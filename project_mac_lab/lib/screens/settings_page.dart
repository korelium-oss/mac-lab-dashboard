import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;
  String _pingResult = '';
  bool _pinging = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ConfigService.getBaseUrl());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    ConfigService.setBaseUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Server URL saved for this session'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _ping() async {
    setState(() {
      _pinging = true;
      _pingResult = '';
    });

    // Save current field value before pinging
    ConfigService.setBaseUrl(_urlController.text.trim());

    try {
      final status = await ApiService.fetchStatus();
      final online = status.values.where((v) => v).length;
      setState(() => _pingResult = '✅ Connected! $online machine(s) online.');
    } catch (e) {
      setState(() => _pingResult = '❌ Failed: ${e.toString().substring(0, 80)}');
    } finally {
      setState(() => _pinging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Server URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the IP or hostname of the machine running mac-lab-backend.\n'
              'Example: http://192.168.1.10:8000',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://127.0.0.1:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _save,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: _pinging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find),
                  label: const Text('Test Connection'),
                  onPressed: _pinging ? null : _ping,
                ),
              ],
            ),
            if (_pingResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pingResult.startsWith('✅')
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _pingResult.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(_pingResult),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Quick Presets',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Localhost :8000'),
                  onPressed: () {
                    _urlController.text = 'http://127.0.0.1:8000';
                    _save();
                  },
                ),
                ActionChip(
                  label: const Text('admin-pc.local :8000'),
                  onPressed: () {
                    _urlController.text = 'http://admin-pc.local:8000';
                    _save();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
