import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/shared/models/block_model.dart';

/// Service to manage the local SHA-256 hash-chain (blockchain)
/// Blocks are stored in Hive for offline persistence and
/// synced to Supabase when online (TODO).
class BlockchainService {
  // Singleton
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  Box<Map>? _blockBox;
  final List<BlockModel> _chain = [];

  // ─── Initialization ──────────────────────────────────────

  /// Initialize the blockchain service, open Hive box, and load chain
  Future<void> initialize() async {
    if (_blockBox != null && _blockBox!.isOpen) return;

    _blockBox = await Hive.openBox<Map>(AppConstants.hiveBlockBox);
    await _loadChain();
  }

  /// Load existing chain from Hive or create genesis block
  Future<void> _loadChain() async {
    _chain.clear();

    if (_blockBox == null || _blockBox!.isEmpty) {
      // Create genesis block
      final genesis = BlockModel.genesis();
      await _saveBlock(genesis);
      _chain.add(genesis);
    } else {
      // Load all blocks from Hive in order
      final keys = _blockBox!.keys.toList()..sort();
      for (final key in keys) {
        final data = _blockBox!.get(key);
        if (data != null) {
          try {
            final block = BlockModel.fromJson(Map<String, dynamic>.from(data));
            _chain.add(block);
          } catch (_) {
            // Skip corrupt blocks
          }
        }
      }

      // Ensure genesis exists
      if (_chain.isEmpty) {
        final genesis = BlockModel.genesis();
        await _saveBlock(genesis);
        _chain.add(genesis);
      }
    }
  }

  // ─── Save Block to Hive ──────────────────────────────────

  Future<void> _saveBlock(BlockModel block) async {
    final key = 'block_${block.index.toString().padLeft(6, '0')}';
    await _blockBox?.put(key, block.toJson());
  }

  // ─── Add Block ───────────────────────────────────────────

  /// Create a new block from a batch and add it to the chain
  Future<BlockModel> addBlock(BatchModel batch) async {
    await initialize();

    final lastBlock = _chain.last;
    final newBlock = BlockModel.create(
      index: lastBlock.index + 1,
      batchId: batch.id,
      batchData: {
        'variety': batch.variety,
        'origin': batch.origin,
        'elevation_masl': batch.elevationMasl,
        'process': batch.process,
        'cupping_score': batch.cuppingScore,
        'farmer': batch.farmerName,
        'weight_kg': batch.weightKg,
        'moisture_content': batch.moistureContent,
        'status': batch.status,
      },
      previousHash: lastBlock.hash,
    );

    _chain.add(newBlock);
    await _saveBlock(newBlock);

    return newBlock;
  }

  /// Add a block with custom data (e.g., status change events)
  Future<BlockModel> addCustomBlock({
    required String batchId,
    required Map<String, dynamic> data,
  }) async {
    await initialize();

    final lastBlock = _chain.last;
    final newBlock = BlockModel.create(
      index: lastBlock.index + 1,
      batchId: batchId,
      batchData: data,
      previousHash: lastBlock.hash,
    );

    _chain.add(newBlock);
    await _saveBlock(newBlock);

    return newBlock;
  }

  // ─── Retrieve ────────────────────────────────────────────

  /// Get the complete blockchain
  List<BlockModel> getChain() => List.unmodifiable(_chain);

  /// Get the last block in the chain
  BlockModel? getLastBlock() => _chain.isNotEmpty ? _chain.last : null;

  /// Get block by index
  BlockModel? getBlockByIndex(int index) {
    try {
      return _chain.firstWhere((b) => b.index == index);
    } catch (_) {
      return null;
    }
  }

  /// Get all blocks for a specific batch
  List<BlockModel> getBlocksForBatch(String batchId) {
    return _chain.where((b) => b.batchId == batchId).toList();
  }

  /// Get chain length (excluding genesis)
  int get chainLength => _chain.length - 1;

  // ─── Verification ────────────────────────────────────────

  /// Verify a single block's hash integrity
  bool verifyBlock(BlockModel block) {
    return block.isValid();
  }

  /// Verify the entire chain integrity
  ChainVerificationResult verifyChain() {
    if (_chain.isEmpty) {
      return ChainVerificationResult(
        isValid: false,
        totalBlocks: 0,
        invalidBlocks: [],
        message: 'Chain kosong',
      );
    }

    final invalidBlocks = <int>[];

    // Verify genesis
    if (!_chain.first.isValid()) {
      invalidBlocks.add(0);
    }

    // Verify each subsequent block
    for (int i = 1; i < _chain.length; i++) {
      final current = _chain[i];
      final previous = _chain[i - 1];

      if (!current.isValid()) {
        invalidBlocks.add(i);
      } else if (!current.isLinkedTo(previous)) {
        invalidBlocks.add(i);
      }
    }

    final isValid = invalidBlocks.isEmpty;
    return ChainVerificationResult(
      isValid: isValid,
      totalBlocks: _chain.length,
      invalidBlocks: invalidBlocks,
      message: isValid
          ? '✅ Seluruh chain valid (${_chain.length} blok)'
          : '❌ Ditemukan ${invalidBlocks.length} blok tidak valid',
    );
  }

