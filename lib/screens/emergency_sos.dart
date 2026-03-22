import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  COLOURS
// ─────────────────────────────────────────────
const _red         = Color(0xFFDC2626);
const _redLight    = Color(0xFFFEE2E2);
const _redMid      = Color(0xFFFCA5A5);
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _green       = Color(0xFF15803D);
const _greenLight  = Color(0xFFDCFCE7);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

// ─────────────────────────────────────────────
//  MODEL: Emergency Contact
// ─────────────────────────────────────────────
class EmergencyContact {
  final String name;
  final String relation;
  String phone;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
}

// ─────────────────────────────────────────────
//  EMERGENCY SOS SCREEN
// ─────────────────────────────────────────────
class EmergencySOS extends StatefulWidget {
  final VoidCallback onBack;
  const EmergencySOS({super.key, required this.onBack});

  @override
  State<EmergencySOS> createState() => _EmergencySOSState();
}

class _EmergencySOSState extends State<EmergencySOS>
    with TickerProviderStateMixin {
  // Pulse animation for SOS button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseSc;

  // Page entry animation
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  // SOS countdown
  bool _sosPressed = false;
  int _countdown = 3;
  AnimationController? _countdownCtrl;

  // Location sharing toggle
  bool _locationSharing = false;

  // Emergency contacts (empty by default — user adds own)
  final List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseSc = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.7)));
    _entrySlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryCtrl,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _countdownCtrl?.dispose();
    super.dispose();
  }

  // ── SOS Logic ──────────────────────────────────────────────
  void _startSOS() {
    setState(() {
      _sosPressed = true;
      _countdown = 3;
    });

    _countdownCtrl?.dispose();
    _countdownCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _countdownCtrl!.forward();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_sosPressed) return false;
      if (_countdown > 1) {
        setState(() => _countdown--);
        return true;
      }
      // Trigger SOS call
      _triggerSOS();
      return false;
    });
  }

  void _cancelSOS() {
    _countdownCtrl?.stop();
    setState(() {
      _sosPressed = false;
      _countdown = 3;
    });
  }

  Future<void> _triggerSOS() async {
    setState(() => _sosPressed = false);
    // Call national emergency
    await _call('112');
    // Notify all contacts via phone
    for (final c in _contacts) {
      final clean = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
      await launchUrl(Uri.parse('sms:$clean?body=🚨 SOS Alert! I need immediate help. Please contact me.'));
    }
  }

  Future<void> _call(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('tel:$clean'));
  }

  // ── Add Contact Dialog ──────────────────────────────────────
  void _showAddContactDialog({EmergencyContact? existing, int? index}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final relCtrl  = TextEditingController(text: existing?.relation ?? '');
    final phoneCtrl= TextEditingController(text: existing?.phone ?? '');
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        title: Text(
          existing == null ? 'Add Emergency Contact' : 'Edit Contact',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _textMain),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Full Name', nameCtrl, Icons.person_outline_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Name required' : null),
              const SizedBox(height: 12),
              _dialogField('Relation (e.g. Brother)', relCtrl,
                  Icons.people_outline_rounded),
              const SizedBox(height: 12),
              _dialogField('Phone Number', phoneCtrl, Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.replaceAll(RegExp(r'[^0-9]'), '').length < 10
                          ? 'Valid phone required'
                          : null),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _textSub, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final contact = EmergencyContact(
                name: nameCtrl.text.trim(),
                relation: relCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              setState(() {
                if (index != null) {
                  _contacts[index] = contact;
                } else {
                  _contacts.add(contact);
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(existing == null ? 'Add' : 'Save',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  TextFormField _dialogField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _textMain),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _textSub),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.5)),
        labelStyle: const TextStyle(fontSize: 13, color: _textSub),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── DELETE CONTACT ──────────────────────────
  void _deleteContact(int index) {
    setState(() => _contacts.removeAt(index));
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [
                      // ── Danger notice ──────────────────────
                      _buildDangerBanner(),
                      const SizedBox(height: 24),

                      // ── SOS Button ────────────────────────
                      _buildSOSButton(),
                      const SizedBox(height: 28),

                      // ── Quick Emergency Numbers ───────────
                      _buildSectionLabel('Quick Emergency Calls'),
                      const SizedBox(height: 14),
                      _buildQuickCalls(),
                      const SizedBox(height: 28),

                      // ── Location sharing ──────────────────
                      _buildSectionLabel('Live Location'),
                      const SizedBox(height: 14),
                      _buildLocationCard(),
                      const SizedBox(height: 28),

                      // ── Emergency Contacts ────────────────
                      _buildSectionLabel('Emergency Contacts'),
                      const SizedBox(height: 14),
                      _buildContactsList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(
            top: -30,
            right: -20,
            child: Container(
                width: 130,
                height: 130,
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
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Emergency SOS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Alert contacts & services instantly',
                          style:
                              TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                    ],
                  )),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1)),
                child:
                    const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  DANGER BANNER
  // ─────────────────────────────────────────────
  Widget _buildDangerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _redMid, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              const BoxDecoration(color: Color(0xFFFECACA), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: _red, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('For Real Emergencies Only',
                style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            SizedBox(height: 2),
            Text(
                'Press SOS to alert your contacts & call 112. Adds 3-second countdown to prevent accidents.',
                style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 11,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  PULSING SOS BUTTON
  // ─────────────────────────────────────────────
  Widget _buildSOSButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _red.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _sosPressed ? const AlwaysStoppedAnimation(1.0) : _pulseSc,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple rings
                Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                        color: _red.withOpacity(0.06),
                        shape: BoxShape.circle)),
                Container(
                    width: 185,
                    height: 185,
                    decoration: BoxDecoration(
                        color: _red.withOpacity(0.10),
                        shape: BoxShape.circle)),
                Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                        color: _red.withOpacity(0.16),
                        shape: BoxShape.circle)),
                // Main button
                GestureDetector(
                  onTap: _sosPressed ? _cancelSOS : _startSOS,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _sosPressed ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444),
                          _sosPressed ? const Color(0xFF991B1B) : _red,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _red.withOpacity(0.45),
                            blurRadius: 22,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sosPressed) ...[
                          Text('$_countdown',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900)),
                          const Text('CANCEL',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2)),
                        ] else ...[
                          const Text('SOS',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                          const Text('Hold to Alert',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _sosPressed
                ? 'Calling 112 in $_countdown seconds...'
                : 'Tap to activate • 3-second countdown',
            style: TextStyle(
                fontSize: 12,
                color: _sosPressed ? _red : _textSub,
                fontWeight:
                    _sosPressed ? FontWeight.w700 : FontWeight.w400),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK CALL BUTTONS
  // ─────────────────────────────────────────────
  Widget _buildQuickCalls() {
    final calls = [
      _QuickCall('112', 'Emergency', Icons.emergency_rounded, _red, _redLight),
      _QuickCall('108', 'Ambulance', Icons.medical_services_rounded, const Color(0xFFBE185D), const Color(0xFFFCE7F3)),
      _QuickCall('100', 'Police', Icons.local_police_rounded, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
      _QuickCall('101', 'Fire', Icons.local_fire_department_rounded, const Color(0xFFEA580C), const Color(0xFFFED7AA)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: calls.length,
      itemBuilder: (_, i) => _quickCallTile(calls[i]),
    );
  }

  Widget _quickCallTile(_QuickCall c) {
    return InkWell(
      onTap: () => _call(c.number),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: c.color.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: c.bgColor, shape: BoxShape.circle),
            child: Icon(c.icon, color: c.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(c.number,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.color)),
              ],
            ),
          ),
          Icon(Icons.call_rounded, size: 16, color: c.color),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LOCATION CARD
  // ─────────────────────────────────────────────
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: _locationSharing ? _greenLight : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.location_on_rounded,
              color: _locationSharing ? _green : _textSub, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Share Live Location',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textMain)),
            const SizedBox(height: 2),
            Text(
              _locationSharing
                  ? 'Broadcasting to your emergency contacts'
                  : 'Off — contacts won\'t see your location',
              style: const TextStyle(fontSize: 11, color: _textSub, height: 1.3),
            ),
          ]),
        ),
        Switch(
          value: _locationSharing,
          onChanged: (v) => setState(() => _locationSharing = v),
          activeColor: _green,
          activeTrackColor: _greenLight,
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTACTS LIST
  // ─────────────────────────────────────────────
  Widget _buildContactsList() {
    return Column(
      children: [
        if (_contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder, width: 1.5),
            ),
            child: Column(children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                      color: _redLight, shape: BoxShape.circle),
                  child: const Icon(Icons.person_off_rounded,
                      color: _red, size: 26)),
              const SizedBox(height: 12),
              const Text('No contacts added',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _textMain)),
              const SizedBox(height: 4),
              const Text('Add people who should be notified\nin an emergency',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _textSub, height: 1.4)),
            ]),
          )
        else
          ...List.generate(_contacts.length, (i) {
            final c = _contacts[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder, width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_rounded,
                        color: _purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _textMain)),
                          const SizedBox(height: 2),
                          Text(
                              c.relation.isNotEmpty
                                  ? '${c.relation} · ${c.phone}'
                                  : c.phone,
                              style: const TextStyle(
                                  fontSize: 11, color: _textSub)),
                        ]),
                  ),
                  // Call button
                  InkWell(
                    onTap: () => _call(c.phone),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: _greenLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.call_rounded,
                          color: _green, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit button
                  InkWell(
                    onTap: () =>
                        _showAddContactDialog(existing: c, index: i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: _purpleLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_rounded,
                          color: _purple, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  InkWell(
                    onTap: () => _deleteContact(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: _redLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: _red, size: 18),
                    ),
                  ),
                ]),
              ),
            );
          }),

        const SizedBox(height: 10),

        // Add contact button
        InkWell(
          onTap: () => _showAddContactDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder, width: 1.8),
              color: _purpleLight.withOpacity(0.4),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_rounded, color: _purple, size: 18),
                SizedBox(width: 8),
                Text('Add Emergency Contact',
                    style: TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_red, _redMid],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _textMain)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────
class _QuickCall {
  final String number;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _QuickCall(this.number, this.label, this.icon, this.color, this.bgColor);
}
