import 'package:bean_origin/shared/models/batch_model.dart';

class BatchRepository {
  // Singleton
  static final BatchRepository _instance = BatchRepository._internal();
  factory BatchRepository() => _instance;
  BatchRepository._internal() {
    _batches = List.from(_sampleBatches);
  }

  late List<BatchModel> _batches;

  // ─── Sample Data ──────────────────────────────────────────
  static final List<BatchModel> _sampleBatches = [
    BatchModel(
      id: 'BATCH-001',
      farmerId: 'user_001',
      farmerName: 'Ahmad Gayo',
      variety: 'Arabika Gayo',
      origin: 'Aceh Tengah',
      process: 'Washed',
      elevationMasl: 1600,
      moistureContent: 11.5,
      cuppingScore: 87.5,
      status: 'verified',
      weightKg: 250,
      latitude: 4.6167,
      longitude: 96.8333,
      slopeAngle: 12.5,
      notes: 'Panen musim hujan 2026, fermentasi 48 jam',
      createdAt: DateTime(2026, 9, 15),
      verifiedAt: DateTime(2026, 9, 20),
    ),
    BatchModel(
      id: 'BATCH-002',
      farmerId: 'user_002',
      farmerName: 'Budi Toraja',
      variety: 'Arabika Toraja',
      origin: 'Toraja',
      process: 'Natural',
      elevationMasl: 1800,
      moistureContent: 10.8,
      cuppingScore: 89.0,
      status: 'exported',
      weightKg: 180,
      latitude: -3.0500,
      longitude: 119.8500,
      slopeAngle: 18.0,
      notes: 'Single origin, dry mill proses alami',
      createdAt: DateTime(2026, 8, 10),
      verifiedAt: DateTime(2026, 8, 18),
      exportedAt: DateTime(2026, 9, 1),
    ),
    BatchModel(
      id: 'BATCH-003',
      farmerId: 'user_001',
      farmerName: 'Ahmad Gayo',
      variety: 'Robusta Lampung',
      origin: 'Lampung',
      process: 'Semi-Washed',
      elevationMasl: 800,
      moistureContent: 12.0,
      cuppingScore: 78.0,
      status: 'pending',
      weightKg: 500,
      latitude: -5.3971,
      longitude: 105.2668,
      slopeAngle: 5.3,
      notes: 'Robusta grade A, siap cupping',
      createdAt: DateTime(2026, 10, 1),
    ),
    BatchModel(
      id: 'BATCH-004',
      farmerId: 'user_003',
      farmerName: 'Ketut Kintamani',
      variety: 'Arabika Kintamani',
      origin: 'Kintamani',
      process: 'Honey',
      elevationMasl: 1200,
      moistureContent: 11.0,
      cuppingScore: 85.5,
      status: 'verified',
      weightKg: 120,
      latitude: -8.2833,
      longitude: 115.3500,
      slopeAngle: 15.2,
      notes: 'Honey process, penjemuran raised bed',
      createdAt: DateTime(2026, 9, 25),
      verifiedAt: DateTime(2026, 10, 2),
    ),
    BatchModel(
      id: 'BATCH-005',
      farmerId: 'user_004',
      farmerName: 'Yohanes Wamena',
      variety: 'Arabika Wamena',
      origin: 'Wamena',
      process: 'Washed',
      elevationMasl: 1850,
      moistureContent: 10.5,
      cuppingScore: 91.0,
      status: 'verified',
      weightKg: 80,
      latitude: -4.1000,
      longitude: 138.9500,
      slopeAngle: 22.0,
      notes: 'Specialty grade, altitude premium',
      createdAt: DateTime(2026, 9, 5),
      verifiedAt: DateTime(2026, 9, 12),
    ),
    BatchModel(
      id: 'BATCH-006',
      farmerId: 'user_005',
      farmerName: 'Maria Flores',
      variety: 'Arabika Flores',
      origin: 'Flores Bajawa',
      process: 'Wet-Hulled (Giling Basah)',
      elevationMasl: 1500,
      moistureContent: 13.0,
      cuppingScore: 83.0,
      status: 'pending',
      weightKg: 300,
      latitude: -8.7833,
      longitude: 121.0167,
      slopeAngle: 20.0,
      notes: 'Giling basah tradisional, sortasi manual',
      createdAt: DateTime(2026, 10, 10),
    ),
    BatchModel(
      id: 'BATCH-007',
      farmerId: 'user_002',
      farmerName: 'Budi Toraja',
      variety: 'Arabika Java',
      origin: 'Temanggung',
      process: 'Anaerobic',
      elevationMasl: 1100,
      moistureContent: 11.2,
      cuppingScore: 86.0,
      status: 'exported',
      weightKg: 200,
      latitude: -7.3167,
      longitude: 110.1667,
      slopeAngle: 10.0,
      notes: 'Anaerobic fermentation 72 jam',
      createdAt: DateTime(2026, 8, 20),
      verifiedAt: DateTime(2026, 8, 28),
      exportedAt: DateTime(2026, 9, 15),
    ),
    BatchModel(
      id: 'BATCH-008',
      farmerId: 'user_006',
      farmerName: 'Siti Dampit',
      variety: 'Robusta Dampit',
      origin: 'Dampit Malang',
      process: 'Natural',
      elevationMasl: 650,
      moistureContent: 12.5,
      cuppingScore: 75.5,
      status: 'pending',
      weightKg: 450,
      latitude: -8.2000,
      longitude: 112.7500,
      slopeAngle: 8.0,
      notes: 'Fine robusta, penjemuran patio',
      createdAt: DateTime(2026, 10, 15),
    ),
  ];

  // ─── CRUD ─────────────────────────────────────────────────
  List<BatchModel> getAllBatches() => List.unmodifiable(_batches);

  BatchModel? getBatchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BatchModel> searchBatches({
    String? query,
    String? variety,
    String? origin,
    String? status,
    double? minScore,
    double? maxScore,
  }) {
    return _batches.where((batch) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!batch.variety.toLowerCase().contains(q) &&
            !batch.origin.toLowerCase().contains(q) &&
            !batch.farmerName.toLowerCase().contains(q) &&
            !batch.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (variety != null && variety.isNotEmpty && batch.variety != variety) return false;
      if (origin != null && origin.isNotEmpty && batch.origin != origin) return false;
      if (status != null && status.isNotEmpty && batch.status != status) return false;
      if (minScore != null && (batch.cuppingScore ?? 0) < minScore) return false;
      if (maxScore != null && (batch.cuppingScore ?? 100) > maxScore) return false;
      return true;
    }).toList();
  }

  void addBatch(BatchModel batch) {
    _batches.insert(0, batch);
  }

  void updateBatch(BatchModel updated) {
    final index = _batches.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _batches[index] = updated;
    }
  }

  void deleteBatch(String id) {
    _batches.removeWhere((b) => b.id == id);
  }
}
