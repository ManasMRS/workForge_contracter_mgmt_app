import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AiPredictionResultScreen
    extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final AppMood mood;

  const AiPredictionResultScreen({
    super.key,
    required this.prediction,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedCost =
        prediction[
                'estimated_total_cost_inr'] ??
            0;

    final duration =
        prediction[
                'estimated_duration_days'] ??
            0;

    final machineCount =
        prediction[
                'estimated_machine_count'] ??
            0;

    final machines =
        prediction[
                    'recommended_machine_types']
                is List
            ? List<String>.from(
                prediction[
                    'recommended_machine_types'],
              )
            : <String>[];

    return Scaffold(
      backgroundColor:
          Colors.transparent,

      appBar: AppBar(
        title: const Text(
          'AI Prediction Result',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        foregroundColor:
            Colors.white,
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

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _buildHeader(),

                const SizedBox(
                  height: 24,
                ),

                _buildPredictionCard(
                  icon:
                      Icons.currency_rupee,
                  title:
                      'Estimated Total Cost',
                  value:
                      '₹${_formatNumber(estimatedCost)}',
                ),

                const SizedBox(
                  height: 16,
                ),

                _buildPredictionCard(
                  icon:
                      Icons.calendar_month,
                  title:
                      'Estimated Duration',
                  value:
                      '$duration Days',
                ),

                const SizedBox(
                  height: 16,
                ),

                _buildPredictionCard(
                  icon:
                      Icons.construction,
                  title:
                      'Estimated Machines',
                  value:
                      '$machineCount',
                ),

                const SizedBox(
                  height: 24,
                ),

                _buildMachineSection(
                  machines,
                ),

                const SizedBox(
                  height: 30,
                ),

                SizedBox(
                  width: double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: Icon(
                      Icons.arrow_back,
                      color:
                          mood.textOnAccent,
                    ),

                    label: Text(
                      'Back to AI Estimator',
                      style: TextStyle(
                        color:
                            mood.textOnAccent,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          mood.accent.first,

                      foregroundColor:
                          mood.textOnAccent,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(22),

      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          colors:
              mood.accent,
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: mood.accent.first
                .withOpacity(0.30),

            blurRadius: 15,

            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 42,
            color:
                mood.textOnAccent,
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'AI Site Estimation Complete',
                  style: TextStyle(
                    color:
                        mood.textOnAccent,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Your ML prediction is ready.',
                  style: TextStyle(
                    color: mood
                        .textOnAccent
                        .withOpacity(
                      0.80,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION CARD
  // ============================================================

  Widget _buildPredictionCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.10,
        ),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.12,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(14),

            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors:
                    mood.accent,
              ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Icon(
              icon,
              color:
                  mood.textOnAccent,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MACHINES
  // ============================================================

  Widget _buildMachineSection(
    List<String> machines,
  ) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.10,
        ),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.10,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Recommended Machine Types',

            style: TextStyle(
              color:
                  Colors.white,

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          if (machines.isEmpty)
            const Text(
              'No machine recommendations available.',

              style: TextStyle(
                color:
                    Colors.white70,
              ),
            )
          else
            ...machines.map(
              (machine) =>
                  Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color:
                          mood.accent.last,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        machine,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NUMBER FORMATTER
  // ============================================================

  String _formatNumber(
    dynamic value,
  ) {
    final number =
        double.tryParse(
              value.toString(),
            ) ??
            0;

    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (match) => ',',
        );
  }
}