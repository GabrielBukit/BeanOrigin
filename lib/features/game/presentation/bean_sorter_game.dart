import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bean_origin/core/theme/app_theme.dart';

class BeanSorterGame extends StatefulWidget {
  const BeanSorterGame({super.key});

  @override
  State<BeanSorterGame> createState() => _BeanSorterGameState();
}

class _BeanSorterGameState extends State<BeanSorterGame> with TickerProviderStateMixin {
  // Game state
  bool _isPlaying = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  int _level = 1;
  int _combo = 0;
  int _maxCombo = 0;
  Timer? _spawnTimer;
  Timer? _gameTimer;
  int _timeLeft = 60;

  // Beans
  final List<_FallingBean> _beans = [];
  final Random _random = Random();
  late double _screenWidth;
  late double _screenHeight;

  // Bean types
  static const List<Map<String, dynamic>> _beanTypes = [
    {'emoji': '🟤', 'name': 'Normal', 'isDefect': false, 'color': Color(0xFF4CAF50)},
    {'emoji': '⚫', 'name': 'Black Bean', 'isDefect': true, 'color': Color(0xFF424242)},
    {'emoji': '🟡', 'name': 'Sour', 'isDefect': true, 'color': Color(0xFFFF9800)},
    {'emoji': '🔴', 'name': 'Broken', 'isDefect': true, 'color': Color(0xFFE53935)},
    {'emoji': '🟢', 'name': 'Unripe', 'isDefect': true, 'color': Color(0xFF8BC34A)},
  ];

