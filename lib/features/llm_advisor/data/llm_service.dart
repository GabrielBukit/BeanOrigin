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

  String? _customApiKey;

  void setCustomApiKey(String? key) {
    _customApiKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
    _cache.clear();
  }

  String get effectiveApiKey => _customApiKey ?? AppConstants.geminiApiKey;

  bool get isApiConfigured =>
      effectiveApiKey.isNotEmpty &&
      effectiveApiKey != 'YOUR_GEMINI_API_KEY';

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
      '${AppConstants.geminiBaseUrl}/models/${AppConstants.geminiModel}:generateContent?key=$effectiveApiKey',
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

    // 1. Roasting
    if (q.contains('roast') || q.contains('sangrai') || q.contains('crack')) {
      return '''🔥 Rekomendasi Roasting (Mode Offline Cerdas):
• Profil Roasting: Kopi dataran tinggi (>1300 mdpl) seperti ${batch?.variety ?? 'Arabika'} memiliki densitas biji tinggi, ideal untuk Light-to-Medium Roast guna menonjolkan keasaman cerah (bright acidity) dan floral/fruity notes.
• First Crack: Terjadi pada rentang 196°C - 200°C. Jangan terburu-buru menaikkan panas agar inti biji matang merata.
• Drop Temperature: Untuk Specialty V60/Manual Brew, turunkan (drop) di suhu 203°C - 208°C (development time 15-18%).
• Untuk Espresso Blend: Gunakan Medium-Dark Roast (drop 218°C - 224°C) untuk memaksimalkan body dan crema.''';
    }

    // 2. Ekspor & Regulasi EUDR
    if (q.contains('ekspor') || q.contains('export') || q.contains('eudr') || q.contains('syarat')) {
      return '''📋 Regulasi & Checklist Ekspor Kopi:
1. Mutu Fisik & Cupping:
   • Grade Specialty: Cupping score minimal 80.0 SCA.
   • Batas Kadar Air: 10.0% – 12.0% (Maksimal 12.5% sesuai SNI 01-2907-2008).
   • Cacat Primer (Category 1): 0 defects per 350 gram sampel.

2. Regulasi Anti-Deforestasi Uni Eropa (EUDR):
   • Geolocation Polygon: Setiap petak kebun petani wajib memiliki rekaman koordinat poligon GPS.
   • Bukti Lahan Bebas Deforestasi sejak cut-off date 31 Desember 2020.
   • Due Diligence Statement (DDS) yang diunggah ke portal TRACES EU.

3. Dokumen Legalitas Internasional:
   • Surat Keterangan Asal (SKA / Form ICO) dari Disperindag.
   • Phytosanitary Certificate dari Badan Karantina Pertanian.
   • Bill of Lading (B/L) & Fumigation Certificate.''';
    }

    // 3. Panen & Perawatan
    if (q.contains('panen') || q.contains('petik') || q.contains('rawat') || q.contains('pupuk') || q.contains('kebun')) {
      return '''🌱 Panduan Panen & Pemeliharaan Kebun Kopi:
• Petik Merah Optimal: Hanya petik buah ceri yang 95-100% merah matang sempurna (kadar gula/Brix mencapai 18-22%). Hindari ceri hijau (menimbulkan rasa astrigent/sepet).
• Floating Sortir Air: Rendam ceri panen dalam bak air; buang buah yang mengapung (floater) karena menandakan biji kopong atau diserang hama PBKo.
• Pemangkasan (Pruning): Lakukan pemangkasan cabang air dan cabang tua setelah panen besar selesai guna memicu pertumbuhan cabang produktif baru.
• Naungan (Shade Trees): Pertahankan pohon pelindung (seperti lamtoro atau sengon) dengan rasio tutupan 30-40% untuk menjaga mikroklimat tanah.''';
    }

    // 4. Fermentasi & Pascapanen
    if (q.contains('ferment') || q.contains('proses') || q.contains('washed') || q.contains('natural') || q.contains('honey') || q.contains('anaerob')) {
      return '''⚗️ Manajemen Fermentasi Pascapanen:
• Full Washed: Kupas kulit (depulping), fermentasi basah 24-36 jam hingga lendir (mucilage) terurai sempurna. Bilas dengan air bersih mengalir.
• Honey Process: Kupas kulit, jemur langsung bersama getah lendirnya. Menghasilkan rasa manis karamel dan body yang tebal.
• Natural Process: Jemur buah utuh langsung di atas raised bed. Butuh pembalikan 2-3 jam sekali untuk mencegah pembusukan jamur.
• Anaerobic Fermentation: Masukkan ceri ke dalam tangki kedap udara dengan one-way airlock valve selama 48-96 jam. Jaga suhu fermentasi di bawah 22°C dan pantau pH hingga mencapai 4.0 - 4.2.''';
    }

    // 5. Penjemuran & Moisture / Kadar Air
    if (q.contains('jemur') || q.contains('dry') || q.contains('kadar air') || q.contains('moisture') || q.contains('pengeringan')) {
      return '''☀️ Standar Penjemuran & Pengendalian Kadar Air:
• Target Kadar Air Aman: 10.5% – 11.5% untuk kestabilan penyimpanan jangka panjang (mencegah jamur Aspergillus ochraceus penghasil Ochratoxin A).
• Fasilitas Penjemuran: Gunakan meja penjemuran jaring (raised African beds), jangan menjemur langsung di atas tanah atau aspal.
• Ketebalan Lapisan: Tebar biji setebal 3–4 cm pada 3 hari pertama, kemudian ratakan hingga 2–3 cm pada tahap akhir.
• Perlindungan Cuaca: Tutup atau masukkan biji jika mendung/hujan, dan tutupi terpal di malam hari agar kelembaban embun tidak terserap kembali.''';
    }

    // 6. Cacat Biji & Defect
    if (q.contains('defect') || q.contains('cacat') || q.contains('hama') || q.contains('pbko') || q.contains('jamur')) {
      return '''🔍 Deteksi & Pencegahan Cacat Biji Kopi (Defect):
• Cacat Primer (Fatal):
  - Black Bean: Akibat buah terlalu matang di pohon atau fermentasi berlebih. Menimbulkan rasa pahit abu/gosong.
  - Sour Bean: Terjadi fermentasi asam/pembusukan lendir yang lambat. Menimbulkan rasa cuka tajam.
  - Moldy / Jamur: Pengeringan lambat atau disimpan lembab. Menghasilkan rasa apek dan bahaya mikotoksin.
• Cacat Sekunder:
  - Borer / Insect Damage: Disebabkan hama Penggerek Buah Kopi (PBKo). Dicegah dengan panen bersih (rampasan) dan perangkap atraktan brocap.
  - Broken / Biji Pecah: Kesalahan kalibrasi mesin huller atau pulper.''';
    }

    // 7. Cupping & Sensory Notes
    if (q.contains('cupping') || q.contains('rasa') || q.contains('skor') || q.contains('score') || q.contains('flavor') || q.contains('aroma')) {
      final variety = batch?.variety ?? 'Kopi Nusantara';
      final origin = batch?.origin ?? 'Indonesia';
      final score = batch?.cuppingScore?.toStringAsFixed(1) ?? '85.5';
      return '''☕ Analisis Sensory & Cupping ($variety - $origin):
• Estimasi Cupping Score: $score SCA (Kategori Specialty Grade).
• Karakteristik Rasa:
  - Fragrance / Aroma: Sweet floral, melati, aroma brown sugar dan jeruk segar.
  - Flavor: Ripe peach, blackcurrant, cokelat susu, dan sentuhan rempah manis.
  - Acidity: Malic-citric bright acidity yang bersih dan menyegarkan.
  - Body: Medium-full, bertekstur lembut (silky mouthfeel) dengan aftertaste bersih berkepanjangan.''';
    }

    // 8. Harga & Pasar
    if (q.contains('harga') || q.contains('pasar') || q.contains('lelang') || q.contains('market') || q.contains('london')) {
      return '''📈 Pasar Komoditas & Lelang Kopi:
• Bursa Acuan Global:
  - Arabika: Diperdagangkan di ICE Futures US (New York) dalam satuan US Cent/lb.
  - Robusta: Diperdagangkan di ICE Futures Europe (London) dalam satuan USD/Metric Ton.
• Jam Buka Bursa London: 09:00 UTC (16:00 WIB). Pantau ticker di menu Pasar Komoditas aplikasi ini.
• Specialty Premium: Kopi dengan sertifikat blockchain dan skor cupping >85 SCA biasanya mendapatkan premi harga 25% - 40% di atas harga bursa C-Market.''';
    }

    // 9. Jawaban Default
    return '''🤖 Asisten Agronomi & Roasting BeanOrigin (Mode Cerdas):
Pertanyaan Anda: "$question"

💡 Panduan Praktis Terkait Kopi:
1. Roasting: Biji kopi specialty paling optimal disangrai pada level Light to Medium untuk mempertahankan kompleksitas origin.
2. Pascapanen: Selalu jaga kadar air akhir antara 10.5% - 11.5% sebelum dimasukkan ke dalam karung GrainPro/Hermetik.
3. Kepatuhan Ekspor: Pastikan titik koordinat GPS kebun tercatat dan skor cupping minimal 80 SCA.

Tip: Anda dapat memasukkan Gemini API Key dari Google AI Studio melalui tombol di kanan atas untuk mengaktifkan kecerdasan buatan online!''';
  }
}
