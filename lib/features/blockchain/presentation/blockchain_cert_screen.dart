import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/shared/models/block_model.dart';
import 'package:bean_origin/features/blockchain/data/blockchain_service.dart';

class BlockchainCertScreen extends StatefulWidget {
  final BatchModel batch;
  const BlockchainCertScreen({super.key, required this.batch});

  @override
  State<BlockchainCertScreen> createState() => _BlockchainCertScreenState();
}

class _BlockchainCertScreenState extends State<BlockchainCertScreen>
    with SingleTickerProviderStateMixin {
  final BlockchainService _blockchain = BlockchainService();
  late BlockModel _block;
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _isLoading = true;
  ChainVerificationResult? _chainResult;
  late AnimationController _verifyAnimController;

  @override
  void initState() {
    super.initState();
    _verifyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initBlock();
  }

  @override
  void dispose() {
    _verifyAnimController.dispose();
    super.dispose();
  }

  Future<void> _initBlock() async {
    await _blockchain.initialize();

    // Check if this batch already has a block
    final existingBlocks = _blockchain.getBlocksForBatch(widget.batch.id);

    if (existingBlocks.isNotEmpty) {
      _block = existingBlocks.last;
    } else {
      // Create a new block for this batch (persisted in Hive)
      _block = await _blockchain.addBlock(widget.batch);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _verifyChain() async {
    setState(() => _isVerifying = true);
    _verifyAnimController.repeat();

    await Future.delayed(const Duration(milliseconds: 300));

    final blockValid = _blockchain.verifyBlock(_block);
    final chainResult = _blockchain.verifyChain();

    _verifyAnimController.stop();
    _verifyAnimController.reset();

    setState(() {
      _isVerified = blockValid && chainResult.isValid;
      _chainResult = chainResult;
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sertifikat Blockchain')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text('Memuat blockchain...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sertifikat Blockchain'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            onPressed: _showChainStats,
          ),
        ],
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

            // Chain Statistics
            _buildChainStats(),
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
              eyeShape: QrEyeShape.square,
              color: Color(0xFF2D1B0E),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
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

          // Arrow
          const Center(
            child: Icon(Icons.arrow_downward_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(height: 6),

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
              ? RotationTransition(
                  turns: _verifyAnimController,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: Icon(Icons.sync_rounded, size: 18),
                  ),
                )
              : const Icon(Icons.verified_user_rounded, size: 20),
          label: Text(_isVerifying ? 'Memverifikasi...' : 'Verifikasi Hash Chain'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        if (_isVerified && _chainResult != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _chainResult!.isValid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _chainResult!.isValid
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _chainResult!.isValid ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: _chainResult!.isValid ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _chainResult!.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: _chainResult!.isValid ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_chainResult!.isValid) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Integritas data batch terjamin. Tidak ada modifikasi terdeteksi.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (!_isVerified && _chainResult != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chainResult!.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChainStats() {
    final stats = _blockchain.getStatistics();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Statistik Blockchain',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('Total Blok', '${stats['total_blocks']}'),
              const SizedBox(width: 8),
              _buildStatChip('Batch', '${stats['unique_batches']}'),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Genesis', '${stats['genesis_hash']}...'),
          const SizedBox(height: 4),
          _buildInfoRow('Latest', '${stats['latest_hash']}...'),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3D2E22)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
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

  void _showChainStats() {
    final stats = _blockchain.getStatistics();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text('Blockchain Info', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('Total Blok', '${stats['total_blocks']}'),
            _statRow('Chain Length', '${stats['chain_length']}'),
            _statRow('Unique Batches', '${stats['unique_batches']}'),
            _statRow('Genesis Hash', '${stats['genesis_hash']}...'),
            _statRow('Latest Hash', '${stats['latest_hash']}...'),
            _statRow('Updated', '${stats['latest_timestamp']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
