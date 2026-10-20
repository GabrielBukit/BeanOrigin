import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/shared/models/block_model.dart';

class BlockchainCertScreen extends StatefulWidget {
  final BatchModel batch;
  const BlockchainCertScreen({super.key, required this.batch});

  @override
  State<BlockchainCertScreen> createState() => _BlockchainCertScreenState();
}

class _BlockchainCertScreenState extends State<BlockchainCertScreen> {
  late BlockModel _block;
  bool _isVerified = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _generateBlock();
  }

  void _generateBlock() {
    final genesis = BlockModel.genesis();
    _block = BlockModel.create(
      index: 1,
      batchId: widget.batch.id,
      batchData: {
        'variety': widget.batch.variety,
        'origin': widget.batch.origin,
        'elevation_masl': widget.batch.elevationMasl,
        'process': widget.batch.process,
        'cupping_score': widget.batch.cuppingScore,
        'farmer': widget.batch.farmerName,
        'weight_kg': widget.batch.weightKg,
        'moisture_content': widget.batch.moistureContent,
      },
      previousHash: genesis.hash,
    );
  }

  Future<void> _verifyChain() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isVerified = _block.isValid();
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sertifikat Blockchain'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Certificate Header
            _buildCertificateHeader(),
            const SizedBox(height: 16),

            // QR Code
            _buildQrCode(),
            const SizedBox(height: 16),

            // Block Info
            _buildBlockInfo(),
            const SizedBox(height: 16),

            // Hash Chain
            _buildHashChain(),
            const SizedBox(height: 16),

            // Verify Button
            _buildVerifySection(),
            const SizedBox(height: 16),

            // Batch Data in Block
            _buildBatchData(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF4A3728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              const Text(
                'SERTIFIKAT KEASLIAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.batch.variety,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.batch.origin} · ${widget.batch.process}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.batch.id,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          QrImageView(
            data: _block.toQrData(),
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.roundedOuter,
              color: Color(0xFF2D1B0E),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.roundedOutsideCorners,
              color: Color(0xFF2D1B0E),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan untuk verifikasi keaslian',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A6554)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Block Index', '#${_block.index}'),
          const Divider(color: Color(0xFF3D2E22), height: 16),
          _buildInfoRow('Batch ID', _block.batchId),
          const Divider(color: Color(0xFF3D2E22), height: 16),
          _buildInfoRow('Timestamp', _block.timestamp.toIso8601String()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHashChain() {
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
              Icon(Icons.link_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'SHA-256 Hash Chain',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Previous Hash
          const Text('Previous Hash:', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _block.previousHash,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Current Hash
          const Text('Current Hash:', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              _block.hash,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.accent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifySection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isVerifying ? null : _verifyChain,
          icon: _isVerifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                )
              : const Icon(Icons.verified_user_rounded, size: 20),
          label: Text(_isVerifying ? 'Memverifikasi...' : 'Verifikasi Hash Chain'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        if (_isVerified) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Hash valid! Integritas data batch terjamin.',
                    style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBatchData() {
    final dataStr = const JsonEncoder.withIndent('  ').convert(_block.batchData);
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
              Icon(Icons.data_object_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Data Batch (dalam Blok)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dataStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
