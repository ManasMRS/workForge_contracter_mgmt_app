import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';

/// Lets the user pick an Employee + Month, pulls that employee's
/// attendance records (already scoped to the signed-in user by the
/// backend) and computes salary:
///   presentDays = records where workingHours >= 8
///   halfDays    = records where 0 < workingHours < 8
///   totalSalary = presentDays * dailySalary + halfDays * (dailySalary / 2)
/// Result can be saved straight to /salary.
class SalaryCalculatorScreen extends StatefulWidget {
  final AppMood mood;
  const SalaryCalculatorScreen({super.key, required this.mood});

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  late Repository _repo;
  List<dynamic> _employees = [];
  bool _loadingEmployees = true;
  String? _employeeId;
  final _monthController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 7)); // YYYY-MM

  bool _calculating = false;
  bool _saving = false;
  String? _error;

  int? _presentDays;
  int? _halfDays;
  double? _dailySalary;
  double? _totalSalary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = Repository(context.read<AuthService>());
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await _repo.get('/employees');
      setState(() => _employees = data is List ? data : []);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Failed to load employees');
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _calculate() async {
    if (_employeeId == null) {
      setState(() => _error = 'Select an employee first');
      return;
    }
    final month = _monthController.text.trim(); // expects YYYY-MM
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      setState(() => _error = 'Enter month as YYYY-MM, e.g. 2026-07');
      return;
    }

    setState(() {
      _calculating = true;
      _error = null;
      _presentDays = null;
      _halfDays = null;
      _totalSalary = null;
    });

    try {
      final employee = _employees.firstWhere((e) => e['_id'] == _employeeId);
      final dailySalary = (employee['dailySalary'] as num).toDouble();

      // Attendance list is already scoped to the current user by the backend.
      final all = await _repo.get('/attendance');
      final records = (all as List).where((r) {
        final emp = r['employeeId'];
        final empId = emp is Map ? emp['_id'] : emp;
        if (empId != _employeeId) return false;
        final dateStr = r['date']?.toString() ?? '';
        return dateStr.startsWith(month);
      }).toList();

      int presentDays = 0;
      int halfDays = 0;
      for (final r in records) {
        final status = r['status'] == true;
        final hours = (r['workingHours'] as num?)?.toDouble() ?? 0;
        if (!status) continue;
        if (hours >= 8) {
          presentDays++;
        } else if (hours > 0) {
          halfDays++;
        }
      }

      final total = presentDays * dailySalary + halfDays * (dailySalary / 2);

      setState(() {
        _presentDays = presentDays;
        _halfDays = halfDays;
        _dailySalary = dailySalary;
        _totalSalary = total;
      });
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Calculation failed');
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _saveSalary() async {
    if (_employeeId == null || _totalSalary == null) return;
    setState(() => _saving = true);
    try {
      await _repo.post('/salary', {
        'employeeId': _employeeId,
        'month': _monthController.text.trim(),
        'presentDays': _presentDays,
        'halfDays': _halfDays,
        'dailySalary': _dailySalary,
        'totalSalary': _totalSalary,
        'paidStatus': 'Pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Salary record saved'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Save failed'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      mood: widget.mood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Salary Calculator')),
        body: _loadingEmployees
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Employee',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _employeeId,
                          dropdownColor: const Color(0xFF1E1E2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Select employee'),
                          items: _employees
                              .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                                    value: e['_id'] as String,
                                    child: Text('${e['name']} (₹${e['dailySalary']}/day)'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _employeeId = v),
                        ),
                        const SizedBox(height: 16),
                        const Text('Month',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _monthController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'YYYY-MM, e.g. 2026-07'),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Calculate Salary',
                    icon: Icons.calculate_outlined,
                    mood: widget.mood,
                    loading: _calculating,
                    onPressed: _calculate,
                  ),
                  if (_totalSalary != null) ...[
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ResultRow(label: 'Present Days', value: '$_presentDays'),
                          const Divider(color: Colors.white24),
                          _ResultRow(label: 'Half Days', value: '$_halfDays'),
                          const Divider(color: Colors.white24),
                          _ResultRow(
                              label: 'Daily Salary',
                              value: '₹${_dailySalary!.toStringAsFixed(0)}'),
                          const Divider(color: Colors.white24),
                          _ResultRow(
                            label: 'Total Salary',
                            value: '₹${_totalSalary!.toStringAsFixed(0)}',
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Save as Salary Record',
                      icon: Icons.save_outlined,
                      mood: widget.mood,
                      loading: _saving,
                      onPressed: _saveSalary,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _ResultRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: highlight ? 20 : 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
