import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/core/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
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
                  // TODO: Navigate to notifications
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Auction Clock Widget
                  _buildAuctionClock(),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Market Price Preview
                  _buildSectionHeader('Harga Pasar', Icons.trending_up_rounded),
                  const SizedBox(height: 10),
                  _buildMarketPreview(),
                  const SizedBox(height: 24),

                  // Recent Batches
                  _buildSectionHeader('Batch Terbaru', Icons.inventory_2_outlined),
                  const SizedBox(height: 10),
                  _buildRecentBatches(),
                  const SizedBox(height: 24),

                  // Coffee Origin Map Preview
                  _buildSectionHeader('Peta Sentra Kopi', Icons.map_outlined),
                  const SizedBox(height: 10),
                  _buildMapPreview(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.batchList);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Batch Baru'),
      ),
    );
  }

  Widget _buildAuctionClock() {
    final utcNow = _now.toUtc();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A4633), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Auction Clock — ICE Futures Europe',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              _buildMarketStatus(utcNow),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppConstants.timeZoneOffsets.entries.map((entry) {
              final localTime = utcNow.add(Duration(hours: entry.value));
              return _buildTimeCard(entry.key, localTime);
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
    return Column(
      children: [
        Text(
          zone,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
      ],
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
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRouter.batchList),
          child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _buildMarketPreview() {
    final currencies = [
      {'flag': '🇮🇩', 'code': 'IDR', 'price': '98.500', 'change': '+2.3%', 'up': true},
      {'flag': '🇺🇸', 'code': 'USD', 'price': '5.82', 'change': '-0.4%', 'up': false},
      {'flag': '🇬🇧', 'code': 'GBP', 'price': '4.58', 'change': '+1.1%', 'up': true},
      {'flag': '🇪🇺', 'code': 'EUR', 'price': '5.31', 'change': '+0.8%', 'up': true},
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: currencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final c = currencies[index];
          final isUp = c['up'] as bool;
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
                      c['code'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      c['price'] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c['change'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUp ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentBatches() {
    // Placeholder batch cards
    final batches = [
      {'variety': 'Arabika Gayo', 'origin': 'Aceh Tengah', 'score': '87.5', 'status': 'verified'},
      {'variety': 'Robusta Lampung', 'origin': 'Lampung Barat', 'score': '78.0', 'status': 'pending'},
      {'variety': 'Arabika Toraja', 'origin': 'Toraja Utara', 'score': '89.0', 'status': 'exported'},
    ];

    return Column(
      children: batches.map((batch) {
        final statusColor = batch['status'] == 'verified'
            ? AppColors.success
            : batch['status'] == 'exported'
                ? AppColors.info
                : AppColors.warning;
        return Container(
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
                      batch['variety']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      batch['origin']!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${batch['score']} SCA',
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
                      batch['status']!.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
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
        child: Center(
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
                'Tap untuk membuka peta penuh',
                style: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
