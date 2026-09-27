import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/ml_prediction_service.dart';
import 'ai_prediction_result_screen.dart';

class SitePredictionScreen extends StatefulWidget {
  final AppMood mood;

  const SitePredictionScreen({
    super.key,
    required this.mood,
  });

  @override
  State<SitePredictionScreen> createState() =>
      _SitePredictionScreenState();
}

class _SitePredictionScreenState
    extends State<SitePredictionScreen> {
  late final MlPredictionService _mlService;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _areaController =
      TextEditingController(text: '1800');

  final TextEditingController _floorsController =
      TextEditingController(text: '1');

  final TextEditingController _workersController =
      TextEditingController(text: '10');

  String _siteType = 'Home';
  String _cityTier = 'tier2';
  String _qualityTier = 'standard';
  String _roadQuality = 'pichu';

  bool _loading = false;

  String? _errorMessage;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    final authService = AuthService();

    final apiService = ApiService(
      authService,
    );

    _mlService = MlPredictionService(
      apiService,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _areaController.dispose();
    _floorsController.dispose();
    _workersController.dispose();

    super.dispose();
  }

  // ============================================================
  // AI PREDICTION
  // ============================================================

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final double area =
          double.parse(
        _areaController.text.trim(),
      );

      final int floors =
          int.parse(
        _floorsController.text.trim(),
      );

      final int workers =
          int.parse(
        _workersController.text.trim(),
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        'STARTING AI SITE PREDICTION',
      );

      debugPrint(
        'Site Type: $_siteType',
      );

      debugPrint(
        'Area: $area',
      );

      debugPrint(
        'Floors: $floors',
      );

      debugPrint(
        'Workers: $workers',
      );

      debugPrint(
        'City Tier: $_cityTier',
      );

      debugPrint(
        'Quality Tier: $_qualityTier',
      );

      debugPrint(
        'Road Quality: $_roadQuality',
      );

      debugPrint(
        '========================================',
      );

      // ========================================================
      // CALL ML SERVICE
      // ========================================================

      final result =
          await _mlService.predict(
        siteType: _siteType,
        scopeAreaSqft: area,
        floors: floors,
        plannedWorkers: workers,
        cityTier: _cityTier,
        qualityTier: _qualityTier,
        roadQuality:
            _siteType == 'Road'
                ? _roadQuality
                : 'Not Applicable',
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        'AI RESULT RECEIVED',
      );

      debugPrint(
        result.toString(),
      );

      debugPrint(
        '========================================',
      );

      if (!mounted) {
        return;
      }

      final prediction =
          Map<String, dynamic>.from(
        result,
      );

      setState(() {
        _loading = false;
      });

      // ========================================================
      // OPEN RESULT SCREEN
      // ========================================================

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AiPredictionResultScreen(
            prediction: prediction,
            mood: widget.mood,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'AI PREDICTION ERROR',
      );

      debugPrint(
        error.toString(),
      );

      debugPrint(
        '========================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _errorMessage =
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood;

    return Scaffold(
      backgroundColor:
          Colors.transparent,

      appBar: AppBar(
        title: const Text(
          'AI Site Estimator',
        ),
        centerTitle: true,
        backgroundColor:
            Colors.transparent,
        foregroundColor:
            Colors.white,
        elevation: 0,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            colors:
                mood.background,
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  _buildHeader(),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Site Information',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildSiteTypeDropdown(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildAreaField(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildFloorsField(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildWorkersField(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildCityTierDropdown(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildQualityDropdown(),

                  if (_siteType ==
                      'Road') ...[
                    const SizedBox(
                      height: 16,
                    ),
                    _buildRoadQualityDropdown(),
                  ],

                  const SizedBox(
                    height: 26,
                  ),

                  _buildPredictButton(),

                  if (_loading) ...[
                    const SizedBox(
                      height: 18,
                    ),
                    _buildLoadingCard(),
                  ],

                  if (_errorMessage !=
                      null) ...[
                    const SizedBox(
                      height: 18,
                    ),
                    _buildErrorCard(),
                  ],

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final mood = widget.mood;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(22),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22),

        gradient:
            LinearGradient(
          colors: mood.accent,
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(
            color: mood.accent.first
                .withOpacity(0.30),
            blurRadius: 14,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.auto_awesome,
            color:
                mood.textOnAccent,
            size: 38,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'AI Site Estimator',
            style: TextStyle(
              color:
                  mood.textOnAccent,
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Use trained machine learning models to estimate construction cost, project duration and machine requirements.',
            style: TextStyle(
              color: mood.textOnAccent
                  .withOpacity(0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SITE TYPE
  // ============================================================

  Widget _buildSiteTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _siteType,

      decoration:
          const InputDecoration(
        labelText: 'Site Type',
        prefixIcon:
            Icon(Icons.location_city),
      ),

      items: const [
        'Home',
        'Office',
        'Road',
        'Bridge',
        'School',
        'Hospital',
        'Apartment',
        'Other',
      ].map(
        (type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        },
      ).toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _siteType = value;
        });
      },
    );
  }

  // ============================================================
  // AREA
  // ============================================================

  Widget _buildAreaField() {
    return TextFormField(
      controller:
          _areaController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration:
          const InputDecoration(
        labelText:
            'Scope Area (sq ft)',
        hintText:
            'Example: 1800',
        prefixIcon:
            Icon(Icons.square_foot),
      ),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Enter scope area';
        }

        final area =
            double.tryParse(
          value.trim(),
        );

        if (area == null ||
            area <= 0) {
          return 'Enter a valid area';
        }

        return null;
      },
    );
  }

  // ============================================================
  // FLOORS
  // ============================================================

  Widget _buildFloorsField() {
    return TextFormField(
      controller:
          _floorsController,

      keyboardType:
          TextInputType.number,

      decoration:
          const InputDecoration(
        labelText:
            'Number of Floors',
        prefixIcon:
            Icon(Icons.layers),
      ),

      validator: (value) {
        final floors =
            int.tryParse(
          value?.trim() ?? '',
        );

        if (floors == null ||
            floors < 1) {
          return 'Enter a valid number of floors';
        }

        return null;
      },
    );
  }

  // ============================================================
  // WORKERS
  // ============================================================

  Widget _buildWorkersField() {
    return TextFormField(
      controller:
          _workersController,

      keyboardType:
          TextInputType.number,

      decoration:
          const InputDecoration(
        labelText:
            'Planned Workers',
        prefixIcon:
            Icon(Icons.people),
      ),

      validator: (value) {
        final workers =
            int.tryParse(
          value?.trim() ?? '',
        );

        if (workers == null ||
            workers < 1) {
          return 'Enter a valid number of workers';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CITY TIER
  // ============================================================

  Widget _buildCityTierDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _cityTier,

      decoration:
          const InputDecoration(
        labelText:
            'City Tier',
        prefixIcon:
            Icon(Icons.location_on),
      ),

      items: const [
        DropdownMenuItem(
          value: 'tier1',
          child: Text('Tier 1'),
        ),
        DropdownMenuItem(
          value: 'tier2',
          child: Text('Tier 2'),
        ),
        DropdownMenuItem(
          value: 'tier3',
          child: Text('Tier 3'),
        ),
      ],

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _cityTier = value;
        });
      },
    );
  }

  // ============================================================
  // QUALITY
  // ============================================================

  Widget _buildQualityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _qualityTier,

      decoration:
          const InputDecoration(
        labelText:
            'Quality Tier',
        prefixIcon:
            Icon(Icons.high_quality),
      ),

      items: const [
        DropdownMenuItem(
          value: 'basic',
          child: Text('Basic'),
        ),
        DropdownMenuItem(
          value: 'standard',
          child: Text('Standard'),
        ),
        DropdownMenuItem(
          value: 'premium',
          child: Text('Premium'),
        ),
      ],

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _qualityTier = value;
        });
      },
    );
  }

  // ============================================================
  // ROAD QUALITY
  // ============================================================

  Widget _buildRoadQualityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _roadQuality,

      decoration:
          const InputDecoration(
        labelText:
            'Road Quality',
        prefixIcon:
            Icon(Icons.route),
      ),

      items: const [
        DropdownMenuItem(
          value: 'pichu',
          child:
              Text('Pichu / Asphalt'),
        ),
        DropdownMenuItem(
          value: 'concrete',
          child:
              Text('Concrete'),
        ),
      ],

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _roadQuality = value;
        });
      },
    );
  }

  // ============================================================
  // PREDICT BUTTON
  // ============================================================

  Widget _buildPredictButton() {
    final mood = widget.mood;

    return SizedBox(
      width: double.infinity,
      height: 56,

      child: DecoratedBox(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),

          gradient:
              LinearGradient(
            colors:
                mood.accent,
          ),

          boxShadow: [
            BoxShadow(
              color: mood.accent.first
                  .withOpacity(0.30),
              blurRadius: 10,
              offset:
                  const Offset(0, 5),
            ),
          ],
        ),

        child:
            ElevatedButton.icon(
          onPressed:
              _loading
                  ? null
                  : _predict,

          icon: _loading
              ? SizedBox(
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color:
                        mood.textOnAccent,
                  ),
                )
              : Icon(
                  Icons.auto_awesome,
                  color:
                      mood.textOnAccent,
                ),

          label: Text(
            _loading
                ? 'Running ML Prediction...'
                : 'Predict Site',

            style: TextStyle(
              color:
                  mood.textOnAccent,
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            foregroundColor:
                mood.textOnAccent,
            shadowColor:
                Colors.transparent,
            surfaceTintColor:
                Colors.transparent,
            disabledBackgroundColor:
                Colors.transparent,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingCard() {
    final mood = widget.mood;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: mood.accent.first
              .withOpacity(0.25),
        ),
      ),

      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,

            child:
                CircularProgressIndicator(
              strokeWidth: 2.5,
              color:
                  mood.accent.first,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Text(
              'AI model is analyzing your construction project...',
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            Colors.red.withOpacity(0.12),

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.red.withOpacity(0.35),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Prediction Failed',
                  style: TextStyle(
                    color:
                        Colors.redAccent,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  _errorMessage ??
                      'Unknown error',
                  style:
                      const TextStyle(
                    color:
                        Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}