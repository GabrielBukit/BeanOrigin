import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

class BlockModel extends Equatable {
  final int index;
  final String batchId;
  final DateTime timestamp;
  final Map<String, dynamic> batchData;
  final String previousHash;
  final String hash;

  const BlockModel({
    required this.index,
    required this.batchId,
    required this.timestamp,
    required this.batchData,
    required this.previousHash,
    required this.hash,
  });

  /// Genesis block (first block in chain)
  factory BlockModel.genesis() {
    final timestamp = DateTime.utc(2026, 1, 1);
    const previousHash = '0';
    final data = {'message': 'BeanOrigin Genesis Block'};
    final hash = _calculateHash(0, timestamp, data, previousHash);

    return BlockModel(
      index: 0,
      batchId: 'genesis',
      timestamp: timestamp,
      batchData: data,
      previousHash: previousHash,
      hash: hash,
    );
  }

  /// Create a new block from batch data
  factory BlockModel.create({
    required int index,
    required String batchId,
    required Map<String, dynamic> batchData,
    required String previousHash,
  }) {
    final timestamp = DateTime.now().toUtc();
    final hash = _calculateHash(index, timestamp, batchData, previousHash);

    return BlockModel(
      index: index,
      batchId: batchId,
      timestamp: timestamp,
      batchData: batchData,
      previousHash: previousHash,
      hash: hash,
    );
  }

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      index: json['index'] as int,
      batchId: json['batch_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      batchData: json['batch_data'] is String
          ? jsonDecode(json['batch_data'] as String) as Map<String, dynamic>
          : json['batch_data'] as Map<String, dynamic>,
      previousHash: json['previous_hash'] as String,
      hash: json['hash'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'batch_id': batchId,
      'timestamp': timestamp.toIso8601String(),
      'batch_data': batchData,
      'previous_hash': previousHash,
      'hash': hash,
    };
  }

  /// Verify the block hash is valid
  bool isValid() {
    final calculated = _calculateHash(index, timestamp, batchData, previousHash);
    return calculated == hash;
  }

  /// Verify that this block links to the previous block correctly
  bool isLinkedTo(BlockModel previousBlock) {
    return previousHash == previousBlock.hash && index == previousBlock.index + 1;
  }

  static String _calculateHash(
    int index,
    DateTime timestamp,
    Map<String, dynamic> batchData,
    String previousHash,
  ) {
    final input = '$index${timestamp.toIso8601String()}${jsonEncode(batchData)}$previousHash';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate QR data string for this block
  String toQrData() {
    return jsonEncode({
      'index': index,
      'batch_id': batchId,
      'hash': hash,
      'previous_hash': previousHash,
      'origin': batchData['origin'],
      'variety': batchData['variety'],
      'timestamp': timestamp.toIso8601String(),
    });
  }

  @override
  List<Object?> get props => [index, batchId, timestamp, hash, previousHash];
}
