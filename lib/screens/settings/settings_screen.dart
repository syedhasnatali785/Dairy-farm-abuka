import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _milkModeKey = 'milk_mode';
  static const String _predictionKey = 'prediction';
  String _milkMode = 'bought';
  double _prediction = 0;

  final TextEditingController _predictionController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _predictionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_milkModeKey) ?? 'bought';
    final prediction = prefs.getDouble(_predictionKey) ?? 0;
    if (!mounted) return;

    setState(() {
      _milkMode = mode;
      _prediction = prediction;
      _predictionController.text = prediction == 0 ? '' : prediction.toString();
    });
  }

  Future<void> _saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_milkModeKey, mode);
    if (!mounted) return;

    setState(() {
      _milkMode = mode;
    });
    _showMessage('Milk mode saved.');
  }

  Future<void> _savePrediction() async {
    final value = double.tryParse(_predictionController.text.trim());
    if (value == null || value < 0) {
      _showMessage('Enter a valid prediction.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_predictionKey, value);
    if (!mounted) return;

    setState(() {
      _prediction = value;
    });

    _showMessage('Prediction saved.');
  }

  Future<void> _clearSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Settings?'),
          content: const Text(
            'This will reset application settings only. '
            'Your customers and milk records will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_milkModeKey);
    await prefs.remove(_predictionKey);
    if (!mounted) return;
    setState(() {
      _milkMode = 'bought';
      _prediction = 0;
      _predictionController.clear();
    });
    _showMessage('Settings reset.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Milk Entry Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bought Customers'),
                subtitle: const Text('Select customers who bought milk.'),
                leading: Radio<String>(
                  value: 'bought',
                  groupValue: _milkMode,
                  onChanged: (value) {
                    if (value != null) {
                      _saveMode(value);
                    }
                  },
                ),
                onTap: () {
                  _saveMode('bought');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Not Bought Customers'),
                subtitle: const Text('Select customers who did not buy milk.'),
                leading: Radio<String>(
                  value: 'notBought',
                  groupValue: _milkMode,
                  onChanged: (value) {
                    if (value != null) {
                      _saveMode(value);
                    }
                  },
                ),
                onTap: () {
                  _saveMode('notBought');
                },
              ),
            ],
          ),

          const Divider(height: 32),

          const Text(
            'Milk Prediction',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _predictionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Expected Daily Milk',
              hintText: 'e.g. 150',
              suffixText: 'L',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _savePrediction,
              child: const Text('SAVE PREDICTION'),
            ),
          ),

          const SizedBox(height: 12),

          if (_prediction > 0)
            Text(
              'Current prediction: '
              '${_prediction.toStringAsFixed(1)} L',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

          const SizedBox(height: 32),

          OutlinedButton(
            onPressed: _clearSettings,
            child: const Text('RESET SETTINGS'),
          ),
        ],
      ),
    );
  }
}
