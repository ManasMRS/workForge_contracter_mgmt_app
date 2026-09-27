import 'api_service.dart';

class MlPredictionService {
  final ApiService api;

  MlPredictionService(this.api);

  /// Sends site information to the backend ML API
  /// and returns the prediction result.
  Future<Map<String, dynamic>> predict({
    required String siteType,
    required double scopeAreaSqft,
    int floors = 1,
    int plannedWorkers = 10,
    String cityTier = 'tier2',
    String qualityTier = 'standard',
    String roadQuality = 'Not Applicable',
  }) async {
    print('');
    print('========================================');
    print('        ML PREDICTION REQUEST');
    print('========================================');
    print('Site Type       : $siteType');
    print('Area            : $scopeAreaSqft sq.ft');
    print('Floors          : $floors');
    print('Workers         : $plannedWorkers');
    print('City Tier       : $cityTier');
    print('Quality Tier    : $qualityTier');
    print('Road Quality    : $roadQuality');
    print('Endpoint        : /ai/predict');
    print('========================================');

    try {
      final response = await api.post(
        '/ai/predict',
        {
          'site_type': siteType,
          'scope_area_sqft': scopeAreaSqft,
          'floors': floors,
          'planned_workers': plannedWorkers,
          'city_tier': cityTier,
          'quality_tier': qualityTier,
          'road_quality': roadQuality,
        },
      );

      print('');
      print('========================================');
      print('        ML API RESPONSE');
      print('========================================');
      print('Response type: ${response.runtimeType}');
      print('Response: $response');
      print('========================================');

      // ----------------------------------------------------------
      // Validate main API response
      // ----------------------------------------------------------

      if (response == null) {
        throw ApiException(
          'Server returned an empty response.',
        );
      }

      if (response is! Map) {
        throw ApiException(
          'Invalid prediction response from server.',
        );
      }

      // ----------------------------------------------------------
      // Check success flag
      // ----------------------------------------------------------

      final success = response['success'];

      if (success == false) {
        final errorMessage =
            response['error']?.toString() ??
            'Prediction failed on the server.';

        throw ApiException(errorMessage);
      }

      // ----------------------------------------------------------
      // Get prediction object
      // ----------------------------------------------------------

      final prediction = response['prediction'];

      if (prediction == null) {
        throw ApiException(
          'Prediction data is missing from server response.',
        );
      }

      if (prediction is! Map) {
        throw ApiException(
          'Prediction data has an invalid format.',
        );
      }

      final result =
          Map<String, dynamic>.from(prediction);

      // ----------------------------------------------------------
      // Validate expected prediction fields
      // ----------------------------------------------------------

      if (!result.containsKey(
        'estimated_total_cost_inr',
      )) {
        throw ApiException(
          'Estimated cost is missing from prediction.',
        );
      }

      if (!result.containsKey(
        'estimated_duration_days',
      )) {
        throw ApiException(
          'Estimated duration is missing from prediction.',
        );
      }

      if (!result.containsKey(
        'estimated_machine_count',
      )) {
        throw ApiException(
          'Estimated machine count is missing from prediction.',
        );
      }

      if (!result.containsKey(
        'recommended_machine_types',
      )) {
        throw ApiException(
          'Recommended machines are missing from prediction.',
        );
      }

      // ----------------------------------------------------------
      // Print final result
      // ----------------------------------------------------------

      print('');
      print('========================================');
      print('        ML PREDICTION RESULT');
      print('========================================');
      print(
        'Estimated Cost     : '
        '${result['estimated_total_cost_inr']}',
      );
      print(
        'Duration            : '
        '${result['estimated_duration_days']} days',
      );
      print(
        'Machine Count      : '
        '${result['estimated_machine_count']}',
      );
      print(
        'Recommended Machines: '
        '${result['recommended_machine_types']}',
      );
      print('========================================');
      print('');

      return result;
    } on ApiException {
      rethrow;
    } catch (error) {
      print('');
      print('========================================');
      print('        ML SERVICE ERROR');
      print('========================================');
      print(error);
      print('========================================');

      throw ApiException(
        'Unable to get AI prediction: $error',
      );
    }
  }
}