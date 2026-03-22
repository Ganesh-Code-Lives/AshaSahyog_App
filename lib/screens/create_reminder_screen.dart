import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  COLOURS  (matches app design system)
// ─────────────────────────────────────────────
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _purpleMid   = Color(0xFFA855F7);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

class CreateReminderScreen extends StatefulWidget {
  final Reminder? existingReminder;
  final Function(Reminder) onSave;

  const CreateReminderScreen({
    super.key,
    this.existingReminder,
    required this.onSave,
  });

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  ReminderType _selectedType = ReminderType.appointment;
  RepeatType _selectedRepeat = RepeatType.none;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      _descriptionController.text = r.description;
      _selectedDate = r.date;
      _selectedTime = r.time;
      _selectedType = r.type;
      _selectedRepeat = r.repeatType;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: _purple),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: _purple),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }

      String colorTag = 'appointment';
      if (_selectedType == ReminderType.medication) {
        colorTag = 'medication';
      } else if (_selectedType == ReminderType.custom) {
        colorTag = 'custom';
      }

      final reminder = Reminder(
        id: widget.existingReminder?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        date: _selectedDate!,
        time: _selectedTime!,
        repeatType: _selectedRepeat,
        colorTag: colorTag,
        createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
        isCompleted: widget.existingReminder?.isCompleted ?? false,
      );

      widget.onSave(reminder);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existingReminder != null;
    
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context, isEdit),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Reminder Basics'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'e.g. Morning Medication',
                      icon: Icons.title_rounded,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Optional details...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    _sectionLabel('Event Details'),
                    const SizedBox(height: 16),
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildPickerTile(
                          label: 'Date',
                          value: _selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!),
                          icon: Icons.calendar_month_rounded,
                          onTap: _pickDate,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPickerTile(
                          label: 'Time',
                          value: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                          icon: Icons.access_time_filled_rounded,
                          onTap: _pickTime,
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRepeatSelector(),
                    const SizedBox(height: 48),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEdit) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20, child: Container(
          width: 120, height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0x10FFFFFF)))),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 4),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Reminder' : 'New Reminder',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  const Text('Set your notification details',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                ],
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, 
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _purple, letterSpacing: 0.5));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: _purple, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReminderType>(
          value: _selectedType,
          style: const TextStyle(color: _textMain, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_rounded, color: _purple, size: 20),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
          ),
          items: const [
            DropdownMenuItem(value: ReminderType.appointment, child: Text('Appointment')),
            DropdownMenuItem(value: ReminderType.medication, child: Text('Medication')),
            DropdownMenuItem(value: ReminderType.custom, child: Text('Custom')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedType = val);
          },
        ),
      ],
    );
  }

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repeat Frequency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 8),
        DropdownButtonFormField<RepeatType>(
          value: _selectedRepeat,
          style: const TextStyle(color: _textMain, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.repeat_rounded, color: _purple, size: 20),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
          ),
          items: const [
            DropdownMenuItem(value: RepeatType.none, child: Text('Do not repeat')),
            DropdownMenuItem(value: RepeatType.daily, child: Text('Daily')),
            DropdownMenuItem(value: RepeatType.weekly, child: Text('Weekly')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedRepeat = val);
          },
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder, width: 1.5)),
            child: Row(
              children: [
                Icon(icon, color: _purple, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(value, style: const TextStyle(color: _textMain, fontSize: 14, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveReminder,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.3),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Save Reminder',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}