  // Edukasi facts
  static const List<String> _defectFacts = [
    '☕ Black Bean: Biji yang sudah mati karena fermentasi berlebih. Rasanya sangat pahit dan tidak enak.',
    '☕ Sour Bean: Disebabkan fermentasi yang tidak sempurna. Menimbulkan rasa asam yang tidak diinginkan.',
    '☕ Broken Bean: Biji pecah karena proses hulling yang terlalu keras. Merusak konsistensi roasting.',
    '☕ Unripe (Quaker): Biji yang dipetik sebelum matang. Tidak akan berubah warna saat di-roast.',
    '☕ Insect Damage: Lubang kecil pada biji akibat hama. Menyebabkan rasa kayu dan flat.',
    '☕ Kopi Specialty harus memiliki 0 cacat primer per 350g sampel.',
    '☕ Cupping score ≥80 untuk Premium, ≥85 untuk Specialty grade.',
  ];

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    for (final bean in _beans) {
      bean.controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _lives = 3;
      _level = 1;
      _combo = 0;
      _maxCombo = 0;
      _timeLeft = 60;
      for (final bean in _beans) {
        bean.controller.dispose();
      }
      _beans.clear();
    });

    // Spawn beans periodically
    _spawnTimer = Timer.periodic(Duration(milliseconds: 1200 - (_level * 100).clamp(0, 800)), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _spawnBean();
    });

    // Countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
        // Level up every 15 seconds
        _level = (60 - _timeLeft) ~/ 15 + 1;
      });
    });
  }

  void _spawnBean() {
    if (!mounted) return;

    // Higher levels = more defects
    final defectChance = 0.3 + (_level * 0.05);
    final isDefect = _random.nextDouble() < defectChance;

    Map<String, dynamic> beanType;
    if (isDefect) {
      final defects = _beanTypes.where((b) => b['isDefect'] == true).toList();
      beanType = defects[_random.nextInt(defects.length)];
    } else {
      beanType = _beanTypes.first;
    }

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3500 - (_level * 200).clamp(0, 1500)),
    );

    final bean = _FallingBean(
      id: DateTime.now().microsecondsSinceEpoch,
      x: 30 + _random.nextDouble() * (_screenWidth - 90),
      beanType: beanType,
      controller: controller,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Bean reached bottom without being tapped
        setState(() {
          if (!bean.beanType['isDefect']) {
            // Normal bean missed = lost a life (should have kept it)
          } else {
            // Defect bean missed = lost a life
            _lives--;
            _combo = 0;
            if (_lives <= 0) _endGame();
          }
          _beans.removeWhere((b) => b.id == bean.id);
        });
        controller.dispose();
      }
    });

    setState(() => _beans.add(bean));
    controller.forward();
  }

  void _tapBean(_FallingBean bean) {
    if (!_isPlaying) return;

    setState(() {
      if (bean.beanType['isDefect']) {
        // Correctly tapped a defect bean
        _score += 10 * _level + (_combo * 2);
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
      } else {
        // Incorrectly tapped a normal bean
        _lives--;
        _combo = 0;
        if (_lives <= 0) _endGame();
      }
      bean.controller.stop();
      _beans.removeWhere((b) => b.id == bean.id);
    });
    bean.controller.dispose();
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _gameOver = true;
    });
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    for (final bean in _beans) {
      bean.controller.dispose();
    }
    _beans.clear();
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BeanSorter Blitz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _gameOver
          ? _buildGameOverScreen()
          : _isPlaying
              ? _buildGameScreen()
              : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🫘', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'BeanSorter Blitz',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sortir biji kopi cacat secepat mungkin!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3D2E22)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara Bermain:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• 🟤 Biji Normal → JANGAN disentuh!\n'
                    '• ⚫🟡🔴🟢 Biji Cacat → TAP untuk buang!\n'
                    '• ❤️ 3 nyawa — salah tap = kehilangan 1\n'
                    '• ⏱️ 60 detik — skor setinggi mungkin\n'
                    '• 🔥 Combo bonus untuk tap berturut-turut\n'
                    '• Level meningkat → biji makin cepat!',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('MULAI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Stack(
      children: [
        // Game area background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1207), Color(0xFF2D1B0E)],
            ),
          ),
        ),

        // Conveyor belt lines
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(top: BorderSide(color: AppColors.accent.withValues(alpha: 0.3), width: 2)),
            ),
            child: Center(
              child: Text(
                '▼ ▼ ▼  CONVEYOR  ▼ ▼ ▼',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),

        // Falling beans
        ..._beans.map((bean) {
          return AnimatedBuilder(
            animation: bean.controller,
            builder: (context, _) {
              final y = bean.controller.value * (_screenHeight - 180);
              return Positioned(
                left: bean.x,
                top: y,
                child: GestureDetector(
                  onTap: () => _tapBean(bean),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (bean.beanType['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (bean.beanType['color'] as Color).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        bean.beanType['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // HUD - Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(color: const Color(0xFF3D2E22))),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Lives
                  Row(
                    children: List.generate(3, (i) {
                      return Text(
                        i < _lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 18),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bgDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Timer
                  Row(
                    children: [
                      Icon(Icons.timer_rounded, color: _timeLeft <= 10 ? AppColors.error : AppColors.textSecondary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_timeLeft}s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _timeLeft <= 10 ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Combo indicator
        if (_combo >= 2)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔥 x$_combo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bgDark,
                ),
              ),
            ),
          ),

        // Level indicator
        Positioned(
          top: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Lv.$_level',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.info),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    final fact = _defectFacts[_random.nextInt(_defectFacts.length)];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Game Over!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3D2E22)),
              ),
              child: Column(
                children: [
                  _buildStatRow('📊 Skor Akhir', '$_score'),
                  const Divider(color: Color(0xFF3D2E22), height: 16),
                  _buildStatRow('📈 Level Tercapai', '$_level'),
                  const Divider(color: Color(0xFF3D2E22), height: 16),
                  _buildStatRow('🔥 Combo Tertinggi', 'x$_maxCombo'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edukasi fact
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school_rounded, color: AppColors.info, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Tahukah kamu?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fact,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Main Lagi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent),
        ),
      ],
    );
  }
}

class _FallingBean {
  final int id;
  final double x;
  final Map<String, dynamic> beanType;
  final AnimationController controller;

  _FallingBean({
    required this.id,
    required this.x,
    required this.beanType,
    required this.controller,
  });
}
