import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/core/notifications/notification_service.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';
import 'package:bean_origin/features/blockchain/data/blockchain_service.dart';

class BatchDetailScreen extends StatefulWidget {
  final BatchModel batch;
  const BatchDetailScreen({super.key, required this.batch});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  late BatchModel _batch;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
  }

  void _showCuppingVerificationDialog() {
    final scoreController = TextEditingController(text: (_batch.cuppingScore ?? 85.0).toStringAsFixed(1));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.success),
            SizedBox(width: 8),
            Text('Verifikasi Mutu & Cupping', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peran: Q-Grader / Kurator Mutu',
              style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Cupping Score (SCA Standard: 0-100)',
                hintText: 'Misal: 87.5',
                prefixIcon: Icon(Icons.star_rounded, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Catatan Rasa / Cupping Notes',
                hintText: 'Floral, jasmine, brown sugar sweetness...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = double.tryParse(scoreController.text) ?? 85.0;
              final updated = _batch.copyWith(
                status: 'verified',
                cuppingScore: score,
                verifiedAt: DateTime.now(),
                notes: notesController.text.isNotEmpty
                    ? '${_batch.notes ?? ""}\n[Q-Grader Note]: ${notesController.text}'.trim()
                    : _batch.notes,
              );

              // Update state & Bloc
              setState(() => _batch = updated);
              context.read<BatchBloc>().add(BatchUpdate(updated));

              // Record on local Blockchain
              await BlockchainService().addBlock(updated);

              // Trigger Notification
              await NotificationService().showBatchStatusNotification(
                batchId: updated.id,
                variety: updated.variety,
                newStatus: 'verified',
              );

              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Batch ${updated.id} berhasil diverifikasi (${score.toStringAsFixed(1)} SCA) & dicatat ke Blockchain!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Verifikasi & Simpan'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    String selectedPort = 'Pelabuhan Belawan';
    final containerController = TextEditingController(text: 'CONT-ID-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: AppColors.info),
              SizedBox(width: 8),
              Text('Proses Ekspor Kontainer', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Peran: Eksportir Komoditas',
                style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: containerController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nomor Segel Kontainer',
                  prefixIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPort,
                dropdownColor: AppColors.bgCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Pelabuhan Keberangkatan',
                  prefixIcon: Icon(Icons.directions_boat_rounded, color: AppColors.accent),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pelabuhan Belawan', child: Text('Belawan (Sumatera Utara)')),
                  DropdownMenuItem(value: 'Pelabuhan Panjang', child: Text('Panjang (Lampung)')),
                  DropdownMenuItem(value: 'Pelabuhan Tanjung Priok', child: Text('Tanjung Priok (Jakarta)')),
                  DropdownMenuItem(value: 'Pelabuhan Tanjung Emas', child: Text('Tanjung Emas (Semarang)')),
                  DropdownMenuItem(value: 'Pelabuhan Tanjung Perak', child: Text('Tanjung Perak (Surabaya)')),
                  DropdownMenuItem(value: 'Pelabuhan Benoa', child: Text('Benoa (Bali)')),
                  DropdownMenuItem(value: 'Pelabuhan Makassar', child: Text('Makassar (Sulawesi)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPort = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = _batch.copyWith(
                  status: 'exported',
                  exportedAt: DateTime.now(),
                  notes: '${_batch.notes ?? ""}\n[Ekspor]: Kontainer ${containerController.text} via $selectedPort'.trim(),
                );

                setState(() => _batch = updated);
                context.read<BatchBloc>().add(BatchUpdate(updated));

                // Blockchain ledger event
                await BlockchainService().addBlock(updated);

                // Notification
                await NotificationService().showBatchStatusNotification(
                  batchId: updated.id,
                  variety: updated.variety,
                  newStatus: 'exported',
                );

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚢 Batch ${updated.id} siap berlayar via $selectedPort!'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              },
              child: const Text('Konfirmasi Pengiriman'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgDark.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.accent),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.blockchainCert, arguments: _batch);
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A3728),
                      Color(0xFF2D1B0E),
                      Color(0xFF1A1207),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(child: Text('☕', style: TextStyle(fontSize: 36))),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _batch.variety,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _batch.id,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Grade
                  _buildStatusRow(),
                  const SizedBox(height: 16),

                  // Role Action Quick Banner (Q-Grader / Exporter)
                  _buildRoleActionBanner(context),
                  const SizedBox(height: 20),

                  // Key Metrics
                  _buildMetricsGrid(),
                  const SizedBox(height: 20),

                  // Origin Info
                  _buildSectionTitle('Informasi Asal & Lahan'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _InfoItem(Icons.location_on_outlined, 'Daerah Asal', _batch.origin),
                    _InfoItem(Icons.terrain_rounded, 'Ketinggian', '${_batch.elevationMasl.toInt()} mdpl'),
                    _InfoItem(Icons.science_outlined, 'Proses', _batch.process),
                    _InfoItem(Icons.person_outline, 'Petani', _batch.farmerName),
                    if (_batch.slopeAngle != null)
                      _InfoItem(Icons.landscape_rounded, 'Kemiringan Lahan (Gyro)', '${_batch.slopeAngle!.toStringAsFixed(1)}°'),
                    if (_batch.latitude != null && _batch.longitude != null)
                      _InfoItem(Icons.my_location_rounded, 'Koordinat GPS',
                          '${_batch.latitude!.toStringAsFixed(4)}, ${_batch.longitude!.toStringAsFixed(4)}'),
                  ]),
                  const SizedBox(height: 20),

                  // Quality Info
                  _buildSectionTitle('Kualitas & Mutu Ekspor'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    if (_batch.cuppingScore != null)
                      _InfoItem(Icons.star_rounded, 'Cupping Score', '${_batch.cuppingScore!.toStringAsFixed(1)} SCA'),
                    _InfoItem(Icons.grade_rounded, 'Grade Mutu', _batch.gradeLabel),
                    if (_batch.moistureContent != null)
                      _InfoItem(Icons.water_drop_outlined, 'Kadar Air', '${_batch.moistureContent!.toStringAsFixed(1)}%'),
                    if (_batch.weightKg != null)
                      _InfoItem(Icons.scale_rounded, 'Berat Total', '${_batch.weightKg!.toStringAsFixed(0)} kg'),
                  ]),
                  const SizedBox(height: 20),

                  // Timeline
                  _buildSectionTitle('Timeline Rantai Pasok (Blockchain)'),
                  const SizedBox(height: 10),
                  _buildTimeline(),
                  const SizedBox(height: 20),

                  // Notes
                  if (_batch.notes != null && _batch.notes!.isNotEmpty) ...[
                    _buildSectionTitle('Catatan & Logistik'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3D2E22)),
                      ),
                      child: Text(
                        _batch.notes!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleActionBanner(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentUserRole = authState is AuthAuthenticated ? authState.user.role : 'farmer';
        final isQGrader = currentUserRole == AppConstants.roleQGrader || currentUserRole == AppConstants.roleAdmin;
        final isExporter = currentUserRole == AppConstants.roleExporter || currentUserRole == AppConstants.roleAdmin;

        if (_batch.status == 'pending') {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.rate_review_rounded, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Siap Kurasi Mutu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning),
                      ),
                      Text(
                        isQGrader
                            ? 'Verifikasi batch & masukkan skor cupping SCA'
                            : 'Khusus hak akses Q-Grader / Kurator Mutu',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isQGrader
                      ? _showCuppingVerificationDialog
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Akses Dibatasi: Hanya Q-Grader/Admin yang dapat menilai cupping score.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isQGrader ? AppColors.warning : AppColors.bgSurface,
                    foregroundColor: isQGrader ? Colors.black : AppColors.textHint,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    isQGrader ? 'Kurasi Mutu' : 'Terkunci 🔒',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        } else if (_batch.status == 'verified') {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lolos Kurasi Ekspor',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                      Text(
                        isExporter
                            ? 'Batch memenuhi standar ekspor komoditas'
                            : 'Khusus hak akses Eksportir / Perusahaan Dagang',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isExporter
                      ? _showExportDialog
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Akses Dibatasi: Hanya Eksportir/Admin yang dapat memproses kontainer ekspor.'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExporter ? AppColors.info : AppColors.bgSurface,
                    foregroundColor: isExporter ? Colors.white : AppColors.textHint,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    isExporter ? 'Proses Ekspor' : 'Terkunci 🔒',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusRow() {
    final statusColor = _getStatusColor(_batch.status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 6),
              Text(
                _batch.statusDisplayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (_batch.cuppingScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _batch.gradeLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.bgDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Cupping Score',
            _batch.cuppingScore != null ? _batch.cuppingScore!.toStringAsFixed(1) : '—',
            'SCA Standard',
            Icons.star_rounded,
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            'Ketinggian',
            '${_batch.elevationMasl.toInt()}',
            'mdpl',
            Icons.terrain_rounded,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            'Kadar Air',
            _batch.moistureContent != null ? '${_batch.moistureContent!.toStringAsFixed(1)}%' : '—',
            'Target 10-12%',
            Icons.water_drop_outlined,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          Text(unit, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 46, color: Color(0xFF2E2218)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline() {
    final events = [
      {
        'label': 'Batch Didaftarkan oleh Petani',
        'date': DateFormat('dd MMM yyyy, HH:mm').format(_batch.createdAt),
        'done': true,
        'color': AppColors.accent,
        'icon': Icons.add_circle_outline,
      },
      {
        'label': 'Verifikasi Mutu & Cupping Q-Grader',
        'date': _batch.verifiedAt != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(_batch.verifiedAt!)
            : 'Menunggu Kurator',
        'done': _batch.verifiedAt != null,
        'color': AppColors.success,
        'icon': Icons.verified_outlined,
      },
      {
        'label': 'Pemuatan & Pengapalan Kontainer Ekspor',
        'date': _batch.exportedAt != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(_batch.exportedAt!)
            : 'Menunggu Pengapalan',
        'done': _batch.exportedAt != null,
        'color': AppColors.info,
        'icon': Icons.local_shipping_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: events.asMap().entries.map((entry) {
          final event = entry.value;
          final isLast = entry.key == events.length - 1;
          final isDone = event['done'] as bool;
          final color = event['color'] as Color;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? color.withValues(alpha: 0.2) : AppColors.bgSurface,
                      border: Border.all(
                        color: isDone ? color : AppColors.textHint.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      event['icon'] as IconData,
                      size: 14,
                      color: isDone ? color : AppColors.textHint,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: isDone ? color.withValues(alpha: 0.3) : AppColors.textHint.withValues(alpha: 0.2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['date'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDone ? AppColors.textSecondary : AppColors.textHint.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!isLast) const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                Icons.smart_toy_outlined,
                'LLM Advisory',
                AppColors.info,
                () {
                  Navigator.of(context).pushNamed(AppRouter.llmAdvisor, arguments: _batch);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                Icons.camera_alt_outlined,
                'AI Defect Scan',
                AppColors.success,
                () {
                  Navigator.of(context).pushNamed(AppRouter.aiScanner);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                Icons.link_rounded,
                'Sertifikat Blockchain',
                const Color(0xFF9C27B0),
                () {
                  Navigator.of(context).pushNamed(AppRouter.blockchainCert, arguments: _batch);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                Icons.map_outlined,
                'Rute Logistik',
                AppColors.warning,
                () {
                  Navigator.of(context).pushNamed(AppRouter.mapScreen, arguments: {
                    'latitude': _batch.latitude,
                    'longitude': _batch.longitude,
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'exported':
        return AppColors.info;
      case 'sold':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.warning;
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}
