import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';
import 'package:bean_origin/features/ai_scanner/data/coffee_vision_service.dart';

class AiScannerScreen extends StatefulWidget {
  final BatchModel? targetBatch;
  const AiScannerScreen({super.key, this.targetBatch});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> with SingleTickerProviderStateMixin {
  File? _imageFile;
  bool _isAnalyzing = false;
  Map<String, double>? _results;
  CoffeeScanResult? _scanResult;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  BatchModel? _currentBatch;

  final _picker = ImagePicker();

  static const Map<String, IconData> _defectIcons = {
    'Normal Bean': Icons.check_circle_rounded,
    'Black Bean': Icons.circle,
    'Sour / Moldy': Icons.warning_rounded,
    'Broken / Chipped': Icons.broken_image_rounded,
    'Insect Damage': Icons.bug_report_rounded,
    'Unripe / Quaker': Icons.eco_outlined,
  };

  static const Map<String, Color> _defectColors = {
    'Normal Bean': Color(0xFF4CAF50),
    'Black Bean': Color(0xFF424242),
    'Sour / Moldy': Color(0xFFFF9800),
    'Broken / Chipped': Color(0xFFE53935),
    'Insect Damage': Color(0xFF9C27B0),
    'Unripe / Quaker': Color(0xFF8BC34A),
  };

  @override
  void initState() {
    super.initState();
    _currentBatch = widget.targetBatch;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _results = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    final file = _imageFile;
    if (file == null) return;

    setState(() {
      _isAnalyzing = true;
      _results = null;
      _scanResult = null;
    });
    _pulseController.repeat(reverse: true);

    // Jalankan Computer Vision Inspection (Memvalidasi foto kopi & menganalisis defect)
    final result = await CoffeeVisionService().inspectImage(file);

    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _scanResult = result;
      _results = result.isCoffee ? result.defectProportions : null;
      _isAnalyzing = false;
    });
  }

  void _applyResultsToBatch() {
    final results = _results;
    if (results == null || (_scanResult != null && !_scanResult!.isCoffee)) return;

    final summary = results.entries.map((e) => '${e.key}: ${e.value}%').join(', ');
    final normalPercent = results['Normal Bean'] ?? 75.0;
    final estimatedScore = double.parse((70.0 + (normalPercent / 100.0) * 20.0).toStringAsFixed(1));

    final batch = _currentBatch;
    if (batch != null) {
      final updated = batch.copyWith(
        defectResult: summary,
        cuppingScore: batch.cuppingScore ?? estimatedScore,
      );
      context.read<BatchBloc>().add(BatchUpdate(updated));
      setState(() => _currentBatch = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Hasil scan AI disimpan ke batch ${updated.id}!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Pick batch from list
      final allBatches = BatchRepository().getAllBatches();
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bgCard,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Batch untuk Menyimpan Hasil AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allBatches.length,
                  itemBuilder: (ctx, index) {
                    final b = allBatches[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.bgSurface,
                        child: Text('☕'),
                      ),
                      title: Text(b.variety, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('${b.id} · ${b.origin}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accent),
                      onTap: () {
                        final updated = b.copyWith(
                          defectResult: summary,
                          cuppingScore: b.cuppingScore ?? estimatedScore,
                        );
                        context.read<BatchBloc>().add(BatchUpdate(updated));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Hasil scan AI disimpan ke batch ${b.id}!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Defect Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Batch context header if provided
            if (_currentBatch != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Target Batch: ${_currentBatch?.id ?? '-'} (${_currentBatch?.variety ?? '-'})',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Image Preview / Capture Area
            _buildImageArea(),
            const SizedBox(height: 16),

            // Camera / Gallery Buttons
            _buildCaptureButtons(),
            const SizedBox(height: 20),

            // Results: Non-Coffee Warning vs Coffee Inspection Results
            if (_scanResult != null) ...[
              if (!_scanResult!.isCoffee)
                _buildNonCoffeeView(_scanResult!)
              else
                _buildCoffeeResults(_scanResult!),
            ],

            // Model Info
            const SizedBox(height: 20),
            _buildModelInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAnalyzing
                    ? AppColors.accent
                    : _scanResult != null
                        ? (_scanResult!.isCoffee ? AppColors.success : AppColors.error)
                        : const Color(0xFF3D2E22),
                width: _isAnalyzing || _scanResult != null ? 2 : 1,
              ),
              boxShadow: _isAnalyzing
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 20,
                      )
                    ]
                  : null,
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_imageFile as File, fit: BoxFit.cover),
                        if (_isAnalyzing)
                          Container(
                            color: AppColors.bgDark.withValues(alpha: 0.65),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memverifikasi & Menganalisis Biji Kopi...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'AI Vision Defect Classifier',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3D2E22)),
                          ),
                          child: const Icon(Icons.coffee_rounded, size: 32, color: AppColors.accent),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambil Foto Sampel Biji Kopi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gunakan kamera atau pilih dari galeri HP',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCaptureButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Buka Kamera'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            label: const Text('Pilih Galeri'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonCoffeeView(CoffeeScanResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.no_photography_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bukan Biji Kopi!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'Terdeteksi: ${result.objectType} (Keyakinan ${result.confidence}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.message,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Petunjuk Pengambilan Foto Biji Kopi:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '1. Letakkan sampel biji kopi (green beans / roasted) di atas nampan atau kertas putih bersih.\n'
                  '2. Posisikan kamera tegak lurus dari atas dengan jarak 15–20 cm.\n'
                  '3. Pastikan pencahayaan terang dan biji tidak tertutup bayangan tebal.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Ambil Ulang Foto Kopi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bgDark,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeResults(CoffeeScanResult result) {
    final normalPercent = result.normalPercent;
    final qualityColor = normalPercent >= 80
        ? AppColors.success
        : normalPercent >= 68
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Coffee Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terverifikasi: ${result.objectType} (Akurasi ${result.confidence}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.isOnlineAnalysis ? 'Gemini Vision' : 'AI Offline Vision',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Overall Quality Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: qualityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: qualityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics_rounded, color: qualityColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.grade,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: qualityColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biji Normal: ${normalPercent.toStringAsFixed(1)}% | Total Cacat: ${result.totalDefectPercent.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: qualityColor.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rekomendasi Kurasi Fisik
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3D2E22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: AppColors.accent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Rekomendasi Sortasi Fisik:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                result.recommendation,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action: Apply to Batch Button
        ElevatedButton.icon(
          onPressed: _applyResultsToBatch,
          icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
          label: Text(_currentBatch != null ? 'Terapkan ke Batch ${_currentBatch?.id ?? ''}' : 'Simpan ke Form Inspeksi Batch'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 20),

        // Detailed Results
        const Text(
          'Proporsi Defect Biji Kopi (Standar SCA / SCAA)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        ...result.defectProportions.entries.map((entry) {
          final icon = _defectIcons[entry.key] ?? Icons.help_outline;
          final color = _defectColors[entry.key] ?? AppColors.textHint;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (entry.value / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF3D2E22),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModelInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text(
                'Arsitektur Model AI Vision & Verifikasi Kopi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Verifikasi Objek: Validasi otomatis spektrum warna & tekstur biji kopi asli\n'
            '• Dual Engine: Gemini 1.5 Flash Multimodal Vision (Online) & Color/Texture Heuristic Classifier (Offline)\n'
            '• Filter Non-Kopi: Menolak otomatis foto manusia, hewan, barang, atau dokumen non-kopi\n'
            '• Klasifikasi Cacat: 6 Kategori Defect Standar SCA (Normal, Black, Sour, Broken, PBKo, Quaker)\n'
            '• Integrasi: Output mutu fisik & defect % langsung tersimpan pada rekam jejak batch',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
