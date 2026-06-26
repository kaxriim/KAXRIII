import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/revenue_provider.dart';
import '../models/work_models.dart';

class DayActionSheet extends StatefulWidget {
  final DateTime date;
  const DayActionSheet({Key? key, required this.date}) : super(key: key);

  @override
  State<DayActionSheet> createState() => _DayActionSheetState();
}

class _DayActionSheetState extends State<DayActionSheet> {
  String _selectedShift = 'Off';
  late String _dateString;

  @override
  void initState() {
    super.initState();
    _dateString = DateFormat('yyyy-MM-dd').format(widget.date);
    final provider = Provider.of<RevenueProvider>(context, listen: false);
    final existingLog = provider.getWorkLog(_dateString);
    if (existingLog != null) {
      _selectedShift = existingLog.shift;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RevenueProvider>(context);
    final hasPayday = provider.hasPayday(_dateString);
    final unpaidBalance = provider.unpaidBalance;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.date);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Work Shift',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24.0),
          DropdownButtonFormField<String>(
            value: _selectedShift,
            decoration: InputDecoration(
              labelText: 'Select Shift Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              prefixIcon: const Icon(Icons.work_history),
            ),
            items: <String>['Full Day', 'Half Day', 'Off']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedShift = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await provider.saveWorkShift(_dateString, _selectedShift);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Shift saved for $_dateString')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const Divider(height: 32.0, thickness: 1.0),
          if (hasPayday) ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.amber),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'This day is marked as Payday.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: unpaidBalance <= 0
                  ? null
                  : () async {
                      await provider.markAsPayday(_dateString);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Marked $_dateString as Payday!')),
                        );
                        Navigator.pop(context);
                      }
                    },
              icon: const Icon(Icons.paid),
              label: Text('Mark as Payday (${unpaidBalance.toStringAsFixed(0)} DA)'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
          ],
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}