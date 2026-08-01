import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../../config/entity_config.dart';
import '../generic_crud_screen.dart';
import '../salary/salary_calculator_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget Function(AppMood) builder;
  const _MenuItem(this.title, this.icon, this.builder);
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppMood mood = AppMoods.all[3];

  void _cycleMood() => setState(() => mood = AppMoods.next(mood));

  late final List<_MenuItem> _items = [
    _MenuItem('Employees', Icons.badge_outlined,
        (m) => GenericCrudScreen(config: EntityConfigs.employee, mood: m)),
    _MenuItem('Sites', Icons.location_city_outlined,
        (m) => GenericCrudScreen(config: EntityConfigs.site, mood: m)),
    _MenuItem('Machines', Icons.precision_manufacturing_outlined,
        (m) => GenericCrudScreen(config: EntityConfigs.machine, mood: m)),
    _MenuItem('Attendance', Icons.event_available_outlined,
        (m) => GenericCrudScreen(config: EntityConfigs.attendance, mood: m)),
    _MenuItem('Salary Records', Icons.payments_outlined,
        (m) => GenericCrudScreen(config: EntityConfigs.salary, mood: m)),
    _MenuItem('Salary Calculator', Icons.calculate_outlined,
        (m) => SalaryCalculatorScreen(mood: m)),
  ];

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return GradientBackground(
      mood: mood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('workForge ©mqub'),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: Colors.white),
              tooltip: 'Change theme',
              onPressed: _cycleMood,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: mood.accent.first,
                      child: Text(
                        (auth.email ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signed in as',
                              style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text(auth.email ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your Workspace',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Only visible to you — every record below is private to your account.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: _items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return _DashboardTile(
                      item: item,
                      mood: mood,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => item.builder(mood))),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final _MenuItem item;
  final AppMood mood;
  final VoidCallback onTap;
  const _DashboardTile(
      {required this.item, required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              mood.accent.first.withOpacity(0.35),
              mood.accent.last.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 38, color: Colors.white),
            const SizedBox(height: 12),
            Text(item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
