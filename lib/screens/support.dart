import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

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
const _red         = Color(0xFFDC2626);
const _redLight    = Color(0xFFFEE2E2);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

// ─────────────────────────────────────────────
//  SUPPORT SCREEN
// ─────────────────────────────────────────────
class Support extends StatefulWidget {
  final VoidCallback onBack;
  const Support({super.key, required this.onBack});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _call(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('tel:$clean'));
  }

  Widget _fadeSlide(Widget child, {required double delay}) {
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(delay, 1.0, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    return FadeTransition(
        opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fadeSlide(_buildEmergencyBanner(), delay: 0.0),
                      const SizedBox(height: 26),
                  _fadeSlide(_buildSectionLabel('Quick Emergency'), delay: 0.1),
                  const SizedBox(height: 14),
                  _fadeSlide(_buildEmergencyGrid(), delay: 0.2),
                  const SizedBox(height: 28),
                  _fadeSlide(_buildSectionLabel('Government Helplines'), delay: 0.3),
                  const SizedBox(height: 14),
                  _fadeSlide(
                    _buildHelpline(
                      title: 'Disability Helpline',
                      subtitle: 'National helpline for persons with disabilities',
                      number: '1800-222-014',
                      icon: Icons.accessible_forward_rounded,
                      iconBg: _purpleLight,
                      iconColor: _purple,
                      free: true,
                    ),
                    delay: 0.4,
                  ),
                  const SizedBox(height: 12),
                  _fadeSlide(
                    _buildHelpline(
                      title: 'Health Ministry',
                      subtitle: 'COVID & health related assistance',
                      number: '1075',
                      icon: Icons.health_and_safety_rounded,
                      iconBg: _blueLight,
                      iconColor: _blue,
                      free: true,
                    ),
                    delay: 0.5,
                  ),
                  const SizedBox(height: 12),
                  _fadeSlide(
                    _buildHelpline(
                      title: 'Senior Citizen Helpline',
                      subtitle: 'Assistance for senior citizens',
                      number: '14567',
                      icon: Icons.elderly_rounded,
                      iconBg: _greenLight,
                      iconColor: _green,
                      free: true,
                    ),
                    delay: 0.6,
                  ),
                  const SizedBox(height: 12),
                  _fadeSlide(
                    _buildHelpline(
                      title: 'Child Helpline',
                      subtitle: 'Protection and support for children',
                      number: '1098',
                      icon: Icons.child_care_rounded,
                      iconBg: _orangeLight,
                      iconColor: _orange,
                      free: true,
                    ),
                    delay: 0.7,
                  ),
                  const SizedBox(height: 28),
                  _fadeSlide(_buildSectionLabel('Mental Health Support'), delay: 0.8),
                  const SizedBox(height: 14),
                  _fadeSlide(_buildMentalHealthCard(), delay: 0.9),
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
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(
            top: -30,
            right: -20,
            child: Container(
                width: 120,
                height: 120,
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
                  Text('Help & Support',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Emergency numbers & helplines',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
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
                child: const Icon(Icons.volume_up_rounded,
                    color: Colors.white, size: 18),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  EMERGENCY BANNER
  // ─────────────────────────────────────────────
  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded,
                color: _red, size: 20)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Immediate Danger?',
                  style: TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              SizedBox(height: 1),
              Text('Call the national emergency number',
                  style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _PulseButton(
          child: Container(
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: _red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _call('112'),
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.call_rounded, color: Colors.white, size: 16),
                      SizedBox(height: 1),
                      Text('112',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  EMERGENCY GRID
  // ─────────────────────────────────────────────
  Widget _buildEmergencyGrid() {
    final items = [
      _EmergencyItem('Ambulance', '108', Icons.medical_services_rounded,
          _pink, _pinkLight),
      _EmergencyItem(
          'Police', '100', Icons.local_police_rounded, _blue, _blueLight),
      _EmergencyItem('Fire', '101', Icons.local_fire_department_rounded,
          _orange, _orangeLight),
      _EmergencyItem('Women Help', '1091', Icons.female_rounded, _purple,
          _purpleLight),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // EXACTLY SQUARE
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _emergencyCard(items[index]),
    );
  }

  Widget _emergencyCard(_EmergencyItem item) {
    return Container(
      
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: item.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _call(item.number),
          borderRadius: BorderRadius.circular(18),
          splashColor: item.bgColor,
          highlightColor: item.bgColor.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(0), // Balanced padding for square cards
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: item.bgColor, shape: BoxShape.circle),
                    child: Icon(item.icon, color: item.color, size: 22)),
                const SizedBox(height: 6),
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _textMain),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.number,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: item.color)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.call_rounded, size: 12, color: item.color),
                    const SizedBox(width: 4),
                    Text('Call Now',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.color)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPLINE CARD
  // ─────────────────────────────────────────────
  Widget _buildHelpline({
    required String title,
    required String subtitle,
    required String number,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool free = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textMain,
                        overflow: TextOverflow.ellipsis)),
              ),
              if (free) ...[
                const SizedBox(width: 6),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: _greenLight,
                        borderRadius: BorderRadius.circular(100)),
                    child: const Text('Free',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _green))),
              ],
            ]),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: _textSub, height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(number,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor)),
          ],
        )),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [iconColor, iconColor.withOpacity(0.8)]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: iconColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _call(number),
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.call_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  MENTAL HEALTH CARD
  // ─────────────────────────────────────────────
  Widget _buildMentalHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(children: [
        Positioned(
            top: -20,
            right: -15,
            child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0x10FFFFFF)))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mental Health Support',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text('iCall · Vandrevala Foundation',
                        style: TextStyle(
                            color: Color(0xCCFFFFFF), fontSize: 11)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Text(
                'Speak to a trained mental health counsellor. Free & confidential support available 24/7.',
                style: TextStyle(
                    color: Color(0xE6FFFFFF), fontSize: 12, height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _call('9152987821'),
                    borderRadius: BorderRadius.circular(10),
                    splashColor: _purpleLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.call_rounded, size: 15, color: _purple),
                          SizedBox(width: 6),
                          Text('iCall',
                              style: TextStyle(
                                  color: _purple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 1)),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _call('18602662345'),
                    borderRadius: BorderRadius.circular(10),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.call_rounded,
                              size: 15, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Vandrevala',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ]),
          ],
        ),
      ]),
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
                  colors: [_purple, _purpleMid],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textMain)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  PULSE BUTTON ANIMATION
// ─────────────────────────────────────────────
class _PulseButton extends StatefulWidget {
  final Widget child;
  const _PulseButton({required this.child});
  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

// ─────────────────────────────────────────────
//  DATA CLASS
// ─────────────────────────────────────────────
class _EmergencyItem {
  final String title;
  final String number;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _EmergencyItem(this.title, this.number, this.icon,
      this.color, this.bgColor);
}