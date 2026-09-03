import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/widgets/place_autocomplete_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 1;
  bool _leavingSoonOnly = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.push(
      '/home/results',
      extra: {
        'fromCity': _fromController.text.trim(),
        'toCity': _toController.text.trim(),
        'date': dateTime,
        'seats': _seats,
        'leavingSoonOnly': _leavingSoonOnly,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Search rides')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlaceAutocompleteField(
                label: 'Pickup city',
                controller: _fromController,
                icon: Icons.trip_origin,
              ),
              const SizedBox(height: 16),
              PlaceAutocompleteField(
                label: 'Drop city',
                controller: _toController,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(dateFormat.format(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        timeFormat.format(
                          DateTime(2024, 1, 1, _selectedTime.hour,
                              _selectedTime.minute),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilterChip(
                label: const Text('Leaving soon (next 2 hrs)'),
                selected: _leavingSoonOnly,
                onSelected: (value) => setState(() => _leavingSoonOnly = value),
                avatar: Icon(
                  Icons.schedule,
                  size: 18,
                  color: _leavingSoonOnly ? Colors.white : AppColors.accent,
                ),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _leavingSoonOnly ? Colors.white : AppColors.charcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_leavingSoonOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Shows trips departing within 2 hours — ignores date above',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.charcoalMuted,
                        ),
                  ),
                ),
              DropdownButtonFormField<int>(
                key: ValueKey(_seats),
                initialValue: _seats,
                decoration: const InputDecoration(
                  labelText: 'Seats needed',
                  prefixIcon: Icon(Icons.event_seat),
                ),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1} seat${i == 0 ? '' : 's'}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _seats = value);
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _search,
                child: const Text('Search trips'),
              ),
              const SizedBox(height: 24),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECEB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Map preview',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
