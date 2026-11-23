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
      final prompt = '''Kamu adalah "BeanOrigin AI Coffee Specialist" — asisten kecerdasan buatan terkemuka yang ahli dan berdedikasi khusus dalam segala aspek dunia KOPI (agronomi budidaya kebun kopi, varietas kopi nusantara & dunia, pascapanen, fermentasi, roasting profile, teknik seduh / barista brewing, cupping & sensory Q-Grader, rantai pasok, pasar komoditas lelang, serta regulasi & ekspor kopi internasional seperti EUDR).

ATURAN WAJIB & PALING UTAMA:
1. Jawab pertanyaan pengguna dengan akurat, mendalam, praktis, dan ramah sesuai topik spesifik yang ditanyakan.
2. FOKUS EKSKLUSIF KOPI: Jika pertanyaan pengguna TIDAK BERHUBUNGAN SAMA SEKALI dengan kopi (misal: politik, matematika murni, koding umum, resep masakan non-kopi, gosip selebriti, otomotif, dsb), kamu HARUS menolak dengan sopan dan ramah. Berikan alasan tegas bahwa kamu adalah asisten kecerdasan buatan khusus BeanOrigin yang fokus hanya pada ekosistem dan industri kopi. Lalu undang pengguna untuk mengajukan pertanyaan seputar kopi.
3. Gunakan Bahasa Indonesia yang lugas, profesional, dan gunakan formatting Markdown (tebal, bullet points, emoji) yang rapi.

${batch != null ? '''KONTEKS BATCH KOPI AKTIF:
- Varietas: ${batch.variety}
- Asal Kebun: ${batch.origin}
- Ketinggian: ${batch.elevationMasl.toInt()} mdpl
- Proses: ${batch.process}
- Cupping Score: ${batch.cuppingScore != null ? '${batch.cuppingScore!.toStringAsFixed(1)} SCA' : 'Belum dinilai'}
- Kadar Air: ${batch.moistureContent != null ? '${batch.moistureContent!.toStringAsFixed(1)}%' : 'Belum diukur'}
- Status: ${batch.status}
''' : ''}
PERTANYAAN PENGGUNA:
"$question"''';

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
    final q = question.toLowerCase().trim();

    // 1. Sapaan Umum
    final greetings = ['halo', 'hai', 'hi', 'hello', 'assalam', 'pagi', 'siang', 'sore', 'malam', 'siapa kamu', 'siapa anda'];
    if (greetings.any((g) => q.startsWith(g) || q == g)) {
      return '''☕ Halo! Saya adalah Asisten AI Khusus Kopi dari BeanOrigin.

Saya siap membantu menjawab segala hal seputar dunia kopi:
🌱 Agronomi & Budidaya: Petik merah, bibit, pohon naungan, pupuk, & hama PBKo
⚗️ Pascapanen & Fermentasi: Full Washed, Natural, Honey, Anaerobic, & Giling Basah
☀️ Penjemuran & Sensor: Kontrol kadar air (moisture 10-12%) & pencegahan jamur
🔥 Roasting Profile: Panduan Light, Medium, Dark Roast, First & Second Crack
☕ Cupping & Seduh: Protokol SCA, Sensory notes, Rasio seduh V60 & Espresso
📋 Pasar & Ekspor: Jam lelang bursa London/NY & regulasi anti-deforestasi EUDR

Silakan ajukan pertanyaan seputar kopi, saya siap membantu! ☕''';
    }

    // 2. Daftar Kata Kunci Dunia Kopi
    final coffeeKeywords = [
      'kopi', 'coffee', 'ceri', 'cherry', 'bean', 'biji', 'roast', 'sangrai',
      'cupping', 'brew', 'seduh', 'barista', 'v60', 'espresso', 'aeropress',
      'french press', 'tubruk', 'cappuccino', 'latte', 'cold brew', 'giling',
      'grind', 'grinder', 'arabika', 'arabica', 'robusta', 'liberika', 'excelsa',
      'gayo', 'toraja', 'mandailing', 'kintamani', 'wamena', 'bajawa', 'sidikalang',
      'temanggung', 'lampung', 'dampit', 'preanger', 'panen', 'petik', 'kebun',
      'tanam', 'bibit', 'pascapanen', 'ferment', 'washed', 'natural', 'honey',
      'giling basah', 'anaerob', 'aerob', 'maceration', 'jemur', 'drying',
      'kadar air', 'moisture', 'defect', 'cacat', 'pbko', 'karat daun', 'jamur',
      'huller', 'pulper', 'ekspor', 'export', 'eudr', 'ico', 'ska', 'sni', 'sca',
      'scaa', 'q-grader', 'acidity', 'body', 'aftertaste', 'flavor', 'aroma',
      'fragrance', 'bursa', 'lelang', 'london', 'new york', 'ice', 'pasar',
      'harga', 'kafein', 'caffeine', 'crema', 'rasio', 'suhu air', 'kalita',
      'chemex', 'moka pot', 'syphon', 'sweetness', 'pahit', 'asam', 'sepet',
      'astringent', 'over-extraction', 'under-extraction', 'blooming', 'densitas'
    ];

    final isCoffeeRelated = coffeeKeywords.any((kw) => q.contains(kw));

    // 3. TOLAK JIKA BUKAN TENTANG KOPI (Permintaan Pengguna: Fokus Eksklusif Kopi)
    if (!isCoffeeRelated) {
      return '''Mohon maaf, saya adalah Asisten AI BeanOrigin yang berdedikasi dan fokus KHUSUS pada dunia KOPI ☕.

Saya tidak dapat menjawab pertanyaan di luar topik kopi karena keahlian saya dirancang khusus untuk agronomi kebun kopi, pascapanen, teknik roasting, uji cita rasa (cupping), metode seduh barista, serta perdagangan dan regulasi ekspor kopi.

💡 Anda dapat menanyakan topik kopi seperti:
• "Bagaimana rasio, suhu, dan teknik seduh V60 yang benar?"
• "Apa perbedaan karakteristik rasa Arabika Gayo dan Toraja?"
• "Bagaimana cara melakukan fermentasi kopi anaerobik?"
• "Kapan waktu yang tepat menurunkan biji saat first crack?"
• "Apa saja syarat ekspor kopi ke Eropa sesuai regulasi EUDR?"

Ada yang bisa saya bantu terkait budidaya, seduh, atau bisnis kopi Anda? ☕''';
    }

    // 4. JAWABAN MENDALAM SEPUTAR KOPI SESUAI TOPIK PERTANYAAN:

    // A. Teknik Seduh & Brewing Barista (V60, Espresso, French Press, Rasio, Grind Size)
    if (q.contains('seduh') || q.contains('brew') || q.contains('v60') || q.contains('espresso') ||
        q.contains('tubruk') || q.contains('aeropress') || q.contains('barista') ||
        q.contains('rasio') || q.contains('giling') || q.contains('grind')) {
      return '''☕ Panduan Teknik Seduh & Brewing Kopi:
1. Manual Brew V60 (Filter Coffee):
   • Rasio: 1:15 hingga 1:16 (Contoh: 15 gram kopi untuk 225 - 240 ml air).
   • Suhu Air: 90°C – 93°C (Gunakan 92°C untuk biji Light-Medium roast).
   • Gilingan (Grind Size): Medium-Fine (seperti garam meja kasar).
   • Teknik Tuang:
     - Tuangan 1 (Blooming): 40-50 ml air, tunggu 30-45 detik agar gas CO2 terlepas.
     - Tuangan 2 & 3: Tuang perlahan secara melingkar dari tengah ke luar, hindari menuang langsung ke kertas filter.
     - Total Waktu Ekstraksi: 2 menit 30 detik – 3 menit.

2. Espresso Extraction:
   • Dose: 18 – 20 gram bubuk halus (fine grind).
   • Yield: 36 – 40 gram cairan espresso (rasio 1:2).
   • Waktu Ekstraksi: 25 – 30 detik pada tekanan 9 bar dan suhu 92°C – 94°C.
   • Ciri Ideal: Crema berwarna hazelnut kemerahan tebal dengan rasa seimbang antara body, acidity, dan sweetness.

3. Kopi Tubruk Tradisional:
   • Rasio 1:12 atau 1:14, air mendidih 95°C, aduk perlahan di menit ke-2, biarkan bubuk mengendap sempurna pada menit ke-4 sebelum diminum.''';
    }

    // B. Roasting / Sangrai (Light, Medium, Dark, First Crack)
    if (q.contains('roast') || q.contains('sangrai') || q.contains('crack') || q.contains('ror')) {
      final variety = batch?.variety ?? 'Arabika Specialty';
      final elevation = batch?.elevationMasl.toInt() ?? 1400;
      return '''🔥 Panduan Roasting Kopi ($variety - $elevation mdpl):
• Karakter Biji: Kopi dataran tinggi memiliki densitas sel biji yang padat, membutuhkan transfer panas yang terukur agar matang hingga inti.
• Profil Pilihan:
  1. Light Roast (Cinnamon / New England):
     - Suhu Drop: 202°C – 206°C (segera setelah First Crack reda).
     - Karakter: Sangat kaya aroma floral, keasaman buah (fruity acidity), rasa manis alami, dan tea-like body. Paling ideal untuk V60 Specialty.
  2. Medium Roast (City / Full City):
     - Suhu Drop: 210°C – 216°C.
     - Karakter: Keseimbangan sempurna antara body, aroma karamel cokelat, dan acidity lembut. Sangat versatile untuk filter maupun espresso.
  3. Dark Roast (French / Italian):
     - Suhu Drop: 222°C – 226°C (memasuki awal Second Crack).
     - Karakter: Acidity hilang, body tebal pekat, aroma smokey dan dark cocoa. Cocok untuk kopi susu kental manis atau blend komersial.
• Tips Penting: Jangan biarkan laju kenaikan suhu (Rate of Rise / RoR) mengalami *crash* atau *flick* menjelang first crack agar tidak terjadi rasa baked (roti panggang hambar).''';
    }

    // C. Varietas & Perbedaan Karakter (Gayo, Toraja, Kintamani, Arabika vs Robusta vs Liberika)
    if (q.contains('varietas') || q.contains('jenis') || q.contains('arabika') || q.contains('robusta') ||
        q.contains('liberika') || q.contains('excelsa') || q.contains('gayo') || q.contains('toraja') ||
        q.contains('kintamani') || q.contains('mandailing') || q.contains('wamena') || q.contains('kafein')) {
      return '''🌍 Varietas & Karakteristik Kopi Nusantara:
1. Perbandingan Utama Jenis Kopi:
   • Arabika: Tumbuh di >1000 mdpl, kadar kafein 1.1%–1.5%, bentuk biji lonjong dengan celah bergelombang, rasa kompleks dengan aroma floral, buah, dan acidity cerah.
   • Robusta: Tumbuh di dataran rendah 200–800 mdpl, kadar kafein tinggi 2.2%–2.7%, bentuk bulat dengan celah lurus, body sangat tebal, aroma nutty, cokelat pahit, tahan hama.
   • Liberika & Excelsa: Biji asimetris besar berujung kait, aroma nangka (jackfruit), buah tropis matang, dan sentuhan aroma kayu manis.

2. Cita Rasa Khas Origin Indonesia:
   • Arabika Gayo (Aceh): Spicy herbal yang khas, body sedang-tebal, clean acidity, dan aftertaste manis cokelat.
   • Arabika Toraja (Sulawesi): Earthy, dark chocolate, sentuhan kayu manis, dan keasaman seimbang yang elegan.
   • Arabika Kintamani (Bali): Dominan rasa buah jeruk segar (citrusy orange), bodi ringan-sedang, dan aroma bunga melati.
   • Arabika Wamena (Papua): Sangat lembut, wangi floral, rasa nutty almond, dan manis karamel bersih tanpa jejak rasa tanah.''';
    }

    // D. Pascapanen & Fermentasi (Full Washed, Natural, Honey, Anaerobik, Giling Basah)
    if (q.contains('ferment') || q.contains('proses') || q.contains('washed') || q.contains('natural') ||
        q.contains('honey') || q.contains('anaerob') || q.contains('giling basah') || q.contains('maceration')) {
      return '''⚗️ Metode Pengolahan Pascapanen & Fermentasi Kopi:
1. Full Washed (Proses Basah):
   • Buah ceri dikupas kulitnya (depulping), difermentasi dalam bak air selama 24–36 jam untuk menguraikan lendir (mucilage).
   • Hasil Cup: Karakter bersih (clean cup), acidity jernih berkilau, dan rasa floral yang murni.
2. Natural / Dry Process:
   • Buah ceri utuh dijemur langsung di bawah matahari selama 18–25 hari.
   • Hasil Cup: Rasa manis buah matang sangat pekat (berry, anggur, ferment-winey) dengan body yang tebal.
3. Honey / Pulped Natural Process:
   • Kulit luar dikupas, biji dijemur bersama lapisan getah lendir manisnya (mucilage).
   • Variasi: Yellow Honey (sisa lendir 25%), Red Honey (50%), Black Honey (100% lendir dijemur teduh).
   • Hasil Cup: Keseimbangan rasa manis karamel dan keasaman buah yang lembut.
4. Anaerobic Fermentation (Modern Specialty):
   • Biji dimasukkan ke wadah drum kedap udara dengan katup one-way valve selama 48–96 jam pada suhu dingin <20°C.
   • Kontrol pH hingga 4.0–4.2. Menghasilkan rasa buah tropis eksotis (nanas, markisa) dan aroma kompleks spektakuler.
5. Giling Basah (Wet-Hulled):
   • Khas petani Sumatera: Biji dikupas kulit tanduknya saat kadar air masih tinggi (30–35%). Menghasilkan warna biji hijau kebiruan dan body yang sangat tebal serta aroma rempah/earthy.''';
    }

    // E. Panen, Budidaya Kebun & Hama (Petik Merah, Pupuk, Naungan, PBKo)
    if (q.contains('panen') || q.contains('petik') || q.contains('kebun') || q.contains('tanam') ||
        q.contains('rawat') || q.contains('pupuk') || q.contains('hama') || q.contains('pbko') ||
        q.contains('karat daun')) {
      return '''🌱 Panduan Budidaya, Panen & Penanganan Hama Kebun:
1. Standar Petik Merah Juara:
   • Hanya panen buah ceri merah marun dengan tingkat kematangan 95%–100% (kadar gula/Brix mencapai 18°–22°).
   • Sortasi Apung (Floating): Masukkan ceri ke bak air; buah yang mengapung (floater) wajib dipisahkan karena indikasi kopong atau terserang hama.
2. Pengendalian Hama & Penyakit Utama:
   • Penggerek Buah Kopi (PBKo / Hypothenemus hampei):
     - Pasang perangkap senyawa atraktan (Brocap trap) 20–25 unit per hektar.
     - Lakukan panen bersih (rampasan) memetik seluruh buah tersisa di akhir musim untuk memutus siklus hidup hama.
   • Karat Daun (Hemileia vastatrix):
     - Atur naungan pohon (rasio 30%–40%) agar sirkulasi udara baik dan kelembaban tidak memicu spora jamur.
     - Gunakan varietas tahan karat seperti Sigarar Utang, Andungsari, atau Komasti.
3. Pemangkasan (Pruning):
   • Pangkas cabang air (wiwilan) dan cabang yang sudah berbuah lebih dari 3 kali setelah panen raya selesai untuk menumbuhkan tunas produktif baru.''';
    }

    // F. Penjemuran & Kadar Air (Moisture Content)
    if (q.contains('jemur') || q.contains('dry') || q.contains('kadar air') || q.contains('moisture') ||
        q.contains('pengeringan')) {
      return '''☀️ Standar Penjemuran & Pengendalian Kadar Air (Moisture):
• Target Kadar Air Resmi: 10.0% – 12.0% (Standar Internasional SCA & SNI Maksimal 12.5%).
  - Jika kadar air >12.5%: Biji sangat rentan ditumbuhi jamur mikotoksin (Ochratoxin A) yang membuat kopi ditolak di pelabuhan ekspor.
  - Jika kadar air <9.5%: Biji menjadi getas, mudah pecah saat proses hulling, dan kehilangan komponen minyak volatil rasa.
• Prosedur Penjemuran Ideal:
  1. Gunakan meja jemur jaring bertingkat (Raised African Beds) untuk sirkulasi udara 360 derajat.
  2. Bolak-balik biji kopi setiap 2 jam sekali pada siang hari.
  3. Tutup terpal atau bawa masuk biji jika cuaca mendung/hujan, dan tutup rapat saat malam hari agar tidak menyerap embun.''';
    }

    // G. Cacat Biji Kopi (Defect) & Standar Mutu
    if (q.contains('defect') || q.contains('cacat')) {
      return '''🔍 Klasifikasi Cacat Biji Kopi (Defect Standard SCA & SNI):
1. Cacat Primer (Category 1 - Fatal / Nol Toleransi untuk Specialty):
   • Black Bean (Biji Hitam): Akibat fermentasi berlebih atau buah mati di pohon. Menghasilkan rasa pahit arang/gosong menusuk.
   • Sour Bean (Biji Asam): Terjadi fermentasi cuka berlebih atau pengeringan terlalu lambat. Menimbulkan rasa cuka tajam yang merusak rasa.
   • Moldy (Biji Berjamur): Terserang jamur akibat disimpan dalam kondisi basah/lembab. Menghasilkan rasa apek tanah dan bahaya mikotoksin.
2. Cacat Sekunder (Category 2):
   • Borer / Insect Damage: Lubang akibat kumbang PBKo. Menyebabkan rasa tidak sedap dan tidak seragam.
   • Broken / Biji Pecah: Kerusakan mekanis pada mesin pulper/huller. Biji mudah hangus saat disangrai.
   • Floater / Biji Keriput: Biji kopong akibat kekurangan nutrisi pada pohon.''';
    }

    // H. Cupping & Sensory Notes (SCA Protocol)
    if (q.contains('cupping') || q.contains('rasa') || q.contains('skor') || q.contains('score') ||
        q.contains('flavor') || q.contains('aroma') || q.contains('acidity') || q.contains('body')) {
      final variety = batch?.variety ?? 'Kopi Nusantara';
      final origin = batch?.origin ?? 'Indonesia';
      final score = batch?.cuppingScore?.toStringAsFixed(1) ?? '85.5';
      return '''☕ Uji Cita Rasa & Cupping Protocol ($variety - $origin):
• Skor Evaluasi: $score SCA (Kategori Specialty Grade).
• 10 Atribut Penilaian SCA Cupping:
  1. Fragrance / Aroma: Bau kering bubuk dan aroma saat dituang air panas 93°C.
  2. Flavor: Kesan rasa utama saat diseruput di lidah (notes buah, bunga, rempah, kacang).
  3. Aftertaste: Jejak rasa yang tertinggal di langit-langit mulut setelah kopi ditelan.
  4. Acidity: Tingkat keasaman cerah yang menyegarkan (seperti apel, lemon, atau jeruk).
  5. Body: Sensasi ketebalan cairan di mulut (mouthfeel: tea-like, creamy, silky, atau heavy).
  6. Balance: Harmoni perpaduan antara sweetness, acidity, dan aroma tanpa ada nada dominan yang menusuk.
  7. Uniformity: Konsistensi rasa di seluruh 5 cangkir sampel yang diuji.
  8. Clean Cup: Bebas dari cacat rasa tidak sedap (tanah, apek, kimia).
  9. Sweetness: Manis alami karamel yang terasa jelas pada suhu suam-suam kuku.
  10. Overall: Penilaian kepuasan holistik dari sang Q-Grader.''';
    }

    // I. Ekspor, Regulasi EUDR & Pasar Global
    if (q.contains('ekspor') || q.contains('export') || q.contains('eudr') || q.contains('syarat') ||
        q.contains('pasar') || q.contains('lelang') || q.contains('harga') || q.contains('london') ||
        q.contains('new york')) {
      return '''📋 Regulasi Ekspor Kopi & Pasar Bursa Global:
1. Regulasi Anti-Deforestasi Uni Eropa (EUDR):
   • Titik Poligon GPS: Setiap petak kebun petani pemasok wajib memiliki rekaman koordinat poligon pemetaan satelit.
   • Bebas Deforestasi: Lahan tidak boleh berasal dari pembabatan hutan primer sejak batas akhir 31 Desember 2020.
   • Due Diligence Statement (DDS): Wajib didaftarkan secara transparan ke sistem TRACES Uni Eropa.
2. Dokumen Ekspor Wajib:
   • Surat Keterangan Asal (SKA / ICO Certificate of Origin) dari Kemendag.
   • Phytosanitary Certificate dari Badan Karantina Indonesia.
   • Bill of Lading (B/L), Packing List, Invoice, & Fumigation Certificate.
3. Acuan Harga Komoditas Dunia:
   • Arabika: Diperdagangkan di bursa ICE New York (dalam satuan Cent USD / pon).
   • Robusta: Diperdagangkan di bursa ICE London (dalam satuan USD / Metric Ton).
   • Jam Lelang London buka pukul 16:00 WIB (09:00 UTC). Pantau live clock di menu Pasar Komoditas aplikasi ini!''';
    }

    // J. Pertanyaan Kopi Spesifik Lainnya
    final currentVariety = batch?.variety ?? 'Kopi Nusantara';
    final currentOrigin = batch?.origin ?? 'Indonesia';
    return '''☕ Analisis Pakar Kopi BeanOrigin:
Pertanyaan Anda: "$question"

💡 Panduan Khusus untuk Biji Kopi $currentVariety ($currentOrigin):
1. Pengolahan: Jaga kebersihan saat proses pascapanen, pastikan air pencucian bersih dan pH fermentasi terkontrol di kisaran 4.0 - 4.5.
2. Penyimpanan: Simpan green beans di dalam kantong berteknologi kedap udara (seperti GrainPro) dengan suhu ruang 20°C - 24°C untuk menjaga kesegaran rasa hingga 12 bulan.
3. Kalibrasi Rasa: Lakukan cupping berkala pada setiap lot panen untuk mengidentifikasi potensi profil rasa terbaik sebelum dipasarkan.

Ada detail lain seputar budidaya, sangrai, seduh, atau bisnis kopi yang ingin Anda ketahui? ☕''';
  }
}
