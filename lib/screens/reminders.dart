import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import 'create_reminder_screen.dart';

// ─────────────────────────────────────────────
//  COLOURS  (matches app design system)
// ─────────────────────────────────────────────
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _purpleMid   = Color(0xFFA855F7);
const _green       = Color(0xFF15803D);
const _greenLight  = Color(0xFFDCFCE7);
const _blue        = Color(0xFF1D4ED8);
const _blueLight   = Color(0xFFDBEAFE);
const _pink        = Color(0xFFBE185D);
const _pinkLight   = Color(0xFFFCE7F3);
const _orange      = Color(0xFFEA580C);
const _orangeLight = Color(0xFFFED7AA);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

class Reminders extends StatefulWidget {
  final VoidCallback onBack;
  const Reminders({super.key, required this.onBack});

  @override
  State<Reminders> createState() => _RemindersState();
}

class _RemindersState extends State<Reminders> with SingleTickerProviderStateMixin {
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadReminders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReminders = List.from(_reminders);
      } else {
        _filteredReminders = _reminders.where((r) {
          return r.title.toLowerCase().contains(query) || 
                 r.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminders = await ReminderService.loadReminders();
    // Sort by date/time ascending
    reminders.sort((a, b) {
      final aDateTime = DateTime(a.date.year, a.date.month, a.date.day, a.time.hour, a.time.minute);
      final bDateTime = DateTime(b.date.year, b.date.month, b.date.day, b.time.hour, b.time.minute);
      return aDateTime.compareTo(bDateTime);
    });
    setState(() {
      _reminders = reminders;
      _filteredReminders = List.from(_reminders);
      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(); // Re-apply search
      }
      _isLoading = false;
    });
    _animCtrl.forward(from: 0.0);
  }

  Future<void> _addReminder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderScreen(
          onSave: (newReminder) async {
            await ReminderService.addReminder(newReminder);
            _loadReminders();
          },
        ),
      ),
    );
  }

  Future<void> _editReminder(Reminder reminder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderScreen(
          existingReminder: reminder,
          onSave: (updatedReminder) async {
            await ReminderService.updateReminder(updatedReminder);
            _loadReminders();
          },
        ),
      ),
    );
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ReminderService.deleteReminder(reminder.id);
      _loadReminders();
    }
  }

  Future<void> _toggleCompletion(Reminder reminder) async {
    final updated = Reminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      type: reminder.type,
      date: reminder.date,
      time: reminder.time,
      repeatType: reminder.repeatType,
      colorTag: reminder.colorTag,
      createdAt: reminder.createdAt,
      isCompleted: !reminder.isCompleted,
    );
    await ReminderService.updateReminder(updated);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _buildFAB(),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchSection(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: _purple))
              : _filteredReminders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: _filteredReminders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final reminder = _filteredReminders[index];
                        final double delay = (index < 8 ? index * 0.1 : 0.8);
                        
                        return _AnimatedCard(
                          animation: _animCtrl,
                          delay: delay,
                          child: _ReminderCard(
                            reminder: reminder,
                            onEdit: () => _editReminder(reminder),
                            onDelete: () => _deleteReminder(reminder),
                            onToggleComplete: () => _toggleCompletion(reminder),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addReminder,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withOpacity(0.4),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Reminders',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Keep track of your schedule',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                ],
              )),
              _buildModernActionBtn(Icons.refresh_rounded, _loadReminders),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildModernActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: _cardBorder, width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search medications, appointments...',
            hintStyle: const TextStyle(color: _textSub, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _purple, size: 20),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _searchController.clear(),
                ) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _purpleLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded, size: 48, color: _purple),
          ),
          const SizedBox(height: 20),
          const Text(
            'All clear for now!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the "+" button to add a new reminder.',
            style: TextStyle(color: _textSub, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double delay;

  const _AnimatedCard({
    required this.child,
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.3 > 1.0 ? 1.0 : delay + 0.3, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.4 > 1.0 ? 1.0 : delay + 0.4, curve: Curves.easeOutCubic),
      ),
    );
    
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    Color tagColor;
    Color tagBg;
    IconData icon;

    switch (reminder.colorTag) {
      case 'appointment':
        tagColor = _purple;
        tagBg = _purpleLight;
        icon = Icons.calendar_today_rounded;
        break;
      case 'medication':
        tagColor = _green;
        tagBg = _greenLight;
        icon = Icons.medical_services_rounded;
        break;
      case 'custom':
      default:
        tagColor = _pink;
        tagBg = _pinkLight;
        icon = Icons.bookmark_rounded;
        break;
    }

    if (reminder.isCompleted) {
      tagColor = _textSub;
      tagBg = const Color(0xFFF1F5F9);
    }

    final formattedTime = reminder.time.format(context);
    final formattedDate = DateFormat('dd MMM yyyy').format(reminder.date);
    
    final bool isToday = DateFormat('yyyy-MM-dd').format(reminder.date) == 
                         DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tagColor.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          splashColor: tagBg,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox
                GestureDetector(
                  onTap: onToggleComplete,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: reminder.isCompleted ? _purple : Colors.white,
                      border: Border.all(
                        color: reminder.isCompleted ? _purple : const Color(0xFFCBD5E1),
                        width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: reminder.isCompleted 
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) 
                      : null,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: reminder.isCompleted ? _textSub : _textMain,
                                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isToday && !reminder.isCompleted ? _orangeLight : tagBg,
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              isToday && !reminder.isCompleted ? 'Today' : formattedDate,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isToday && !reminder.isCompleted ? _orange : tagColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (reminder.description.isNotEmpty) ...[
                        Text(reminder.description,
                          style: const TextStyle(color: _textSub, fontSize: 13, height: 1.4)),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(icon, size: 14, color: tagColor),
                          const SizedBox(width: 6),
                          Text(formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tagColor)),
                          const SizedBox(width: 12),
                          if (reminder.repeatType != RepeatType.none) ...[
                            const Icon(Icons.repeat_rounded, size: 14, color: _textSub),
                            const SizedBox(width: 4),
                            Text(reminder.repeatType.name.toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: _textSub, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
