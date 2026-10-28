import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';
import 'package:bean_origin/core/notifications/notification_service.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';
import 'package:bean_origin/features/blockchain/data/blockchain_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Live market data
  Map<String, double> _rates = {
    'USD': 1.0,
    'IDR': 16920.0,
    'GBP': 0.787,
    'EUR': 0.913,
  };
  bool _ratesLoaded = true;
  static const double _coffeePriceUsd = 5.82;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchRates();
    // Schedule auction alarm on first load
    NotificationService().scheduleAuctionAlarm();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    try {
      final url = '${AppConstants.frankfurterBaseUrl}/latest?from=USD&to=IDR,GBP,EUR';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _rates = ratesData.map((key, value) => MapEntry(key, (value as num).toDouble()));
            _rates['USD'] = 1.0;
            _ratesLoaded = true;
          });
        }
      }
    } catch (_) {
      // Fallback rates
      if (mounted) {
        setState(() {
          _rates = {'USD': 1.0, 'IDR': 16920.0, 'GBP': 0.787, 'EUR': 0.913};
          _ratesLoaded = true;
        });
      }
    }
  }

  String _formatPrice(String currency) {
    if (!_ratesLoaded) return '...';
    final rate = _rates[currency] ?? 1.0;
    final price = _coffeePriceUsd * rate;
    if (currency == 'IDR') return NumberFormat('#,##0', 'id').format(price);
    return NumberFormat('#,##0.00').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 72,
            backgroundColor: AppColors.bgDark,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🫘', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BeanOrigin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Batch Explorer',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.aiScanner);
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                onPressed: () {
                  _showNotificationSettingsDialog();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final userRole = authState is AuthAuthenticated ? authState.user.role : 'farmer';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Role-Based Welcome Banner
                      _buildRoleWelcomeBanner(),
                      const SizedBox(height: 16),

                      // Quick Actions (Selalu ada di atas untuk akses cepat 13 kriteria dosen)
                      _buildQuickActions(),
                      const SizedBox(height: 20),

                      // Susunan Widget Adaptif Berdasarkan Role
                      if (userRole == AppConstants.roleFarmer) ...[
                        _buildFarmerHighlightCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Batch Panen Kebun', Icons.inventory_2_outlined, AppRouter.batchList),
                        const SizedBox(height: 10),
                        _buildRecentBatches(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Auction Clock (Bursa London)', Icons.access_time_rounded, AppRouter.main),
                        const SizedBox(height: 10),
                        _buildAuctionClock(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Harga Pasar Ekspor', Icons.trending_up_rounded, AppRouter.marketPrice),
                        const SizedBox(height: 10),
                        _buildMarketPreview(),
                      ] else if (userRole == AppConstants.roleQGrader) ...[
                        _buildQGraderHighlightCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Antrean Kurasi Mutu (Pending)', Icons.rate_review_rounded, AppRouter.batchList),
                        const SizedBox(height: 10),
                        _buildPendingBatchesForQGrader(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Harga Pasar & Valas', Icons.trending_up_rounded, AppRouter.marketPrice),
                        const SizedBox(height: 10),
                        _buildMarketPreview(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Auction Clock London', Icons.access_time_rounded, AppRouter.main),
                        const SizedBox(height: 10),
                        _buildAuctionClock(),
                      ] else if (userRole == AppConstants.roleExporter) ...[
                        _buildExporterHighlightCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Bursa Lelang London (ICE Futures)', Icons.access_time_rounded, AppRouter.main),
                        const SizedBox(height: 10),
                        _buildAuctionClock(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Live Kurs Mata Uang Ekspor', Icons.trending_up_rounded, AppRouter.marketPrice),
                        const SizedBox(height: 10),
                        _buildMarketPreview(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Batch Siap Ekspor Kontainer', Icons.local_shipping_outlined, AppRouter.batchList),
                        const SizedBox(height: 10),
                        _buildVerifiedBatchesForExporter(),
                      ] else ...[
                        // Super Admin Overview
                        _buildAdminHighlightCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Auction Clock', Icons.access_time_rounded, AppRouter.main),
                        const SizedBox(height: 10),
                        _buildAuctionClock(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Harga Pasar', Icons.trending_up_rounded, AppRouter.marketPrice),
                        const SizedBox(height: 10),
                        _buildMarketPreview(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Semua Batch Rantai Pasok', Icons.inventory_2_outlined, AppRouter.batchList),
                        const SizedBox(height: 10),
                        _buildRecentBatches(),
                      ],

                      const SizedBox(height: 24),
                      // Peta Sentra Kopi
                      _buildSectionHeader('Peta Sentra Kopi & Logistik', Icons.map_outlined, AppRouter.mapScreen),
                      const SizedBox(height: 10),
                      _buildMapPreview(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final userRole = state is AuthAuthenticated ? state.user.role : 'farmer';
          // Tombol tambah batch hanya untuk Petani dan Admin
          if (userRole == AppConstants.roleFarmer || userRole == AppConstants.roleAdmin) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.addBatch);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Batch Baru'),
            );
          }
          // Untuk Q-Grader dan Eksportir, FAB tidak ditampilkan
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRoleWelcomeBanner() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final role = user?.role ?? 'farmer';
        final name = user?.name ?? 'Pengguna';

        Color badgeColor;
        String roleDesc;
        IconData roleIcon;

        switch (role) {
          case 'q_grader':
            badgeColor = AppColors.warning;
            roleDesc = 'Fokus: Periksa sampel biji kopi dengan AI Scanner & verifikasi skor cupping SCA.';
            roleIcon = Icons.rate_review_rounded;
            break;
          case 'exporter':
            badgeColor = AppColors.info;
            roleDesc = 'Fokus: Pantau lelang ICE London, live valas, & kargo kontainer ke pelabuhan ekspor.';
            roleIcon = Icons.local_shipping_rounded;
            break;
          case 'admin':
            badgeColor = const Color(0xFF9C27B0);
            roleDesc = 'Akses penuh: Manajemen pengguna, audit blockchain ledger, & monitoring suplai nasional.';
            roleIcon = Icons.admin_panel_settings_rounded;
            break;
          default:
            badgeColor = AppColors.accent;
            roleDesc = 'Fokus: Daftarkan panen baru dengan GPS, pantau cuaca kebun, & konsultasi LLM AI.';
            roleIcon = Icons.eco_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withValues(alpha: 0.15),
                AppColors.bgCard,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(roleIcon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hai, $name',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.roleDisplayName ?? 'Petani',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      roleDesc,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Role Adaptive Highlight Cards ──────────────────────────────

  Widget _buildFarmerHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kondisi Kebun & Cuaca Panen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.weatherMonitor),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Detail Cuaca', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Suhu Rata-rata',
                  '23.5°C',
                  'Ideal Penjemuran ☀️',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Kelembaban',
                  '72%',
                  'Risiko Jamur: Rendah',
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.llmAdvisor),
            icon: const Icon(Icons.psychology_rounded, size: 18),
            label: const Text('Tanya AI: Panduan Perawatan Panen Kopi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bgDark,
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQGraderHighlightCard() {
    final pendingCount = BatchRepository().getAllBatches().where((b) => b.status == 'pending').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Meja Uji Kurasi Kualitas (SCA)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pendingCount Batch',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Lakukan inspeksi visual menggunakan AI Scanner untuk menghitung cacat fisik biji kopi sebelum menandatangani sertifikat mutu.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.aiScanner),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Buka AI Scanner'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.batchList),
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Antrean Uji'),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExporterHighlightCard() {
    final verifiedCount = BatchRepository().getAllBatches().where((b) => b.status == 'verified').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_boat_rounded, color: AppColors.info, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Logistik & Pengiriman Ekspor',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$verifiedCount Siap Kapal',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pantau rute kontainer ke 7 pelabuhan ekspor Indonesia dan pastikan sensor accelerometer kargo bebas dari guncangan ekstrem.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.mapScreen),
                  icon: const Icon(Icons.alt_route_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Rute Pelabuhan'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.sensorMonitor),
                  icon: const Icon(Icons.speed_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Sensor Kargo'),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHighlightCard() {
    final batches = BatchRepository().getAllBatches();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF9C27B0), size: 24),
              SizedBox(width: 8),
              Text(
                'Ringkasan Pengawas Sistem Nasional',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Total Batch', '${batches.length}', 'Tercatat di Hive', AppColors.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Lolos Kurasi',
                  '${batches.where((b) => b.status == 'verified' || b.status == 'exported').length}',
                  'Standar SCA',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Ekspor Kapal',
                  '${batches.where((b) => b.status == 'exported').length}',
                  'Kontainer',
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), maxLines: 1),
        ],
      ),
    );
  }

  void _showCuppingDialog(BatchModel batch) {
    final scoreController = TextEditingController(text: (batch.cuppingScore ?? 85.0).toStringAsFixed(1));
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
            Text(
              'Batch: ${batch.variety} (${batch.origin})',
              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Cupping Score (SCA: 0-100)',
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
                hintText: 'Misal: Floral, jasmine, sweet finish...',
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
              final updated = batch.copyWith(
                status: 'verified',
                cuppingScore: score,
                verifiedAt: DateTime.now(),
                notes: notesController.text.isNotEmpty
                    ? '${batch.notes ?? ""}\n[Q-Grader Note]: ${notesController.text}'.trim()
                    : batch.notes,
              );

              // Update in repository & bloc
              BatchRepository().updateBatch(updated);
              context.read<BatchBloc>().add(BatchUpdate(updated));

              // Record to Blockchain
              await BlockchainService().addBlock(updated);

              // Notification
              await NotificationService().showBatchStatusNotification(
                batchId: updated.id,
                variety: updated.variety,
                newStatus: 'verified',
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Batch ${updated.variety} diverifikasi (${score.toStringAsFixed(1)} SCA) & dicatat ke Blockchain!'),
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

  void _showExportDialog(BatchModel batch) {
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
              Text(
                'Batch: ${batch.variety} (${batch.origin})',
                style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700),
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
                final updated = batch.copyWith(
                  status: 'exported',
                  exportedAt: DateTime.now(),
                  notes: '${batch.notes ?? ""}\n[Ekspor]: Kontainer ${containerController.text} via $selectedPort'.trim(),
                );

                BatchRepository().updateBatch(updated);
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
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚢 Batch ${updated.variety} siap berlayar via $selectedPort!'),
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

  Widget _buildPendingBatchesForQGrader() {
    final pendingBatches = BatchRepository().getAllBatches().where((b) => b.status == 'pending').toList();
    if (pendingBatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text('Tidak ada batch yang menunggu kurasi saat ini. Semua sudah dinilai! 🎉',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: pendingBatches.map((batch) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pushNamed(AppRouter.batchDetail, arguments: batch),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.variety, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('${batch.origin} · Petani: ${batch.farmerName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showCuppingDialog(batch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text('Kurasi Mutu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerifiedBatchesForExporter() {
    final verifiedBatches = BatchRepository().getAllBatches().where((b) => b.status == 'verified').toList();
    if (verifiedBatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text('Semua batch yang lolos verifikasi sudah diproses ekspor.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: verifiedBatches.map((batch) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pushNamed(AppRouter.batchDetail, arguments: batch),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.variety, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('Skor SCA: ${batch.cuppingScore?.toStringAsFixed(1) ?? "-"} · ${batch.weightKg?.toInt() ?? 0} Kg',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showExportDialog(batch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text('Kirim Kapal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Notifikasi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotifOption(ctx, '⏰', 'Auction Alarm', 'Alarm harian jam buka lelang London', () {
              NotificationService().scheduleAuctionAlarm();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alarm lelang dijadwalkan'), backgroundColor: AppColors.success),
              );
            }),
            const SizedBox(height: 8),
            _buildNotifOption(ctx, '📈', 'Test Currency Alert', 'Simulasi perubahan kurs', () {
              NotificationService().showCurrencyAlert(
                currency: 'IDR',
                changePercent: 1.5,
                oldRate: 16920,
                newRate: 17174,
              );
              Navigator.pop(ctx);
            }),
            const SizedBox(height: 8),
            _buildNotifOption(ctx, '📦', 'Test Batch Alert', 'Simulasi status batch berubah', () {
              NotificationService().showBatchStatusNotification(
                batchId: 'BATCH-001',
                variety: 'Arabika Gayo',
                newStatus: 'verified',
              );
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifOption(BuildContext ctx, String emoji, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionClock() {
    final utcNow = _now.toUtc();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A4633), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Auction Clock · ICE Futures',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildMarketStatus(utcNow),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: AppConstants.timeZoneOffsets.entries.map((entry) {
              final localTime = utcNow.add(Duration(hours: entry.value));
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildTimeCard(entry.key, localTime),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatus(DateTime utcNow) {
    final londonHour = utcNow.hour; // London = UTC (simplified, no BST)
    final isOpen = londonHour >= 10 && londonHour < 18;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isOpen ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String zone, DateTime time) {
    final timeStr = DateFormat('HH:mm:ss').format(time);
    final dateStr = DateFormat('dd MMM').format(time);
    final isLondon = zone == 'London';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLondon ? AppColors.accent.withValues(alpha: 0.4) : const Color(0xFF3D2E22),
          width: isLondon ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            zone,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLondon ? AppColors.accent : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 9, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.camera_alt_rounded, 'label': 'AI Scan', 'color': const Color(0xFF4CAF50), 'route': AppRouter.aiScanner},
      {'icon': Icons.speed_rounded, 'label': 'Sensor', 'color': const Color(0xFF2196F3), 'route': AppRouter.sensorMonitor},
      {'icon': Icons.currency_exchange_rounded, 'label': 'Market', 'color': const Color(0xFFFF9800), 'route': AppRouter.marketPrice},
      {'icon': Icons.cloud_rounded, 'label': 'Cuaca', 'color': const Color(0xFF9C27B0), 'route': AppRouter.weatherMonitor},
      {'icon': Icons.games_rounded, 'label': 'Mini Game', 'color': const Color(0xFFE91E63), 'route': AppRouter.miniGame},
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(action['route'] as String);
            },
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (action['color'] as Color).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  action['label'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String route) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(route),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _buildMarketPreview() {
    final currencies = [
      {'flag': '🇮🇩', 'code': 'IDR'},
      {'flag': '🇺🇸', 'code': 'USD'},
      {'flag': '🇬🇧', 'code': 'GBP'},
      {'flag': '🇪🇺', 'code': 'EUR'},
    ];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.marketPrice),
      child: SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: currencies.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final c = currencies[index];
            final code = c['code'] as String;
            final price = _formatPrice(code);
            return Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3D2E22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c['flag'] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        code,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentBatches() {
    // Dynamic data from BatchRepository
    final allBatches = BatchRepository().getAllBatches();
    final recentBatches = allBatches.take(3).toList();

    return Column(
      children: recentBatches.map((batch) {
        final statusColor = batch.status == 'verified'
            ? AppColors.success
            : batch.status == 'exported'
                ? AppColors.info
                : AppColors.warning;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pushNamed(AppRouter.batchDetail, arguments: batch),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: Row(
              children: [
                // Coffee icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${batch.origin} · ${batch.farmerName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (batch.cuppingScore != null)
                      Text(
                        '${batch.cuppingScore?.toStringAsFixed(1) ?? '-'} SCA',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        batch.statusDisplayName.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.mapScreen),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D2E22)),
        ),
        child: Stack(
          children: [
            // Decorative dots representing map markers
            ..._buildMapDots(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: AppColors.accent.withValues(alpha: 0.5), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Peta Sentra Kopi Indonesia',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${BatchRepository().getAllBatches().where((b) => b.latitude != null).length} lokasi kebun terdaftar',
                    style: TextStyle(color: AppColors.accent.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMapDots() {
    // Decorative dots to hint there's map content
    final dots = [
      const Positioned(left: 30, top: 30, child: _MapDot(color: AppColors.success)),
      const Positioned(left: 80, top: 60, child: _MapDot(color: AppColors.warning)),
      const Positioned(right: 60, top: 40, child: _MapDot(color: AppColors.info)),
      const Positioned(right: 30, bottom: 50, child: _MapDot(color: AppColors.success)),
      const Positioned(left: 50, bottom: 40, child: _MapDot(color: AppColors.info)),
    ];
    return dots;
  }
}

class _MapDot extends StatelessWidget {
  final Color color;
  const _MapDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
    );
  }
}
