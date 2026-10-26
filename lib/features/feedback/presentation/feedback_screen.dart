import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/database/hive_service.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers Tab 1 (Kuliah PaM)
  final _kesanKuliahController = TextEditingController();
  final _saranKuliahController = TextEditingController();
  int _ratingKuliah = 5;

  // Controllers Tab 2 (Ekosistem Kopi)
  final _topikKopiController = TextEditingController();
  final _pesanKopiController = TextEditingController();
  String _kategoriKopi = 'Rekomendasi Mutu & Pasca-Panen';

  final List<String> _kategoriKopiOptions = [
    'Rekomendasi Mutu & Pasca-Panen',
    'Masalah Logistik & Pelabuhan',
    'Harga Pasar & Penjualan Ekspor',
    'Kendala Hama & Cuaca Kebun',
    'Usulan Fitur Blockchain / Sertifikat',
  ];

  List<Map<String, dynamic>> _savedHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HiveService().getAllFeedback();
    if (mounted) {
      setState(() {
        _savedHistory = list;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kesanKuliahController.dispose();
    _saranKuliahController.dispose();
    _topikKopiController.dispose();
    _pesanKopiController.dispose();
    super.dispose();
  }

  void _submitKuliahFeedback(String userRole) async {
    if (_kesanKuliahController.text.trim().isEmpty && _saranKuliahController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi kesan atau saran terlebih dahulu.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await HiveService().saveFeedback(
      kesan: _kesanKuliahController.text.trim(),
      saran: _saranKuliahController.text.trim(),
      rating: _ratingKuliah,
      category: 'Kuliah PaM',
      role: userRole,
    );

    _kesanKuliahController.clear();
    _saranKuliahController.clear();
    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback kuliah PaM berhasil disimpan ke database lokal Hive! ✨'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _submitKopiFeedback(String userRole) async {
    if (_pesanKopiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tuliskan detail saran/masukan ekosistem kopi.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final topik = _topikKopiController.text.trim().isEmpty ? _kategoriKopi : _topikKopiController.text.trim();

    await HiveService().saveFeedback(
      kesan: topik,
      saran: _pesanKopiController.text.trim(),
      rating: 5,
      category: _kategoriKopi,
      role: userRole,
    );

    _topikKopiController.clear();
    _pesanKopiController.clear();
    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saran ekosistem kopi berhasil diajukan ke jaringan BeanOrigin! ☕'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userRole = authState is AuthAuthenticated ? authState.user.roleDisplayName : 'Petani';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saran & Masukan'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.school_rounded, size: 20),
                  text: 'Kuliah PaM',
                ),
                Tab(
                  icon: Icon(Icons.coffee_rounded, size: 20),
                  text: 'Ekosistem Kopi',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildKuliahTab(userRole),
              _buildKopiTab(userRole),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKuliahTab(String userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5A4633)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemrograman Aplikasi Mobile',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Evaluasi & Masukan Semester 5 · 2026/2027',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rating
          const Text('Rating Pembelajaran Kuliah:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _ratingKuliah = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _ratingKuliah ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _ratingKuliah ? AppColors.accent : AppColors.textHint,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Kesan
          const Text('Kesan Mengikuti Kuliah:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _kesanKuliahController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Tuliskan kesan Anda selama praktikum dan teori PaM...',
            ),
          ),
          const SizedBox(height: 16),

          // Saran
          const Text('Saran untuk Mata Kuliah:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _saranKuliahController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Saran materi, tugas, atau metode belajar ke depan...',
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Kirim
          ElevatedButton.icon(
            onPressed: () => _submitKuliahFeedback(userRole),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Simpan Feedback Kuliah'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 28),

          // Riwayat
          _buildHistorySection('Kuliah PaM'),
        ],
      ),
    );
  }

  Widget _buildKopiTab(String userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Ekosistem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.coffee_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forum Suara Rantai Pasok',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Diajukan sebagai peran: $userRole',
                        style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dropdown Kategori Saran
          const Text('Kategori Saran / Topik:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _kategoriKopi,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                items: _kategoriKopiOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kategoriKopi = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Topik / Judul
          const Text('Judul / Pokok Masukan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _topikKopiController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Misal: Usulan standar suhu fermentasi anaerobic...',
            ),
          ),
          const SizedBox(height: 16),

          // Isi Saran
          const Text('Uraian Saran & Rekomendasi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pesanKopiController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Jelaskan saran, perbaikan alur logistik, atau teknik mutu kopi...',
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Kirim
          ElevatedButton.icon(
            onPressed: () => _submitKopiFeedback(userRole),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Kirim Saran Ekosistem Kopi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bgDark,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 28),

          // Riwayat
          _buildHistorySection('Ekosistem Kopi'),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String targetFilter) {
    final filtered = _savedHistory.where((item) {
      if (targetFilter == 'Kuliah PaM') {
        return item['category'] == 'Kuliah PaM' || item['category'] == null;
      } else {
        return item['category'] != 'Kuliah PaM';
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Riwayat Saran Saya (${filtered.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator(color: AppColors.accent))
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: const Center(
              child: Text(
                'Belum ada saran yang diajukan di kategori ini.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...filtered.map((item) {
            final dateStr = item['timestamp'] != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['timestamp'] as String))
                : '-';
            final roleTag = item['role'] ?? 'Umum';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleTag,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['category'] ?? 'Feedback',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item['kesan'] != null && (item['kesan'] as String).isNotEmpty)
                    Text(
                      '“${item['kesan']}”',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  if (item['saran'] != null && (item['saran'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Saran: ${item['saran']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
