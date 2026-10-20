import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/shared/models/batch_model.dart';

class BatchDetailScreen extends StatelessWidget {
  final BatchModel batch;
  const BatchDetailScreen({super.key, required this.batch});

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
                  Navigator.of(context).pushNamed(AppRouter.blockchainCert, arguments: batch);
                },
              ),
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, size: 18, color: AppColors.textSecondary),
                ),
                onPressed: () {},
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
                        batch.variety,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        batch.id,
                        style: TextStyle(
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
                  const SizedBox(height: 20),

                  // Key Metrics
                  _buildMetricsGrid(),
                  const SizedBox(height: 20),

                  // Origin Info
                  _buildSectionTitle('Informasi Asal'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _InfoItem(Icons.location_on_outlined, 'Daerah Asal', batch.origin),
                    _InfoItem(Icons.terrain_rounded, 'Ketinggian', '${batch.elevationMasl.toInt()} mdpl'),
                    _InfoItem(Icons.science_outlined, 'Proses', batch.process),
                    _InfoItem(Icons.person_outline, 'Petani', batch.farmerName),
                    if (batch.slopeAngle != null)
                      _InfoItem(Icons.landscape_rounded, 'Kemiringan Lahan', '${batch.slopeAngle!.toStringAsFixed(1)}°'),
                    if (batch.latitude != null && batch.longitude != null)
                      _InfoItem(Icons.my_location_rounded, 'Koordinat',
                          '${batch.latitude!.toStringAsFixed(4)}, ${batch.longitude!.toStringAsFixed(4)}'),
                  ]),
                  const SizedBox(height: 20),

                  // Quality Info
                  _buildSectionTitle('Kualitas & Mutu'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    if (batch.cuppingScore != null)
                      _InfoItem(Icons.star_rounded, 'Cupping Score', '${batch.cuppingScore!.toStringAsFixed(1)} SCA'),
                    _InfoItem(Icons.grade_rounded, 'Grade', batch.gradeLabel),
                    if (batch.moistureContent != null)
                      _InfoItem(Icons.water_drop_outlined, 'Kadar Air', '${batch.moistureContent!.toStringAsFixed(1)}%'),
                    if (batch.weightKg != null)
                      _InfoItem(Icons.scale_rounded, 'Berat', '${batch.weightKg!.toStringAsFixed(0)} kg'),
                  ]),
                  const SizedBox(height: 20),

                  // Timeline
                  _buildSectionTitle('Timeline'),
                  const SizedBox(height: 10),
                  _buildTimeline(),
                  const SizedBox(height: 20),

                  // Notes
                  if (batch.notes != null && batch.notes!.isNotEmpty) ...[
                    _buildSectionTitle('Catatan'),
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
                        batch.notes!,
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

  Widget _buildStatusRow() {
    final statusColor = _getStatusColor(batch.status);
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
                batch.statusDisplayName,
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
        if (batch.cuppingScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              batch.gradeLabel,
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
        _buildMetricCard(
          Icons.star_rounded,
          batch.cuppingScore?.toStringAsFixed(1) ?? '-',
          'Score SCA',
          AppColors.accent,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          Icons.terrain_rounded,
          '${batch.elevationMasl.toInt()}',
          'mdpl',
          AppColors.success,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          Icons.scale_rounded,
          batch.weightKg?.toStringAsFixed(0) ?? '-',
          'kg',
          AppColors.info,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          Icons.water_drop_outlined,
          batch.moistureContent?.toStringAsFixed(1) ?? '-',
          '% H₂O',
          const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D2E22)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      item.label,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
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
              if (!isLast) Divider(color: const Color(0xFF3D2E22), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline() {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final events = <Map<String, dynamic>>[
      {
        'icon': Icons.add_circle_outline,
        'label': 'Batch Dibuat',
        'date': dateFormat.format(batch.createdAt),
        'color': AppColors.warning,
        'done': true,
      },
      {
        'icon': Icons.verified_outlined,
        'label': 'Terverifikasi',
        'date': batch.verifiedAt != null ? dateFormat.format(batch.verifiedAt!) : 'Belum',
        'color': AppColors.success,
        'done': batch.verifiedAt != null,
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Diekspor',
        'date': batch.exportedAt != null ? dateFormat.format(batch.exportedAt!) : 'Belum',
        'color': AppColors.info,
        'done': batch.exportedAt != null,
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
                  Navigator.of(context).pushNamed(AppRouter.llmAdvisor, arguments: batch);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                Icons.camera_alt_outlined,
                'AI Scan',
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
                'Blockchain',
                const Color(0xFF9C27B0),
                () {
                  Navigator.of(context).pushNamed(AppRouter.blockchainCert, arguments: batch);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                Icons.map_outlined,
                'Peta Lokasi',
                AppColors.warning,
                () {
                  Navigator.of(context).pushNamed(AppRouter.mapScreen, arguments: {
                    'latitude': batch.latitude,
                    'longitude': batch.longitude,
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
