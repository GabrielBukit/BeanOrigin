import 'package:flutter/material.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/llm_advisor/data/llm_service.dart';

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
  String? _customAnswer;
  bool _isAskingCustom = false;
  final _customPromptController = TextEditingController();
  final _llmService = LlmService();

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

    try {
      final batch = widget.batch;
      if (batch != null) {
        final result = await _llmService.generateAdvisory(batch);
        setState(() {
          _roastingAdvice = result['roasting'] ?? 'Tidak ada data';
          _cuppingNotes = result['cupping'] ?? 'Tidak ada data';
          _exportChecklist = result['export'] ?? 'Tidak ada data';
          _isLoading = false;
        });
      } else {
        setState(() {
          _roastingAdvice = 'Pilih batch terlebih dahulu untuk mendapatkan rekomendasi roasting.';
          _cuppingNotes = 'Pilih batch terlebih dahulu.';
          _exportChecklist = 'Pilih batch terlebih dahulu.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal menghasilkan advisory: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _askCustomQuestion() async {
    final question = _customPromptController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isAskingCustom = true;
      _customAnswer = null;
    });

    try {
      final answer = await _llmService.askQuestion(question, batch: widget.batch);
      setState(() {
        _customAnswer = answer;
        _isAskingCustom = false;
      });
    } catch (e) {
      setState(() {
        _customAnswer = 'Error: $e';
        _isAskingCustom = false;
      });
    }
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

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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

                  // Custom Answer
                  if (_customAnswer != null) ...[
                    _buildAdvisoryCard(
                      '💬 Jawaban Gemini',
                      _customAnswer!,
                      AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                  ],

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
            _llmService.isApiConfigured
                ? 'Mengirim data ke Gemini API...'
                : 'Menghasilkan rekomendasi (mode offline)',
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
                batch.cuppingScore!.toStringAsFixed(1),
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
            onPressed: _isAskingCustom ? null : _askCustomQuestion,
            icon: _isAskingCustom
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isAskingCustom ? 'Mengirim...' : 'Kirim'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfo() {
    final isConfigured = _llmService.isApiConfigured;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: isConfigured ? AppColors.success : AppColors.textHint,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConfigured
                  ? 'Terhubung ke Google Gemini 1.5 Flash API'
                  : 'Mode Offline — Atur API key di constants.dart untuk koneksi Gemini',
              style: TextStyle(
                fontSize: 11,
                color: isConfigured ? AppColors.success : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
