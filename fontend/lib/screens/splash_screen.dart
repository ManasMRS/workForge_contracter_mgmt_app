import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/dashboard_screen.dart';

/// WorkForge animated splash: emblem pops in piece by piece (crane,
/// buildings, house, people, spinning gear), the wordmark reveals, and
/// the surrounding empty space is filled with drifting/driving
/// construction elements (truck, wrench, roofing, foundation, hard-hat)
/// so the screen never feels empty — then routes to Login or Dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _gearSpin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final AnimationController _footerPop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  // Drives all the background filler animations (truck drive, drift, pulse).
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  Animation<double> _seg(double start, double end, {Curve curve = Curves.elasticOut}) {
    return CurvedAnimation(parent: _pop, curve: Interval(start, end, curve: curve));
  }

  late final _crane = _seg(0.00, 0.35);
  late final _buildings = _seg(0.12, 0.45);
  late final _house = _seg(0.25, 0.58);
  late final _people = _seg(0.40, 0.72);
  late final _gearPop = _seg(0.50, 0.80);
  late final _title = CurvedAnimation(parent: _pop, curve: const Interval(0.55, 0.90, curve: Curves.easeOutCubic));
  late final _tagline = CurvedAnimation(parent: _pop, curve: const Interval(0.75, 1.00, curve: Curves.easeOut));

  static const _gradient = LinearGradient(
    colors: [Color(0xFF2E6BFF), Color(0xFF8B3EFF), Color(0xFFFF3E9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final List<_FeatureIcon> _features = const [
    _FeatureIcon(Icons.engineering, 'EMPLOYEES', Color(0xFF2E6BFF)),
    _FeatureIcon(Icons.fact_check_outlined, 'TASKS', Color(0xFFCA3EFF)),
    _FeatureIcon(Icons.groups_rounded, 'CLIENTS', Color(0xFF8B3EFF)),
    _FeatureIcon(Icons.settings_rounded, 'EQUIPMENT', Color(0xFFFF3E9A)),
    _FeatureIcon(Icons.bar_chart_rounded, 'REPORTS', Color(0xFF2E6BFF)),
  ];

  @override
  void initState() {
    super.initState();
    _pop.forward();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _footerPop.forward();
    });
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    await Future.wait([
      auth.loadSession(),
      Future.delayed(const Duration(milliseconds: 2800)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => auth.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    ));
  }

  @override
  void dispose() {
    _pop.dispose();
    _gearSpin.dispose();
    _bob.dispose();
    _footerPop.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Widget _popIn(Animation<double> anim, Widget child, {double startScale = 0.2}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value.clamp(0, 1),
        child: Transform.scale(scale: startScale + (1 - startScale) * anim.value, child: c),
      ),
      child: child,
    );
  }

  Widget _gradientIcon(IconData icon, double size) {
    return ShaderMask(
      shaderCallback: (rect) => _gradient.createShader(rect),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }

  Widget _driftIcon({
    required IconData icon,
    required double size,
    required Color color,
    required double phase,
    double amplitude = 10,
  }) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final t = (_ambient.value + phase) % 1.0;
        final dy = sin(t * 2 * pi) * amplitude;
        final dx = cos(t * 2 * pi) * (amplitude * 0.4);
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: Icon(icon, size: size, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Ambient background filler: construction elements drifting
            // around the empty corners/edges so nothing feels blank ──
            Positioned(
              top: 40,
              left: 24,
              child: Opacity(
                opacity: 0.16,
                child: _driftIcon(icon: Icons.foundation, size: 46, color: Colors.blueAccent, phase: 0.0),
              ),
            ),
            Positioned(
              top: 70,
              right: 20,
              child: Opacity(
                opacity: 0.14,
                child: _driftIcon(icon: Icons.roofing, size: 40, color: Colors.purpleAccent, phase: 0.3),
              ),
            ),
            Positioned(
              top: 220,
              left: 12,
              child: Opacity(
                opacity: 0.16,
                child: _driftIcon(icon: Icons.hardware_rounded, size: 34, color: Colors.pinkAccent, phase: 0.5),
              ),
            ),
            Positioned(
              top: 240,
              right: 18,
              child: Opacity(
                opacity: 0.14,
                child: _driftIcon(icon: Icons.electrical_services, size: 34, color: Colors.blueAccent, phase: 0.7),
              ),
            ),
            Positioned(
              bottom: 130,
              left: 22,
              child: Opacity(
                opacity: 0.15,
                child: _driftIcon(icon: Icons.plumbing_rounded, size: 36, color: Colors.purpleAccent, phase: 0.2),
              ),
            ),
            Positioned(
              bottom: 150,
              right: 26,
              child: Opacity(
                opacity: 0.16,
                child: _driftIcon(icon: Icons.architecture_rounded, size: 38, color: Colors.pinkAccent, phase: 0.9),
              ),
            ),
            // A truck driving slowly left-to-right across the lower area
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) {
                final width = MediaQuery.of(context).size.width;
                final t = (_ambient.value * 0.6) % 1.0; // slower full pass
                final x = -60 + t * (width + 120);
                return Positioned(
                  bottom: 190,
                  left: x,
                  child: Opacity(opacity: 0.13, child: child),
                );
              },
              child: const Icon(Icons.local_shipping_rounded, size: 30, color: Colors.white),
            ),
            // Wrench gently rotating back and forth
            Positioned(
              top: 160,
              right: 60,
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (context, child) {
                  final angle = sin(_ambient.value * 2 * pi * 1.3) * 0.3;
                  return Opacity(
                    opacity: 0.15,
                    child: Transform.rotate(angle: angle, child: child),
                  );
                },
                child: const Icon(Icons.build_rounded, size: 28, color: Colors.white),
              ),
            ),

            // ── Main foreground content ──
            Column(
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  height: 220,
                  width: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _popIn(
                        _seg(0.0, 0.5, curve: Curves.easeOut),
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: const [
                                Color(0xFF2E6BFF),
                                Color(0xFF8B3EFF),
                                Color(0xFFFF3E9A),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 0.75, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 194,
                              height: 194,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A0E27)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 28,
                        top: 58,
                        child: _popIn(_buildings, _gradientIcon(Icons.location_city_rounded, 54)),
                      ),
                      Positioned(
                        left: 30,
                        top: 34,
                        child: _popIn(
                          _crane,
                          AnimatedBuilder(
                            animation: _bob,
                            builder: (context, child) => Transform.translate(offset: Offset(0, 3 * _bob.value), child: child),
                            child: _gradientIcon(Icons.construction_rounded, 46),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 46,
                        child: _popIn(_house, _gradientIcon(Icons.home_rounded, 58)),
                      ),
                      Positioned(
                        bottom: 28,
                        child: _popIn(_people, _gradientIcon(Icons.groups_2_rounded, 40)),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 44,
                        child: _popIn(
                          _gearPop,
                          AnimatedBuilder(
                            animation: _gearSpin,
                            builder: (context, child) => Transform.rotate(angle: _gearSpin.value * 6.28319, child: child),
                            child: _gradientIcon(Icons.settings_rounded, 34),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _title,
                  builder: (context, child) => Opacity(
                    opacity: _title.value,
                    child: Transform.translate(offset: Offset(0, 24 * (1 - _title.value)), child: child),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      children: [
                        const TextSpan(text: 'work', style: TextStyle(color: Colors.white)),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: ShaderMask(
                            shaderCallback: (rect) => _gradient.createShader(rect),
                            child: const Text(
                              'Forge',
                              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _tagline,
                  builder: (context, child) => Opacity(opacity: _tagline.value, child: child),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 26, height: 1, color: Colors.white24),
                      const SizedBox(width: 10),
                      Text(
                        'CONTRACTOR EVERYTHING MANAGEMENT APP',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 26, height: 1, color: Colors.white24),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_features.length, (i) {
                      final anim = CurvedAnimation(
                        parent: _footerPop,
                        curve: Interval((i / _features.length) * 0.6, (i / _features.length) * 0.6 + 0.4, curve: Curves.elasticOut),
                      );
                      final f = _features[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _popIn(
                          anim,
                          Column(
                            children: [
                              Icon(f.icon, color: f.color, size: 22),
                              const SizedBox(height: 6),
                              Text(f.label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureIcon {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureIcon(this.icon, this.label, this.color);
}