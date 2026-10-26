import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/auth/data/auth_repository.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await AuthRepository().isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                ),
                title: const Text('Ambil Foto dari Kamera', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.info),
                ),
                title: const Text('Pilih dari Galeri HP', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profileImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricDialog() async {
    final repo = AuthRepository();
    final isAvailable = await repo.isBiometricAvailable();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: AppColors.accent, size: 28),
              SizedBox(width: 10),
              Text('Biometric Login', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAvailable
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: isAvailable ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAvailable
                            ? 'Sensor Biometrik Siap Digunakan'
                            : 'Sensor Biometrik Belum Aktif / Mode Emulator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masuk lebih cepat dan aman menggunakan sidik jari atau pemindai wajah tanpa mengetik password.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.5),
                activeThumbColor: AppColors.accent,
                title: const Text('Aktifkan Fingerprint', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                subtitle: Text(
                  _biometricEnabled ? 'Status: Aktif' : 'Status: Nonaktif',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                value: _biometricEnabled,
                onChanged: (val) async {
                  setDialogState(() => _biometricEnabled = val);
                  setState(() => _biometricEnabled = val);
                  if (val) {
                    await repo.enableBiometric();
                  } else {
                    // disable flag
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: AppColors.textHint)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.touch_app_rounded, size: 18),
              label: const Text('Uji Sensor'),
              onPressed: () async {
                Navigator.pop(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final user = await repo.biometricLogin();
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Autentikasi sidik jari berhasil! Akun: ${user.name}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Uji Biometrik: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Versi 1.0.0+1',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Platform Rantai Pasok & Verifikasi Ekspor Kopi Nusantara Berbasis LBS, AI Vision, dan Blockchain.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF3D2E22)),
              const SizedBox(height: 8),
              const Text(
                'Karya Tugas Akhir:',
                style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mata Kuliah: Pemrograman Aplikasi Mobile\nProgram Studi Informatika / Sistem Informasi\nSemester 5 — 2026/2027',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3D2E22)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teknologi Utama:', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('• Flutter 3 & BLoC State Management', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('• Offline Database Hive & Supabase BaaS', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('• LBS (Geolocator & OpenStreetMap)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('• Sensor Accelerometer & Gyroscope Clinometer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('• AI Vision & Google Gemini 1.5 Flash LLM', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('• SHA-256 Immutable Blockchain Ledger', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showBlockchainCertificates() {
    final batches = BatchRepository().getAllBatches();
    final verifiedBatches = batches.where((b) => b.status == 'verified' || b.status == 'exported').toList();

    if (verifiedBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada batch kopi yang terverifikasi sertifikat blockchain.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRouter.blockchainCert,
      arguments: verifiedBatches.first,
    );
  }

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
                icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                onPressed: _showAboutDialog,
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
                  'Lihat QR & Hash',
                  _showBlockchainCertificates,
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
                  'OpenStreetMap & Pelabuhan',
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
                  _biometricEnabled ? 'Aktif' : 'Nonaktif',
                  _showBiometricDialog,
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'Tentang Aplikasi',
                  'v1.0.0',
                  _showAboutDialog,
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
        // Avatar with Camera Tap
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _profileImage == null ? AppColors.accentGradient : null,
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _profileImage == null
                    ? Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bgDark,
                          ),
                        ),
                      )
                    : null,
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent, size: 16),
              ),
            ],
          ),
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
    final batches = BatchRepository().getAllBatches();
    final total = batches.length;
    final verified = batches.where((b) => b.status == 'verified').length;
    final exported = batches.where((b) => b.status == 'exported').length;

    return Row(
      children: [
        _buildStatCard('Total Batch', '$total', Icons.inventory_2_outlined),
        const SizedBox(width: 10),
        _buildStatCard('Verified', '$verified', Icons.verified_outlined),
        const SizedBox(width: 10),
        _buildStatCard('Exported', '$exported', Icons.local_shipping_outlined),
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
