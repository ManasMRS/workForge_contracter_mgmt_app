/// Response returned by both /predict/house and /predict/road.
class CostEstimate {
  final double estimatedCostInr;
  final double lowEstimateInr;
  final double highEstimateInr;

  CostEstimate({
    required this.estimatedCostInr,
    required this.lowEstimateInr,
    required this.highEstimateInr,
  });

  factory CostEstimate.fromJson(Map<String, dynamic> json) {
    return CostEstimate(
      estimatedCostInr: (json['estimated_cost_inr'] as num).toDouble(),
      lowEstimateInr: (json['low_estimate_inr'] as num).toDouble(),
      highEstimateInr: (json['high_estimate_inr'] as num).toDouble(),
    );
  }
}

enum QualityTier { basic, standard, premium }

enum CityTier { tier1, tier2, tier3 }

enum StructureType { rccFrame, loadBearing }

enum FoundationType { normal, raft, pile }

enum ConcreteGrade { m15, m20, m25, m30 }

extension QualityTierX on QualityTier {
  String get apiValue => name; // basic / standard / premium
}

extension CityTierX on CityTier {
  String get apiValue => name; // tier1 / tier2 / tier3
}

extension StructureTypeX on StructureType {
  String get apiValue => this == StructureType.rccFrame ? 'RCC_frame' : 'load_bearing';
}

extension FoundationTypeX on FoundationType {
  String get apiValue => name; // normal / raft / pile
}

extension ConcreteGradeX on ConcreteGrade {
  String get apiValue => name.toUpperCase(); // M15 / M20 / M25 / M30
}

class HouseEstimateRequest {
  final double builtUpAreaSqft;
  final int floors;
  final QualityTier qualityTier;
  final CityTier cityTier;
  final StructureType structureType;
  final FoundationType foundationType;

  HouseEstimateRequest({
    required this.builtUpAreaSqft,
    required this.floors,
    this.qualityTier = QualityTier.standard,
    this.cityTier = CityTier.tier2,
    this.structureType = StructureType.rccFrame,
    this.foundationType = FoundationType.normal,
  });

  Map<String, dynamic> toJson() => {
        'built_up_area_sqft': builtUpAreaSqft,
        'floors': floors,
        'quality_tier': qualityTier.apiValue,
        'city_tier': cityTier.apiValue,
        'structure_type': structureType.apiValue,
        'foundation_type': foundationType.apiValue,
      };
}

class RoadEstimateRequest {
  final double lengthFt;
  final double widthFt;
  final double thicknessInch;
  final ConcreteGrade concreteGrade;
  final bool reinforcement;
  final bool hilly;

  RoadEstimateRequest({
    required this.lengthFt,
    required this.widthFt,
    this.thicknessInch = 6,
    this.concreteGrade = ConcreteGrade.m20,
    this.reinforcement = true,
    this.hilly = false,
  });

  Map<String, dynamic> toJson() => {
        'length_ft': lengthFt,
        'width_ft': widthFt,
        'thickness_inch': thicknessInch,
        'concrete_grade': concreteGrade.apiValue,
        'reinforcement': reinforcement ? 'yes' : 'no',
        'terrain': hilly ? 'hilly' : 'normal',
      };
}
