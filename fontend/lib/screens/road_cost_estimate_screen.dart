import 'package:flutter/material.dart';
import '../models/cost_estimate_models.dart';
import '../services/cost_estimate_service.dart';

/// Minimal example screen for road cost estimation.
/// Wire this into your app's navigation the same way as HouseCostEstimateScreen.
/// Swap the hardcoded baseUrl for your real deployed API URL (inject via
/// --dart-define or a config file, not hardcoded, in a real app).
class RoadCostEstimateScreen extends StatefulWidget {
  const RoadCostEstimateScreen({super.key});

  @override
  State<RoadCostEstimateScreen> createState() => _RoadCostEstimateScreenState();
}

class _RoadCostEstimateScreenState extends State<RoadCostEstimateScreen> {
  final _service = CostEstimateService(baseUrl: 'https://your-api-domain.com');

  final _lengthController = TextEditingController(text: '500');
  final _widthController = TextEditingController(text: '20');
  double _thickness = 6;
  ConcreteGrade _grade = ConcreteGrade.m20;
  bool _reinforcement = true;
  bool _hilly = false;

  bool _loading = false;
  String? _error;
  CostEstimate? _result;

  Future<void> _getEstimate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final length = double.tryParse(_lengthController.text) ?? 0;
      final width = double.tryParse(_widthController.text) ?? 0;
      final result = await _service.estimateRoad(
        RoadEstimateRequest(
          lengthFt: length,
          widthFt: width,
          thicknessInch: _thickness,
          concreteGrade: _grade,
          reinforcement: _reinforcement,
          hilly: _hilly,
        ),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Road Cost Estimate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Length (ft)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Width (ft)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              initialValue: _thickness,
              decoration: const InputDecoration(labelText: 'Slab thickness (inch)'),
              items: [4, 5, 6, 7, 8, 9]
                  .map((t) => DropdownMenuItem(value: t.toDouble(), child: Text('$t"')))
                  .toList(),
              onChanged: (v) => setState(() => _thickness = v ?? 6),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ConcreteGrade>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Concrete grade'),
              items: ConcreteGrade.values
                  .map((g) => DropdownMenuItem(value: g, child: Text(g.apiValue)))
                  .toList(),
              onChanged: (v) => setState(() => _grade = v ?? ConcreteGrade.m20),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Steel mesh reinforcement'),
              value: _reinforcement,
              onChanged: (v) => setState(() => _reinforcement = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hilly terrain'),
              value: _hilly,
              onChanged: (v) => setState(() => _hilly = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _getEstimate,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Get Estimate'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${_result!.estimatedCostInr.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Range: ₹${_result!.lowEstimateInr.toStringAsFixed(0)} – '
                        '₹${_result!.highEstimateInr.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
