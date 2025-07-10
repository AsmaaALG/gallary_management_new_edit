import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

typedef DateChangedCallback = void Function(DateTime);

class DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime? startDateLimit;
  final DateTime? endDateLimit;
  final DateChangedCallback onDateChanged;

  const DatePickerField({
    Key? key,
    required this.label,
    required this.onDateChanged,
    this.initialDate,
    this.startDateLimit,
    this.endDateLimit,
  }) : super(key: key);

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime first = widget.startDateLimit ?? DateTime(2000);
    final DateTime last = widget.endDateLimit ?? DateTime(2100);

    DateTime initial = _selectedDate ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? intl.DateFormat('dd-MM-yyyy').format(_selectedDate!)
                  : 'اختر التاريخ',
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
