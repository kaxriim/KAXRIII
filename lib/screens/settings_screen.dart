import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/revenue_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullDayController;
  late TextEditingController _halfDayController;
  late TextEditingController _goalController;
  late String _currentYearMonth;

  @override
  void initState() {
    super.initState();
    _currentYearMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    final provider = Provider.of<RevenueProvider>(context, listen: false);
    _fullDayController = TextEditingController(
      text: provider.data.settings.fullDayRate.toStringAsFixed(0),
    );
    _halfDayController = TextEditingController(
      text: provider.data.settings.halfDayRate.toStringAsFixed(0),
    );
    _goalController = TextEditingController(
      text: provider.getGoalForMonth(_currentYearMonth).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _fullDayController.dispose();
    _halfDayController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RevenueProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Daily Shift Rates (DA)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _fullDayController,
                  decoration: InputDecoration(
                    labelText: 'Full Day Rate',
                    suffixText: 'DA',
                    prefixIcon: const Icon(Icons.flash_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter rate';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _halfDayController,
                  decoration: InputDecoration(
                    labelText: 'Half Day Rate',
                    suffixText: 'DA',
                    prefixIcon: const Icon(Icons.flash_off),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter rate';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),
                Text(
                  'Monthly Targets & Goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _goalController,
                  decoration: InputDecoration(
                    labelText: 'Monthly Goal ($_currentYearMonth)',
                    suffixText: 'DA',
                    prefixIcon: const Icon(Icons.emoji_events),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter goal';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),
                FilledButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      double fullDay = double.parse(_fullDayController.text);
                      double halfDay = double.parse(_halfDayController.text);
                      double goalValue = double.parse(_goalController.text);

                      await provider.updateRates(fullDay, halfDay);
                      await provider.updateGoal(_currentYearMonth, goalValue);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved successfully!')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
                const Divider(),
                const SizedBox(height: 24.0),
                Text(
                  'Danger Zone',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 12.0),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Factory Reset'),
                          content: const Text(
                            'Are you sure you want to reset all data, logs, rates, and goals? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await provider.factoryReset();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('App has been fully reset.')),
                                  );
                                }
                              },
                              child: Text(
                                'Reset Everything',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Factory Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}