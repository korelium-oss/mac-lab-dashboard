import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MultiInstallPage extends StatefulWidget {
  const MultiInstallPage({super.key});

  @override
  State<MultiInstallPage> createState() => _MultiInstallPageState();
}

class _MultiInstallPageState extends State<MultiInstallPage> {
  final List<String> machines = List.generate(
    33,
    (i) => 'mac-${(i + 1).toString().padLeft(3, '0')}',
  );

  final Set<String> selected = {};
  final TextEditingController pkgController = TextEditingController();
  String type = 'cask';
  bool isUninstall = false; // ← Install vs Uninstall mode
  bool running = false;
  String terminal = '';

  final Map<String, StreamSubscription<String>> streams = {};

  void append(String text) => setState(() => terminal += text);

  // ========================
  // SELECT ALL
  // ========================
  void toggleSelectAll() {
    setState(() {
      if (selected.length == machines.length) {
        selected.clear();
      } else {
        selected.addAll(machines);
      }
    });
  }

  // ========================
  // INSTALL (streaming)
  // ========================
  Future<void> startInstall() async {
    if (selected.isEmpty || pkgController.text.trim().isEmpty) return;

    setState(() {
      terminal = '';
      running = true;
    });

    for (final mac in selected) {
      final id = mac.split('-')[1];

      final stream = await ApiService.installStream(
        macId: id,
        type: type,
        name: pkgController.text.trim(),
      );

      final sub = stream.listen(
        (line) => append(line),
        onDone: () {
          append('\n[$mac] Stream closed\n');
          streams.remove(mac);
          if (streams.isEmpty) setState(() => running = false);
        },
        onError: (e) => append('\n[$mac] ERROR: $e\n'),
      );

      streams[mac] = sub;
    }
  }

  // ========================
  // UNINSTALL (blocking, per-machine)
  // ========================
  Future<void> startUninstall() async {
    if (selected.isEmpty || pkgController.text.trim().isEmpty) return;

    setState(() {
      terminal = '';
      running = true;
    });

    for (final mac in selected) {
      final id = int.tryParse(mac.split('-')[1]) ?? 0;
      append('[$mac] Removing ${pkgController.text.trim()} ($type)...\n');

      try {
        final result = await ApiService.removePkg(
          id: id,
          type: type,
          name: pkgController.text.trim(),
        );

        final ok = result['ok'] == true;
        append(result['stdout'] ?? '');
        if ((result['stderr'] as String? ?? '').isNotEmpty) {
          append(result['stderr'] as String);
        }
        append('\n[$mac] ${ok ? '✅ Done' : '❌ Failed'}\n\n');
      } catch (e) {
        append('\n[$mac] ERROR: $e\n');
      }
    }

    setState(() => running = false);
  }

  // ========================
  // STOP ALL
  // ========================
  Future<void> stopAll() async {
    for (final mac in selected) {
      final id = mac.split('-')[1];
      await ApiService.stopInstall(id);
    }
    for (final sub in streams.values) {
      await sub.cancel();
    }
    streams.clear();
    setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = isUninstall ? 'Uninstall' : 'Install';
    final actionIcon =
        isUninstall ? Icons.delete_forever : Icons.cloud_download;
    final actionColor = isUninstall ? Colors.red : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Management'),
        actions: [
          
          TextButton.icon(
            icon: Icon(
              selected.length == machines.length
                  ? Icons.deselect
                  : Icons.select_all,
            ),
            label: Text(
              selected.length == machines.length ? 'Deselect All' : 'Select All',
            ),
            onPressed: toggleSelectAll,
          ),
          IconButton(
            tooltip: 'Reset everything',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              selected.clear();
              pkgController.clear();
              terminal = '';
              isUninstall = false;
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MACHINE CHIPS
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: machines.map((m) {
                return FilterChip(
                  label: Text(m),
                  selected: selected.contains(m),
                  onSelected: (v) {
                    setState(() {
                      v ? selected.add(m) : selected.remove(m);
                    });
                  },
                  selectedColor: Colors.blueAccent,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // INSTALL / UNINSTALL TOGGLE
            Row(
              children: [
                const Text('Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Install'),
                      icon: Icon(Icons.cloud_download),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Uninstall'),
                      icon: Icon(Icons.delete_forever),
                    ),
                  ],
                  selected: {isUninstall},
                  onSelectionChanged: (v) =>
                      setState(() => isUninstall = v.first),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PACKAGE INPUT + TYPE DROPDOWN
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pkgController,
                    decoration: InputDecoration(
                      labelText: 'Package name',
                      hintText: 'iterm2, firefox, htop, python',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(actionIcon, color: actionColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'cask', child: Text('Cask (GUI)')),
                    DropdownMenuItem(
                        value: 'formula', child: Text('Formula (CLI)')),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ACTION BUTTONS
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(actionIcon),
                  label: Text('$actionLabel Selected (${selected.length})'),
                  style: ElevatedButton.styleFrom(backgroundColor: actionColor),
                  onPressed: running
                      ? null
                      : (isUninstall ? startUninstall : startInstall),
                ),
                const SizedBox(width: 12),
                if (!isUninstall)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop All'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: running ? stopAll : null,
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800),
                  onPressed: terminal.isEmpty
                      ? null
                      : () => setState(() => terminal = ''),
                ),
                if (running) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // TERMINAL OUTPUT
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    terminal.isEmpty
                        ? '— output will appear here —'
                        : terminal,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: terminal.isEmpty
                          ? Colors.grey.shade700
                          : Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
