import 'package:flutter/material.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';

class LlmAdvisorScreen extends StatefulWidget {
  final BatchModel? batch;
  const LlmAdvisorScreen({super.key, this.batch});

  @override
  State<LlmAdvisorScreen> createState() => _LlmAdvisorScreenState();
}

class _LlmAdvisorScreenState extends State<LlmAdvisorScreen> {
  bool _isLoading = false;
  String? _roastingAdvice;
  String? _cuppingNotes;
  String? _exportChecklist;
  String? _error;
  final _customPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.batch != null) {
      _generateAdvisory();
    }
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _generateAdvisory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Simulate Gemini API call
    await Future.delayed(const Duration(seconds: 2));

    final batch = widget.batch;

    setState(() {
      _isLoading = false;

      if (batch != null) {
        _roastingAdvice = _generateRoastingProfile(batch);
        _cuppingNotes = _generateCuppingNotes(batch);
        _exportChecklist = _generateExportChecklist(batch);
      } else {
        _roastingAdvice = 'Pilih batch terlebih dahulu untuk mendapatkan rekomendasi roasting.';
        _cuppingNotes = 'Pilih batch terlebih dahulu.';
        _exportChecklist = 'Pilih batch terlebih dahulu.';
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Advisory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _generateAdvisory,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch Info Header
                  if (widget.batch != null) _buildBatchHeader(),
                  const SizedBox(height: 16),

                  // Roasting Profile
                  if (_roastingAdvice != null) _buildAdvisoryCard(
                    '🔥 Rekomendasi Roasting',
                    _roastingAdvice!,
                    const Color(0xFFFF6D00),
                  ),
                  const SizedBox(height: 12),

                  // Cupping Notes
                  if (_cuppingNotes != null) _buildAdvisoryCard(
                    '☕ Cupping Notes',
                    _cuppingNotes!,
                    const Color(0xFF7B1FA2),
                  ),
                  const SizedBox(height: 12),

                  // Export Checklist
                  if (_exportChecklist != null) _buildAdvisoryCard(
                    '📋 Checklist Ekspor',
                    _exportChecklist!,
                    AppColors.info,
                  ),
                  const SizedBox(height: 20),

                  // Custom Prompt
                  _buildCustomPrompt(),
                  const SizedBox(height: 16),

                  // Model Info
                  _buildModelInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          const Text(
            'Gemini sedang menganalisis...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Menghasilkan rekomendasi roasting, cupping notes,\ndan checklist kepatuhan ekspor',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchHeader() {
    final batch = widget.batch!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5A4633), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('☕', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.variety,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${batch.origin} · ${batch.elevationMasl.toInt()} mdpl · ${batch.process}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (batch.cuppingScore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${batch.cuppingScore!.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.bgDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPrompt() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Tanya Gemini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _customPromptController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Tanyakan seputar kopi, roasting, atau ekspor...',
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement actual Gemini API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur Gemini API akan segera tersedia'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Kirim'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Powered by Google Gemini 1.5 Flash API',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
