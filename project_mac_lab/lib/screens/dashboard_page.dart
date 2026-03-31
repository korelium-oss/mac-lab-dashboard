import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<String> machines = List.generate(
    33,
    (i) => 'mac-${(i + 1).toString().padLeft(3, '0')}',
  );

  final Set<String> selected = {};
  Map<String, bool> status = {'mac-022': true};
  bool loading = false;
  int onlineCount = 0;
  int offlineCount = 0;

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    setState(() => loading = true);
    try {
      final newStatus = await ApiService.fetchStatus();
      newStatus['mac-022'] = true; // Always online

      setState(() {
        status = newStatus;
        onlineCount = status.values.where((v) => v).length;
        offlineCount = status.values.where((v) => !v).length;
      });
    } catch (e, st) {
      debugPrint('Error fetching status: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ========================
  // CONFIRM DIALOG
  // ========================
  Future<void> confirmAndRun(
    String title,
    String msg,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (ok == true) await action();
  }

  // ========================
  // NOTIFY / ALERT DIALOG
  // ========================
  Future<void> showMessageDialog({required bool forAll}) async {
    final msgController = TextEditingController();
    bool withSound = false;

    final targets = forAll ? 'ALL machines' : '${selected.length} selected';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, dialogSetState) => AlertDialog(
          title: Text('📢 Send Message to $targets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: msgController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Class starts in 5 minutes...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: withSound,
                title: const Text('🔔 With Sound Alert'),
                subtitle: const Text('Plays a sound on target machines'),
                onChanged: (v) => dialogSetState(() => withSound = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: Icon(withSound ? Icons.volume_up : Icons.notifications),
              label: const Text('Send'),
              onPressed: () => Navigator.pop(ctx, {
                'message': msgController.text.trim(),
                'sound': withSound,
              }),
            ),
          ],
        ),
      ),
    );

    if (result == null || (result['message'] as String).isEmpty) return;

    final message = result['message'] as String;
    final sound = result['sound'] as bool;

    if (forAll) {
      sound
          ? await ApiService.alertAll(message)
          : await ApiService.notifyAll(message);
    } else {
      for (final mac in selected) {
        sound
            ? await ApiService.alertHost(mac, message)
            : await ApiService.notifyHost(mac, message);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sound ? '🔔 Alert' : '📢 Notification'} sent to $targets'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ========================
  // POWER ACTIONS
  // ========================
  Future<void> rebootSelected() async {
    await confirmAndRun(
      'Reboot Selected',
      'Reboot ${selected.length} machines?\n\n${selected.join(", ")}',
      () async {
        for (final mac in selected) {
          await ApiService.reboot(mac);
        }
        selected.clear();
        fetchStatus();
      },
    );
  }

  Future<void> shutdownSelected() async {
    await confirmAndRun(
      'Shutdown Selected',
      'Shutdown ${selected.length} machines?\n\n${selected.join(", ")}',
      () async {
        for (final mac in selected) {
          await ApiService.shutdown(mac);
        }
        selected.clear();
        fetchStatus();
      },
    );
  }

  Future<void> sleepSelected() async {
    await confirmAndRun(
      'Sleep Selected',
      'Put ${selected.length} machine(s) to sleep?\n\n${selected.join(", ")}',
      () async {
        for (final mac in selected) {
          await ApiService.sleep(mac);
        }
        selected.clear();
        fetchStatus();
      },
    );
  }

  Future<void> wakeSelected() async {
    for (final mac in selected) {
      await ApiService.wake(mac);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Wake-on-LAN sent to ${selected.length} machine(s)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() => selected.clear());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ========================
  // STATUS BOX
  // ========================
  Widget _statusBox(String label, int count, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // ========================
  // UI
  // ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mac Lab Dashboard'),
        actions: [
          // Emergency: kill all zombie SSH/notify processes
          IconButton(
            tooltip: '🛑 Kill zombie processes',
            icon: const Icon(Icons.dangerous, color: Colors.redAccent),
            onPressed: () async {
              await ApiService.killAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛑 All hanging SSH/notify processes killed'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          // Notify ALL button
          IconButton(
            tooltip: 'Send message to ALL',
            icon: const Icon(Icons.campaign),
            onPressed: () => showMessageDialog(forAll: true),
          ),
          Row(
            children: [
              const Text('Select All'),
              Checkbox(
                value: selected.length == machines.length - 1 && !selected.contains('mac-022'),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selected.addAll(machines);
                      selected.remove('mac-022'); // Protect Admin PC
                    } else {
                      selected.clear();
                    }
                  });
                },
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: fetchStatus,
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),

          // STATUS SUMMARY
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusBox('ONLINE', onlineCount, Colors.green),
                _statusBox('OFFLINE', offlineCount, Colors.red),
                _statusBox('TOTAL', machines.length, Colors.blue),
              ],
            ),
          ),

          // MACHINE GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: machines.length,
              itemBuilder: (context, i) {
                final name = machines[i];
                final online = status[name] ?? false;
                final isSelected = selected.contains(name);
                final gap = (i % 6 == 2) ? 18.0 : 6.0;
                final isAdmin = name == 'mac-022';

                return Padding(
                  padding: EdgeInsets.only(right: gap),
                  child: GestureDetector(
                    onTap: () {
                      if (isAdmin) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🛡️ Admin PC (mac-022) is protected and cannot be selected.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        isSelected ? selected.remove(name) : selected.add(name);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: online
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: Colors.blueAccent, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('Admin PC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // GLOBAL CONTROLS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reboot ALL'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Reboot Lab',
                            'Reboot ALL Macs?',
                            () => ApiService.rebootAll(),
                          ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Shutdown ALL'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Shutdown Lab',
                            'Shutdown ALL Macs?',
                            () => ApiService.shutdownAll(),
                          ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    disabledBackgroundColor: Colors.indigo.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Sleep ALL'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Sleep Lab',
                            'Put ALL Macs to sleep?',
                            () => ApiService.sleepAll(),
                          ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    disabledBackgroundColor: Colors.amber.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Wake ALL'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Wake Lab',
                            'Send Wake-on-LAN to ALL Macs?',
                            () => ApiService.wakeAll(),
                          ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.deepPurple.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.desktop_mac),
                  label: const Text('Present Screen'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Present Screen to ALL',
                            'This will push your Admin screen to every machine in the lab.',
                            () => ApiService.screenPresentAll(),
                          ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.settings_ethernet),
                  label: const Text('Setup VNC ALL'),
                  onPressed: selected.isNotEmpty
                      ? null
                      : () => confirmAndRun(
                            'Setup Lab-wide Screen Sharing',
                            'Enable VNC servers silently on ALL machines?',
                            () => ApiService.screenSetupAll(),
                          ),
                ),
              ],
            ),
          ),

          // SELECTED CONTROLS
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: Text('Reboot (${selected.length})'),
                    onPressed: rebootSelected,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.power_settings_new),
                    label: Text('Shutdown (${selected.length})'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: shutdownSelected,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bedtime),
                    label: Text('Sleep (${selected.length})'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo),
                    onPressed: sleepSelected,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bolt),
                    label: Text('Wake (${selected.length})'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700),
                    onPressed: wakeSelected,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.campaign),
                    label: Text('Notify (${selected.length})'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal),
                    onPressed: () => showMessageDialog(forAll: false),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.monitor),
                    label: Text('View Screens (${selected.length})'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                    onPressed: () async {
                      for (final host in selected) {
                        await ApiService.screenMonitor(host);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening VNC for ${selected.length} machine(s)...'))
                        );
                      }
                      setState(() => selected.clear());
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.desktop_mac),
                    label: Text('Present (${selected.length})'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    onPressed: () async {
                      for (final host in selected) {
                        await ApiService.screenPresent(host);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Presenting to ${selected.length} machine(s)...'))
                        );
                      }
                      setState(() => selected.clear());
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_ethernet),
                    label: Text('Setup VNC (${selected.length})'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                    onPressed: () => confirmAndRun(
                      'Setup Screen Sharing',
                      'Enable VNC server silently on ${selected.length} machine(s)?',
                      () async {
                        for (final host in selected) {
                           await ApiService.screenSetup(host);
                        }
                        setState(() => selected.clear());
                      }
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    onPressed: () => setState(() => selected.clear()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
