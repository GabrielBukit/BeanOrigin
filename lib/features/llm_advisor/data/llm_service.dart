import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/shared/models/batch_model.dart';

class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  // Cache to avoid redundant API calls
  final Map<String, String> _cache = {};

  bool get isApiConfigured =>
      AppConstants.geminiApiKey.isNotEmpty &&
      AppConstants.geminiApiKey != 'YOUR_GEMINI_API_KEY';

  /// Generate advisory content via Gemini API
  Future<Map<String, String>> generateAdvisory(BatchModel batch) async {
    final cacheKey = '${batch.id}_${batch.cuppingScore}_${batch.status}';
    if (_cache.containsKey(cacheKey)) {
      return _parseAdvisoryFromCache(_cache[cacheKey]!);
    }

    if (!isApiConfigured) {
      return _generateLocalAdvisory(batch);
    }

    try {
      final prompt = _buildAdvisoryPrompt(batch);
      final response = await _callGemini(prompt);
      _cache[cacheKey] = response;
      return _parseAdvisoryResponse(response);
    } catch (e) {
      // Fallback to local generation
      return _generateLocalAdvisory(batch);
    }
  }

  /// Send a custom question to Gemini
  Future<String> askQuestion(String question, {BatchModel? batch}) async {
    if (!isApiConfigured) {
      return _generateLocalAnswer(question, batch);
    }

    try {
      String prompt = question;
      if (batch != null) {
        prompt = '''Konteks batch kopi:
- Varietas: ${batch.variety}
- Asal: ${batch.origin}
- Ketinggian: ${batch.elevationMasl.toInt()} mdpl
- Proses: ${batch.process}
- Cupping Score: ${batch.cuppingScore ?? 'belum dinilai'}
- Kadar Air: ${batch.moistureContent ?? 'belum diukur'}%

Pertanyaan: $question''';
      }
      return await _callGemini(prompt);
    } catch (e) {
      return _generateLocalAnswer(question, batch);
    }
  }

  /// Call Gemini API
  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(
      '${AppConstants.geminiBaseUrl}/models/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.95,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      throw Exception('Empty response from Gemini');
    } else {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  String _buildAdvisoryPrompt(BatchModel batch) {
    return '''Kamu adalah ahli kopi dan konsultan ekspor Indonesia. Berikan analisis dan rekomendasi untuk batch kopi berikut dalam format yang rapi.

DATA BATCH:
- Varietas: ${batch.variety}
- Asal: ${batch.origin}
- Ketinggian: ${batch.elevationMasl.toInt()} mdpl
- Proses Pascapanen: ${batch.process}
- Cupping Score: ${batch.cuppingScore?.toStringAsFixed(1) ?? 'belum dinilai'} SCA
- Kadar Air: ${batch.moistureContent?.toStringAsFixed(1) ?? 'belum diukur'}%
- Berat: ${batch.weightKg ?? 0} kg
- Status: ${batch.statusDisplayName}

BERIKAN 3 BAGIAN ANALISIS (gunakan emoji dan format yang menarik):

1. 🔥 REKOMENDASI ROASTING PROFILE
- Jenis roast yang direkomendasikan (light/medium/dark)
- Suhu dan durasi
- Tips roasting spesifik untuk varietas ini

2. ☕ CUPPING NOTES DESKRIPSI
- Aroma
- Flavor
- Acidity
- Body
- Best brewing method

3. 📋 CHECKLIST KEPATUHAN EKSPOR
- Status terhadap standar SNI
- Status terhadap standar SCAA  
- Daftar dokumen yang diperlukan

Gunakan bahasa Indonesia yang jelas dan informatif.''';
  }

  Map<String, String> _parseAdvisoryResponse(String response) {
    // Try to split by sections
    String roasting = '';
    String cupping = '';
    String export = '';

    final sections = response.split(RegExp(r'(?=🔥|☕|📋)'));
    for (final section in sections) {
      if (section.contains('ROASTING') || section.contains('🔥')) {
        roasting = section.trim();
      } else if (section.contains('CUPPING') || section.contains('☕')) {
        cupping = section.trim();
      } else if (section.contains('CHECKLIST') || section.contains('EKSPOR') || section.contains('📋')) {
        export = section.trim();
      }
    }

    // If parsing fails, put everything in roasting
    if (roasting.isEmpty && cupping.isEmpty && export.isEmpty) {
      roasting = response;
    }

    return {
      'roasting': roasting,
      'cupping': cupping,
      'export': export,
    };
  }

  Map<String, String> _parseAdvisoryFromCache(String cached) {
    return _parseAdvisoryResponse(cached);
  }

  // ─── Local Fallback Generation ─────────────────────────────

  Map<String, String> _generateLocalAdvisory(BatchModel batch) {
    return {
      'roasting': _generateRoastingProfile(batch),
      'cupping': _generateCuppingNotes(batch),
      'export': _generateExportChecklist(batch),
    };
  }

  String _generateRoastingProfile(BatchModel batch) {
    final isHighAlt = batch.elevationMasl > 1400;
    final isSpecialty = (batch.cuppingScore ?? 0) >= 85;

    if (isHighAlt && isSpecialty) {
      return '''🔥 Profil Roasting Rekomendasi: LIGHT ROAST

📊 Parameter:
• Suhu awal: 180°C (charge temperature)
• Suhu first crack: 196-200°C
• Drop temperature: 202-205°C
• Durasi total: 10-12 menit
• Development time: 15-18% dari total

💡 Alasan:
Biji ${batch.variety} dari ${batch.origin} pada ketinggian ${batch.elevationMasl.toInt()} mdpl memiliki kepadatan tinggi dan kompleksitas rasa yang optimal untuk light roast. Proses ${batch.process} akan menghasilkan profil rasa yang lebih terang.

⚡ Tips:
• Gunakan airflow tinggi di awal untuk menghilangkan moisture
• Kurangi gas secara bertahap menjelang first crack
• Jangan melebihi first crack lebih dari 1 menit''';
    } else if (isHighAlt) {
      return '''🔥 Profil Roasting Rekomendasi: MEDIUM ROAST

📊 Parameter:
• Suhu awal: 185°C
• Suhu first crack: 196-200°C
• Drop temperature: 210-215°C
• Durasi total: 12-14 menit
• Development time: 18-22%

💡 Alasan:
${batch.variety} dari ${batch.origin} cocok untuk medium roast yang menonjolkan balance antara acidity dan body. Proses ${batch.process} memberikan sweetness yang baik pada level ini.

⚡ Tips:
• Pastikan first crack sempurna sebelum melanjutkan
• Monitor warna biji secara visual
• Cooling harus cepat untuk menghentikan proses roasting''';
    } else {
      return '''🔥 Profil Roasting Rekomendasi: MEDIUM-DARK ROAST

📊 Parameter:
• Suhu awal: 190°C
• Suhu first crack: 196-200°C
• Drop temperature: 220-225°C
• Durasi total: 14-16 menit
• Development time: 22-25%

💡 Alasan:
${batch.variety} dari ketinggian ${batch.elevationMasl.toInt()} mdpl akan lebih optimal pada roast level yang lebih gelap untuk menonjolkan body dan chocolate notes.

⚡ Tips:
• Perhatikan second crack — drop sebelum second crack berakhir
• Roast ini cocok untuk espresso blend
• Optimal untuk brewing method immersion (french press)''';
    }
  }

  String _generateCuppingNotes(BatchModel batch) {
    final notes = <String>[];
    final variety = batch.variety.toLowerCase();

    if (variety.contains('gayo')) {
      notes.addAll(['🌺 Aroma: Herbal, earthy, tobacco', '👅 Flavor: Cedar, dark chocolate, spice', '🍋 Acidity: Medium, juicy', '🍫 Body: Full, syrupy']);
    } else if (variety.contains('toraja')) {
      notes.addAll(['🌺 Aroma: Floral, fruity', '👅 Flavor: Stone fruit, brown sugar, vanilla', '🍋 Acidity: Bright, citric', '🍫 Body: Medium-full, creamy']);
    } else if (variety.contains('kintamani')) {
      notes.addAll(['🌺 Aroma: Citrus, jasmine', '👅 Flavor: Mandarin, honey, caramel', '🍋 Acidity: High, bright', '🍫 Body: Medium, clean']);
    } else if (variety.contains('wamena')) {
      notes.addAll(['🌺 Aroma: Sweet, floral', '👅 Flavor: Tropical fruit, vanilla, almond', '🍋 Acidity: High, complex', '🍫 Body: Medium, silky']);
    } else if (variety.contains('flores')) {
      notes.addAll(['🌺 Aroma: Earthy, spice', '👅 Flavor: Dark chocolate, nuts, molasses', '🍋 Acidity: Low-medium', '🍫 Body: Full, heavy']);
    } else if (variety.contains('robusta')) {
      notes.addAll(['🌺 Aroma: Earthy, woody', '👅 Flavor: Bitter chocolate, grain, rubber', '🍋 Acidity: Low', '🍫 Body: Very full, thick']);
    } else {
      notes.addAll(['🌺 Aroma: Sweet, nutty', '👅 Flavor: Chocolate, caramel, nuts', '🍋 Acidity: Medium', '🍫 Body: Medium-full']);
    }

    final score = batch.cuppingScore ?? 80;
    notes.add('\n📈 Skor Cupping Prediksi: ${score.toStringAsFixed(1)} SCA');
    notes.add('🏅 Grade: ${batch.gradeLabel}');
    notes.add('\n☕ Best Brewing: ${score >= 85 ? "Pour Over (V60, Chemex)" : "Espresso, Moka Pot"}');

    return notes.join('\n');
  }

  String _generateExportChecklist(BatchModel batch) {
    final score = batch.cuppingScore ?? 0;
    final moisture = batch.moistureContent ?? 0;

    return '''📋 Checklist Kepatuhan Ekspor

✅ Standar SNI (Badan Standarisasi Nasional):
${score >= 80 ? '  ✓' : '  ✗'} Cupping Score ≥ 80 SCA — ${score.toStringAsFixed(1)} (${score >= 80 ? 'LULUS' : 'BELUM LULUS'})
${moisture <= 12.5 ? '  ✓' : '  ✗'} Kadar Air ≤ 12.5% — ${moisture.toStringAsFixed(1)}% (${moisture <= 12.5 ? 'LULUS' : 'TERLALU TINGGI'})
  ⬜ Bebas serangga hidup — Perlu inspeksi
  ⬜ Ukuran biji sesuai grade — Perlu screening

✅ Standar SCAA (Specialty Coffee Association):
${score >= 85 ? '  ✓' : '  ⬜'} Specialty Grade (≥85 SCA)
  ⬜ Maks 5 full defects per 350g sample
  ⬜ No Category 1 defects (black, sour, fungus)
  ⬜ Moisture 10-12%

✅ Dokumen Ekspor:
  ⬜ Surat Keterangan Asal (SKA)
  ⬜ Phytosanitary Certificate
  ⬜ ICO Certificate of Origin
  ⬜ Bill of Lading
  ⬜ Packing List & Invoice
  ⬜ Fumigation Certificate

📦 Status: ${batch.status == 'exported' ? 'SIAP EKSPOR ✅' : 'PROSES VERIFIKASI...'}''';
  }

  String _generateLocalAnswer(String question, BatchModel? batch) {
    final q = question.toLowerCase();
    if (q.contains('roast')) {
      return 'Untuk roasting, setiap varietas kopi memiliki profil yang berbeda. '
          'Kopi dari dataran tinggi (>1400 mdpl) umumnya cocok untuk light-medium roast '
          'untuk menonjolkan kompleksitas rasa. Sedangkan kopi dataran rendah lebih cocok '
          'untuk medium-dark roast.\n\n'
          'Tip: Gunakan fitur AI Advisory di detail batch untuk rekomendasi spesifik!';
    } else if (q.contains('ekspor') || q.contains('export')) {
      return 'Untuk mengekspor kopi dari Indonesia, diperlukan:\n'
          '1. Cupping Score minimal 80 SCA\n'
          '2. Kadar air ≤ 12.5%\n'
          '3. Surat Keterangan Asal (SKA)\n'
          '4. Phytosanitary Certificate\n'
          '5. ICO Certificate of Origin\n\n'
          'Pastikan batch kopi sudah diverifikasi oleh Q-Grader sebelum proses ekspor.';
    } else {
      return 'Terima kasih atas pertanyaan Anda! Saat ini saya menggunakan mode offline. '
          'Untuk jawaban yang lebih akurat, pastikan Gemini API key sudah dikonfigurasi '
          'di file constants.dart.\n\n'
          'Beberapa topik yang bisa saya bantu:\n'
          '• Rekomendasi roasting profile\n'
          '• Cupping notes dan deskripsi rasa\n'
          '• Checklist kepatuhan ekspor\n'
          '• Info varietas kopi Indonesia';
    }
  }
}
