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
  int _lives = 5;
  int _level = 1;
  int _combo = 0;
  int _maxCombo = 0;
  Timer? _spawnTimer;
  Timer? _survivalTimer;
  int _survivalSeconds = 0; // Stopwatch bertahan hidup

  // Screen shake effect on penalty
  bool _isShaking = false;

  // Beans & Popups
  final List<_FallingBean> _beans = [];
  final List<_ScorePopup> _popups = [];
  final Random _random = Random();
  late double _screenWidth;
  late double _screenHeight;

  // Bean types with explicit labels and special Golden Bean
  static const List<Map<String, dynamic>> _beanTypes = [
    {'emoji': '🟤', 'name': 'Normal', 'isDefect': false, 'isGolden': false, 'color': Color(0xFF4CAF50), 'label': 'BAGUS'},
    {'emoji': '⚫', 'name': 'Black Bean', 'isDefect': true, 'isGolden': false, 'color': Color(0xFFE53935), 'label': 'CACAT'},
    {'emoji': '🟡', 'name': 'Sour Bean', 'isDefect': true, 'isGolden': false, 'color': Color(0xFFFF9800), 'label': 'CACAT'},
    {'emoji': '🔴', 'name': 'Broken Bean', 'isDefect': true, 'isGolden': false, 'color': Color(0xFFE53935), 'label': 'CACAT'},
    {'emoji': '🟢', 'name': 'Unripe Bean', 'isDefect': true, 'isGolden': false, 'color': Color(0xFFFF5722), 'label': 'CACAT'},
    {'emoji': '⭐', 'name': 'Golden Bean', 'isDefect': true, 'isGolden': true, 'color': Color(0xFFFFD700), 'label': 'EMAS!'},
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
    _survivalTimer?.cancel();
    for (final bean in _beans) {
      bean.controller.dispose();
    }
    for (final popup in _popups) {
      popup.controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _lives = 5;
      _level = 1;
      _combo = 0;
      _maxCombo = 0;
      _survivalSeconds = 0;
      _isShaking = false;
      for (final bean in _beans) {
        bean.controller.dispose();
      }
      _beans.clear();
      for (final popup in _popups) {
        popup.controller.dispose();
      }
      _popups.clear();
    });

    _startTimers();
  }

  void _startTimers() {
    _spawnTimer?.cancel();
    // Spawn rate scaling with level: 650ms at Lv1 down to 350ms at Lv5+
    final spawnInterval = max(350, 680 - (_level * 60));
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnInterval), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _spawnBean();
    });

    // Stopwatch counter: survival timer
    _survivalTimer?.cancel();
    _survivalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        _survivalSeconds++;
        // Survival level up every 20 seconds
        final newLevel = (_survivalSeconds ~/ 20) + 1;
        if (newLevel != _level) {
          _level = newLevel;
          _showPopup(_screenWidth / 2 - 40, 160, '🔥 LEVEL $_level!', AppColors.warning);
          // Re-adjust spawn timer for higher difficulty
          _startTimers();
        }
      });
    });
  }

  void _spawnBean() {
    if (!mounted) return;

    // 5% chance of Golden Bean bonus, 55% defects, 40% normal beans
    final roll = _random.nextDouble();
    Map<String, dynamic> beanType;
    if (roll < 0.06) {
      // Golden Bean
      beanType = _beanTypes.firstWhere((b) => b['isGolden'] == true);
    } else if (roll < 0.60) {
      // Defect beans
      final defects = _beanTypes.where((b) => b['isDefect'] == true && b['isGolden'] == false).toList();
      beanType = defects[_random.nextInt(defects.length)];
    } else {
      // Normal bean
      beanType = _beanTypes.first;
    }

    // Faster speed: 3200ms at Lv1 scaling down to 1600ms at high levels
    final fallDuration = max(1600, 3200 - (_level * 280));
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: fallDuration),
    );

    final safeWidth = max(200.0, _screenWidth - 90.0);
    final startX = 16 + _random.nextDouble() * safeWidth;
    // Slight wobble offset (-15 to +15 px)
    final wobble = (_random.nextDouble() - 0.5) * 30.0;

    final bean = _FallingBean(
      id: DateTime.now().microsecondsSinceEpoch + _random.nextInt(1000),
      x: startX,
      wobbleOffset: wobble,
      beanType: beanType,
      controller: controller,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Bean reached bottom conveyor
        setState(() {
          final isDefect = (bean.beanType['isDefect'] as bool?) ?? false;
          final isGolden = (bean.beanType['isGolden'] as bool?) ?? false;

          if (!isDefect) {
            // Normal bean passed successfully into export conveyor!
            _score += 5;
            _showPopup(bean.x, _screenHeight - 150, '+5 ☕ Ekspor', AppColors.success);
          } else if (isGolden) {
            // Golden bean slipped away without penalty
            _showPopup(bean.x, _screenHeight - 150, 'Biji Emas Lewat!', AppColors.textHint);
          } else {
            // Defect bean contaminated the batch: LOSE A LIFE
            _lives--;
            _combo = 0;
            _triggerScreenShake();
            _showPopup(bean.x, _screenHeight - 150, '-❤️ Cacat Lolos!', AppColors.error);
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

  void _triggerScreenShake() {
    setState(() => _isShaking = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _isShaking = false);
    });
  }

  void _tapBean(_FallingBean bean, double currentY) {
    if (!_isPlaying) return;

    final isDefect = (bean.beanType['isDefect'] as bool?) ?? false;
    final isGolden = (bean.beanType['isGolden'] as bool?) ?? false;

    setState(() {
      if (isGolden) {
        // Tapped Golden Bean! Super reward
        _score += 50 * _level;
        _combo += 2;
        if (_combo > _maxCombo) _maxCombo = _combo;
        _showPopup(bean.x, currentY, '+${50 * _level} ⭐ EMAS!', const Color(0xFFFFD700));
      } else if (isDefect) {
        // Successfully tapped defect bean
        final points = (20 * _level) + (_combo * 4);
        _score += points;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;

        // Bonus life every 7 combo (up to max 5 lives)
        if (_combo % 7 == 0 && _lives < 5) {
          _lives++;
          _showPopup(bean.x, currentY - 15, '+1 ❤️ Nyawa!', AppColors.success);
        } else {
          _showPopup(bean.x, currentY, '+$points 🎯', AppColors.accent);
        }
      } else {
        // Accidental tap on normal bean: Penalty score, combo reset, and screen shake!
        _score = max(0, _score - 15);
        _combo = 0;
        _triggerScreenShake();
        _showPopup(bean.x, currentY, '-15 ⚠️ Kopi Baik!', AppColors.warning);
      }
      bean.controller.stop();
      _beans.removeWhere((b) => b.id == bean.id);
    });
    bean.controller.dispose();
  }

  void _showPopup(double x, double y, String text, Color color) {
    if (!mounted) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final popup = _ScorePopup(
      id: DateTime.now().microsecondsSinceEpoch + _random.nextInt(1000),
      x: x.clamp(16.0, max(16.0, _screenWidth - 100.0)),
      y: y.clamp(80.0, max(80.0, _screenHeight - 120.0)),
      text: text,
      color: color,
      controller: controller,
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _popups.removeWhere((p) => p.id == popup.id);
          });
        }
        controller.dispose();
      }
    });
    setState(() {
      _popups.add(popup);
    });
    controller.forward();
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _gameOver = true;
    });
    _spawnTimer?.cancel();
    _survivalTimer?.cancel();
    for (final bean in _beans) {
      bean.controller.dispose();
    }
    _beans.clear();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BeanSorter Blitz: Survival'),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🫘', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 14),
            const Text(
              'BeanSorter: Survival',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Berapa lama Anda bisa bertahan menyortir kopi sebelum kehabisan nyawa?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Rules Card
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
                  Row(
                    children: [
                      Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Aturan Mode Survival:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• 🟤 Biji BAGUS (Hijau) → JANGAN di-tap! Loloskan ke ekspor (+5 Poin)\n'
                    '• ⚫🟡🔴🟢 Biji CACAT (Merah) → TAP SEGERA! (+20 Poin)\n'
                    '• ⭐ Biji EMAS Langka → Tap untuk BONUS BESAR (+50 Poin)\n'
                    '• ❤️ 5 Nyawa — berkurang HANYA jika biji cacat lolos ke bawah\n'
                    '• ⚠️ Salah tap biji bagus: Skor berkurang & layar bergetar!\n'
                    '• 🔥 Combo x7 berturut-turut memulihkan +1 ❤️ Nyawa!\n'
                    '• 📈 Tanpa batas waktu! Semakin lama, kecepatan konveyor makin kencang!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('MULAI SURVIVAL', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      transform: _isShaking ? Matrix4.translationValues(5.0, 0.0, 0.0) : Matrix4.identity(),
      child: Stack(
        children: [
          // Game area background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF140D05), Color(0xFF28170B)],
              ),
            ),
          ),

          // Conveyor belt lines
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 68,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(top: BorderSide(color: AppColors.accent.withValues(alpha: 0.4), width: 2.5)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'KONVEYOR EKSPOR SPESIALTI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ),

          // Falling beans
          ..._beans.map((bean) {
            return AnimatedBuilder(
              animation: bean.controller,
              builder: (context, _) {
                final progress = bean.controller.value;
                final y = progress * (_screenHeight - 190);
                // Slight horizontal drift oscillation
                final wobbleX = sin(progress * pi * 3) * bean.wobbleOffset;
                final actualX = (bean.x + wobbleX).clamp(10.0, _screenWidth - 80.0);

                final isDefect = (bean.beanType['isDefect'] as bool?) ?? false;
                final isGolden = (bean.beanType['isGolden'] as bool?) ?? false;
                final badgeColor = isGolden
                    ? const Color(0xFFFFD700)
                    : isDefect
                        ? AppColors.error
                        : AppColors.success;
                final badgeText = (bean.beanType['label'] as String?) ?? '';

                return Positioned(
                  left: actualX,
                  top: y,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tapBean(bean, y),
                    child: Container(
                      width: 74,
                      height: 80,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isGolden
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                                  : (bean.beanType['color'] as Color).withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isGolden ? const Color(0xFFFFD700) : (isDefect ? AppColors.error : AppColors.accent),
                                width: isGolden ? 3.0 : 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isGolden
                                          ? const Color(0xFFFFD700)
                                          : isDefect
                                              ? AppColors.error
                                              : AppColors.accent)
                                      .withValues(alpha: isGolden ? 0.6 : 0.35),
                                  blurRadius: isGolden ? 12 : 8,
                                  spreadRadius: isGolden ? 2 : 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                bean.beanType['emoji'] as String,
                                style: TextStyle(fontSize: isGolden ? 30 : 26),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isGolden ? Colors.black : Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Floating score/penalty popups
          ..._popups.map((popup) {
            return AnimatedBuilder(
              animation: popup.controller,
              builder: (context, _) {
                final floatOffset = popup.controller.value * 35.0;
                final opacity = (1.0 - popup.controller.value).clamp(0.0, 1.0);
                return Positioned(
                  left: popup.x,
                  top: popup.y - floatOffset,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bgDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: popup.color.withValues(alpha: 0.7), width: 1.5),
                        ),
                        child: Text(
                          popup.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: popup.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // HUD - Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.92),
                border: const Border(bottom: BorderSide(color: Color(0xFF3D2E22))),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Lives (5 Hearts)
                    Row(
                      children: List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(
                            i < _lives ? '❤️' : '🖤',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    // Survival Stopwatch
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.accent, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_survivalSeconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'monospace',
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
              top: 90,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.95),
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
            top: 90,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Lv.$_level',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.info),
              ),
            ),
          ),
        ],
      ),
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
            const SizedBox(height: 8),
            Text(
              'Anda bertahan selama ${_formatTime(_survivalSeconds)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accent),
            ),
            const SizedBox(height: 20),

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
                  _buildStatRow('⏱️ Waktu Bertahan', _formatTime(_survivalSeconds)),
                  const Divider(color: Color(0xFF3D2E22), height: 16),
                  _buildStatRow('📈 Level Tertinggi', 'Lv.$_level'),
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
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: const Text('Kembali'),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent),
        ),
      ],
    );
  }
}

class _FallingBean {
  final int id;
  final double x;
  final double wobbleOffset;
  final Map<String, dynamic> beanType;
  final AnimationController controller;

  _FallingBean({
    required this.id,
    required this.x,
    required this.wobbleOffset,
    required this.beanType,
    required this.controller,
  });
}

class _ScorePopup {
  final int id;
  final double x;
  final double y;
  final String text;
  final Color color;
  final AnimationController controller;

  _ScorePopup({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.controller,
  });
}
