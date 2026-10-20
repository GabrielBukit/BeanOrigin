import 'package:equatable/equatable.dart';

class BatchModel extends Equatable {
  final String id;
  final String farmerId;
  final String farmerName;
  final String variety;
  final String origin;
  final String process;
  final double elevationMasl;
  final double? moistureContent;
  final double? cuppingScore;
  final String status;
  final double? weightKg;
  final double? latitude;
  final double? longitude;
  final double? slopeAngle;
  final String? notes;
  final String? defectResult;
  final String? llmAdvisory;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? exportedAt;

  const BatchModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.variety,
    required this.origin,
    required this.process,
    required this.elevationMasl,
    this.moistureContent,
    this.cuppingScore,
    required this.status,
    this.weightKg,
    this.latitude,
    this.longitude,
    this.slopeAngle,
    this.notes,
    this.defectResult,
    this.llmAdvisory,
    required this.createdAt,
    this.verifiedAt,
    this.exportedAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String? ?? 'Unknown',
      variety: json['variety'] as String,
      origin: json['origin'] as String,
      process: json['process'] as String,
      elevationMasl: (json['elevation_masl'] as num).toDouble(),
      moistureContent: (json['moisture_content'] as num?)?.toDouble(),
      cuppingScore: (json['cupping_score'] as num?)?.toDouble(),
      status: json['status'] as String,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      slopeAngle: (json['slope_angle'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      defectResult: json['defect_result'] as String?,
      llmAdvisory: json['llm_advisory'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      exportedAt: json['exported_at'] != null
          ? DateTime.parse(json['exported_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'variety': variety,
      'origin': origin,
      'process': process,
      'elevation_masl': elevationMasl,
      'moisture_content': moistureContent,
      'cupping_score': cuppingScore,
      'status': status,
      'weight_kg': weightKg,
      'latitude': latitude,
      'longitude': longitude,
      'slope_angle': slopeAngle,
      'notes': notes,
      'defect_result': defectResult,
      'llm_advisory': llmAdvisory,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'exported_at': exportedAt?.toIso8601String(),
    };
  }

  BatchModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? variety,
    String? origin,
    String? process,
    double? elevationMasl,
    double? moistureContent,
    double? cuppingScore,
    String? status,
    double? weightKg,
    double? latitude,
    double? longitude,
    double? slopeAngle,
    String? notes,
    String? defectResult,
    String? llmAdvisory,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? exportedAt,
  }) {
    return BatchModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      variety: variety ?? this.variety,
      origin: origin ?? this.origin,
      process: process ?? this.process,
      elevationMasl: elevationMasl ?? this.elevationMasl,
      moistureContent: moistureContent ?? this.moistureContent,
      cuppingScore: cuppingScore ?? this.cuppingScore,
      status: status ?? this.status,
      weightKg: weightKg ?? this.weightKg,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      slopeAngle: slopeAngle ?? this.slopeAngle,
      notes: notes ?? this.notes,
      defectResult: defectResult ?? this.defectResult,
      llmAdvisory: llmAdvisory ?? this.llmAdvisory,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      exportedAt: exportedAt ?? this.exportedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'verified':
        return 'Terverifikasi';
      case 'exported':
        return 'Diekspor';
      case 'sold':
        return 'Terjual';
      default:
        return status;
    }
  }

  String get gradeLabel {
    if (cuppingScore == null) return 'Belum Dinilai';
    if (cuppingScore! >= 85) return 'Specialty Grade';
    if (cuppingScore! >= 80) return 'Premium Grade';
    if (cuppingScore! >= 70) return 'Exchange Grade';
    return 'Below Standard';
  }

  @override
  List<Object?> get props => [
        id, farmerId, variety, origin, process, elevationMasl,
        moistureContent, cuppingScore, status, weightKg,
        latitude, longitude, slopeAngle, createdAt,
      ];
}
