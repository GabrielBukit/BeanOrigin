import 'package:hive_flutter/hive_flutter.dart';
import 'package:bean_origin/core/utils/constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  // ─── Feedback Box ──────────────────────────────────────────

  Future<Box> _openFeedbackBox() async {
    return await Hive.openBox('feedback_cache');
  }

  Future<void> saveFeedback({
    required String kesan,
    required String saran,
    required int rating,
    String category = 'Kuliah PaM',
    String? role,
  }) async {
    final box = await _openFeedbackBox();
    final feedback = {
      'kesan': kesan,
      'saran': saran,
      'rating': rating,
      'category': category,
      'role': role ?? 'Umum',
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(feedback);
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final box = await _openFeedbackBox();
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList().reversed.toList();
  }

  // ─── Batch Cache Box ───────────────────────────────────────

  Future<Box> _openBatchCacheBox() async {
    return await Hive.openBox(AppConstants.hiveBatchBox);
  }

  Future<void> cacheBatch(Map<String, dynamic> batchJson) async {
    final box = await _openBatchCacheBox();
    await box.put(batchJson['id'], batchJson);
  }

  Future<List<Map<String, dynamic>>> getCachedBatches() async {
    final box = await _openBatchCacheBox();
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> clearBatchCache() async {
    final box = await _openBatchCacheBox();
    await box.clear();
  }

  // ─── Settings Box ──────────────────────────────────────────

  Future<Box> _openSettingsBox() async {
    return await Hive.openBox(AppConstants.hiveSettingsBox);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final box = await _openSettingsBox();
    await box.put(key, value);
  }

  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final box = await _openSettingsBox();
    return box.get(key, defaultValue: defaultValue);
  }

  // ─── LLM Cache Box ────────────────────────────────────────

  Future<Box> _openLlmCacheBox() async {
    return await Hive.openBox('llm_cache');
  }

  Future<void> cacheLlmResponse(String batchId, String response) async {
    final box = await _openLlmCacheBox();
    await box.put(batchId, {
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getCachedLlmResponse(String batchId) async {
    final box = await _openLlmCacheBox();
    final cached = box.get(batchId);
    if (cached != null) {
      final data = Map<String, dynamic>.from(cached as Map);
      final timestamp = DateTime.parse(data['timestamp'] as String);
      // Cache valid for 24 hours
      if (DateTime.now().difference(timestamp).inHours < 24) {
        return data['response'] as String;
      }
    }
    return null;
  }
}