  /// Verify a batch's provenance by checking all its blocks
  BatchProvenanceResult verifyBatchProvenance(String batchId) {
    final blocks = getBlocksForBatch(batchId);
    if (blocks.isEmpty) {
      return BatchProvenanceResult(
        batchId: batchId,
        isVerified: false,
        blocks: [],
        message: 'Batch tidak ditemukan di blockchain',
      );
    }

    bool allValid = true;
    for (final block in blocks) {
      if (!block.isValid()) {
        allValid = false;
        break;
      }
    }

    return BatchProvenanceResult(
      batchId: batchId,
      isVerified: allValid,
      blocks: blocks,
      message: allValid
          ? '✅ Provenance terverifikasi (${blocks.length} transaksi)'
          : '❌ Integritas data batch terganggu',
    );
  }

  // ─── QR Code ─────────────────────────────────────────────

  /// Generate verification QR data for a batch
  String generateQrData(String batchId) {
    final blocks = getBlocksForBatch(batchId);
    if (blocks.isEmpty) return '{}';

    final latestBlock = blocks.last;
    return latestBlock.toQrData();
  }

  /// Verify a scanned QR code data string
  QrVerificationResult verifyQrData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      final batchId = data['batch_id'] as String?;
      final hash = data['hash'] as String?;

      if (batchId == null || hash == null) {
        return QrVerificationResult(
          isValid: false,
          message: 'Data QR tidak valid — format salah',
        );
      }

      // Find matching block in chain
      final matchingBlocks = _chain.where(
        (b) => b.batchId == batchId && b.hash == hash,
      );

      if (matchingBlocks.isEmpty) {
        return QrVerificationResult(
          isValid: false,
          batchId: batchId,
          message: '❌ Hash tidak ditemukan di blockchain — kemungkinan dipalsukan',
        );
      }

      final block = matchingBlocks.first;
      final hashValid = block.isValid();

      return QrVerificationResult(
        isValid: hashValid,
        batchId: batchId,
        block: block,
        message: hashValid
            ? '✅ Keaslian terverifikasi! Batch $batchId tercatat di blockchain.'
            : '⚠️ Hash block ditemukan tapi gagal verifikasi integritas.',
      );
    } catch (e) {
      return QrVerificationResult(
        isValid: false,
        message: 'Error membaca QR: $e',
      );
    }
  }

  // ─── Statistics ──────────────────────────────────────────

  /// Get blockchain statistics
  Map<String, dynamic> getStatistics() {
    final uniqueBatches = _chain.map((b) => b.batchId).where((id) => id != 'genesis').toSet();
    return {
      'total_blocks': _chain.length,
      'chain_length': chainLength,
      'unique_batches': uniqueBatches.length,
      'genesis_hash': _chain.isNotEmpty ? _chain.first.hash.substring(0, 16) : 'N/A',
      'latest_hash': _chain.isNotEmpty ? _chain.last.hash.substring(0, 16) : 'N/A',
      'latest_timestamp': _chain.isNotEmpty ? _chain.last.timestamp.toIso8601String() : 'N/A',
    };
  }

  // ─── Reset (for testing) ─────────────────────────────────

  /// Clear chain and re-initialize with genesis
  Future<void> resetChain() async {
    await _blockBox?.clear();
    _chain.clear();
    final genesis = BlockModel.genesis();
    await _saveBlock(genesis);
    _chain.add(genesis);
  }
}

// ─── Result Models ──────────────────────────────────────────

class ChainVerificationResult {
  final bool isValid;
  final int totalBlocks;
  final List<int> invalidBlocks;
  final String message;

  ChainVerificationResult({
    required this.isValid,
    required this.totalBlocks,
    required this.invalidBlocks,
    required this.message,
  });
}

class BatchProvenanceResult {
  final String batchId;
  final bool isVerified;
  final List<BlockModel> blocks;
  final String message;

  BatchProvenanceResult({
    required this.batchId,
    required this.isVerified,
    required this.blocks,
    required this.message,
  });
}

class QrVerificationResult {
  final bool isValid;
  final String? batchId;
  final BlockModel? block;
  final String message;

  QrVerificationResult({
    required this.isValid,
    this.batchId,
    this.block,
    required this.message,
  });
}
