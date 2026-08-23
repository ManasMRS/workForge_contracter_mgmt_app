import 'package:flutter/material.dart';
import '../models/cost_estimate_models.dart';
import '../services/cost_estimate_service.dart';

/// Minimal example screen. Wire this into your app's navigation
/// and swap the hardcoded baseUrl for your real deployed API URL
/// (ideally injected via --dart-define or a config file, not hardcoded).
class HouseCostEstimateScreen extends StatefulWidget {
  const HouseCostEstimateScreen({super.key});

  @override
  State<HouseCostEstimateScreen> createState() => _HouseCostEstimateScreenState();
}

class _HouseCostEstimateScreenState extends State<HouseCostEstimateScreen> {
  final _service = CostEstimateService(baseUrl: 'https://your-api-domain.com');

  final _areaController = TextEditingController(text: '1500');
  int _floors = 2;
  QualityTier _quality = QualityTier.standard;
  CityTier _city = CityTier.tier2;

  bool _loading = false;
  String? _error;
  CostEstimate? _result;

  Future<void> _getEstimate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final area = double.tryParse(_areaController.text) ?? 0;
      final result = await _service.estimateHouse(
        HouseEstimateRequest(
          builtUpAreaSqft: area,
          floors: _floors,
          qualityTier: _quality,
          cityTier: _city,
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
      appBar: AppBar(title: const Text('House Cost Estimate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Built-up area per floor (sq ft)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _floors,
              decoration: const InputDecoration(labelText: 'Number of floors'),
              items: List.generate(6, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _floors = v ?? 1),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<QualityTier>(
              initialValue: _quality,
              decoration: const InputDecoration(labelText: 'Quality tier'),
              items: QualityTier.values
                  .map((q) => DropdownMenuItem(value: q, child: Text(q.name)))
                  .toList(),
              onChanged: (v) => setState(() => _quality = v ?? QualityTier.standard),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CityTier>(
              initialValue: _city,
              decoration: const InputDecoration(labelText: 'City tier'),
              items: CityTier.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v ?? CityTier.tier2),
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
