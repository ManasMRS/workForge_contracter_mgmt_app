import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cost_estimate_models.dart';

/// Talks to the FastAPI backend for house/road cost predictions.
///
/// Add to pubspec.yaml:
///   dependencies:
///     http: ^1.2.0
class CostEstimateService {
  /// During local development with an Android emulator, use 10.0.2.2
  /// instead of localhost/127.0.0.1 (the emulator maps that to your host machine).
  /// On a real device or once deployed, point this at your live server URL.
  final String baseUrl;

  CostEstimateService({required this.baseUrl});

  Future<CostEstimate> estimateHouse(HouseEstimateRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict/house'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return CostEstimate.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to estimate house cost: ${response.statusCode} ${response.body}');
    }
  }

  Future<CostEstimate> estimateRoad(RoadEstimateRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict/road'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return CostEstimate.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to estimate road cost: ${response.statusCode} ${response.body}');
    }
  }
}
