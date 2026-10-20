import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final userName = user?.name ?? 'Petani Kopi';
        final userEmail = user?.email ?? 'petani@email.com';
        final userRole = user?.roleDisplayName ?? 'Petani';
        final roleEmoji = _getRoleEmoji(user?.role ?? 'farmer');
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Saya'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(initial, userName, userRole, roleEmoji, userEmail),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStats(),
                const SizedBox(height: 24),

                // Menu Items
                _buildMenuItem(
                  context,
                  Icons.inventory_2_outlined,
                  'Batch Saya',
                  '12 batch',
                  () => Navigator.of(context).pushNamed(AppRouter.batchList),
                ),
                _buildMenuItem(
                  context,
                  Icons.verified_outlined,
                  'Sertifikat Blockchain',
                  '8 sertifikat',
                  () {},
                ),
                _buildMenuItem(
                  context,
                  Icons.camera_alt_outlined,
                  'AI Defect Scanner',
                  'Scan biji kopi',
                  () => Navigator.of(context).pushNamed(AppRouter.aiScanner),
                ),
                _buildMenuItem(
                  context,
                  Icons.speed_rounded,
                  'Sensor Monitor',
                  'Accelerometer & Gyroscope',
                  () => Navigator.of(context).pushNamed(AppRouter.sensorMonitor),
                ),
                _buildMenuItem(
                  context,
                  Icons.currency_exchange_rounded,
                  'Harga Pasar',
                  'Konversi mata uang',
                  () => Navigator.of(context).pushNamed(AppRouter.marketPrice),
                ),
                _buildMenuItem(
                  context,
                  Icons.cloud_outlined,
                  'Cuaca Kebun',
                  'Open-Meteo API',
                  () => Navigator.of(context).pushNamed(AppRouter.weatherMonitor),
                ),
                _buildMenuItem(
                  context,
                  Icons.map_outlined,
                  'Peta Sentra Kopi',
                  'OpenStreetMap',
                  () => Navigator.of(context).pushNamed(AppRouter.mapScreen),
                ),
                _buildMenuItem(
                  context,
                  Icons.games_outlined,
                  'BeanSorter Blitz',
                  'Mini Game edukasi',
                  () => Navigator.of(context).pushNamed(AppRouter.miniGame),
                ),
                _buildMenuItem(
                  context,
                  Icons.fingerprint,
                  'Biometric Login',
                  'Aktif',
                  () {},
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'Tentang Aplikasi',
                  'v1.0.0',
                  () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleEmoji(String role) {
    switch (role) {
      case 'farmer':
        return '🌱';
      case 'q_grader':
        return '🔬';
      case 'exporter':
        return '📦';
      case 'admin':
        return '👤';
      default:
        return '🌱';
    }
  }

  Widget _buildProfileHeader(String initial, String name, String role, String emoji, String email) {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bgDark,
                  ),
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: AppColors.accent, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$emoji $role',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard('Total Batch', '12', Icons.inventory_2_outlined),
        const SizedBox(width: 10),
        _buildStatCard('Verified', '8', Icons.verified_outlined),
        const SizedBox(width: 10),
        _buildStatCard('Exported', '5', Icons.local_shipping_outlined),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3D2E22)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String trailing, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent, size: 22),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing.isNotEmpty)
              Text(trailing, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
