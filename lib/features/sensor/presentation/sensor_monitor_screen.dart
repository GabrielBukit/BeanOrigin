import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';

class SensorMonitorScreen extends StatefulWidget {
  const SensorMonitorScreen({super.key});

  @override
  State<SensorMonitorScreen> createState() => _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<SensorMonitorScreen> with SingleTickerProviderStateMixin {
  // Accelerometer
  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _totalG = 0;
  bool _shockDetected = false;
  List<Map<String, dynamic>> _shockLog = [];
  StreamSubscription? _accelSubscription;

  // Gyroscope
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  double _slopeDegrees = 0;
  StreamSubscription? _gyroSubscription;

  // Tab
  late TabController _tabController;

  // Shake detection
  DateTime? _lastShake;
  int _shakeCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startListening();
  }

  void _startListening() {
    // Accelerometer
    _accelSubscription = accelerometerEventStream().listen((event) {
      setState(() {
        _accelX = event.x;
        _accelY = event.y;
        _accelZ = event.z;
        _totalG = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.81;

        // Shock detection
        if (_totalG > AppConstants.shockThresholdG) {
          _shockDetected = true;
          _shockLog.insert(0, {
            'time': DateTime.now(),
            'g': _totalG,
          });
          if (_shockLog.length > 20) _shockLog = _shockLog.sublist(0, 20);
        } else {
          _shockDetected = false;
        }

        // Shake detection for random inspect
        if (_totalG > AppConstants.shakeThresholdG / 9.81) {
          final now = DateTime.now();
          final last = _lastShake;
          if (last == null || now.difference(last) > const Duration(milliseconds: 500)) {
            _shakeCount++;
            _lastShake = now;
            if (_shakeCount >= 3) {
              _shakeCount = 0;
              _triggerRandomInspect();
            }
          }
        }
      });
    });

    // Gyroscope
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
        // Simple slope calculation from accelerometer tilt
        // Using atan2 of the gravity components
        _slopeDegrees = atan2(_accelX, sqrt(_accelY * _accelY + _accelZ * _accelZ)) * 180 / pi;
      });
    });
  }

  void _triggerRandomInspect() {
    final random = Random();
    final sackNumber = random.nextInt(50) + 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shuffle_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Random Inspect!', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '#$sackNumber',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bgDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Karung ke-$sackNumber terpilih untuk inspeksi acak!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(icon: Icon(Icons.vibration_rounded), text: 'Accelerometer'),
            Tab(icon: Icon(Icons.screen_rotation_rounded), text: 'Gyroscope'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccelerometerTab(),
          _buildGyroscopeTab(),
        ],
      ),
    );
  }

  // ────────────── ACCELEROMETER TAB ──────────────

  Widget _buildAccelerometerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // G-Force Gauge
          _buildGForceGauge(),
          const SizedBox(height: 16),

          // Axis Values
          _buildAxisValues(_accelX, _accelY, _accelZ, 'm/s²'),
          const SizedBox(height: 16),

          // Shock Status
          _buildShockStatus(),
          const SizedBox(height: 16),

          // Shake to Inspect hint
          _buildShakeHint(),
          const SizedBox(height: 16),

          // Shock Log
          _buildShockLog(),
        ],
      ),
    );
  }

  Widget _buildGForceGauge() {
    final gClamped = _totalG.clamp(0.0, 5.0);
    final fraction = gClamped / 5.0;
    final color = _totalG > AppConstants.shockThresholdG
        ? AppColors.error
        : _totalG > 1.5
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: [
          const Text(
            'Cargo Shock Monitor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF3D2E22),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_totalG.toStringAsFixed(2)}G',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const Text(
                      'Total Force',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Threshold: ${AppConstants.shockThresholdG}G',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisValues(double x, double y, double z, String unit) {
    return Row(
      children: [
        _buildAxisCard('X', x, Colors.redAccent),
        const SizedBox(width: 8),
        _buildAxisCard('Y', y, Colors.greenAccent),
        const SizedBox(width: 8),
        _buildAxisCard('Z', z, Colors.blueAccent),
      ],
    );
  }

  Widget _buildAxisCard(String axis, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D2E22)),
        ),
        child: Column(
          children: [
            Text(
              axis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShockStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _shockDetected
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _shockDetected ? AppColors.error : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _shockDetected ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: _shockDetected ? AppColors.error : AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            _shockDetected ? '⚠️ SHOCK TERDETEKSI!' : '✅ Kargo stabil — tidak ada guncangan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _shockDetected ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.phone_android_rounded, color: AppColors.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '📱 Kocok HP 3x untuk memilih karung inspeksi acak!',
              style: TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShockLog() {
    if (_shockLog.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shock Event Log',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        ...(_shockLog.take(5).map((log) {
          final time = log['time'] as DateTime;
          final g = log['g'] as double;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                ),
                const Spacer(),
                Text(
                  '${g.toStringAsFixed(2)}G',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  // ────────────── GYROSCOPE TAB ──────────────

  Widget _buildGyroscopeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Clinometer (Bubble Level)
          _buildClinometer(),
          const SizedBox(height: 16),

          // Gyro Axis Values
          _buildAxisValues(_gyroX, _gyroY, _gyroZ, 'rad/s'),
          const SizedBox(height: 16),

          // Slope Data Card
          _buildSlopeCard(),
          const SizedBox(height: 16),

          // Usage Info
          _buildUsageInfo(),
        ],
      ),
    );
  }

  Widget _buildClinometer() {
    final slopeClamped = _slopeDegrees.clamp(-90.0, 90.0);
    final isLevel = slopeClamped.abs() < 3.0;
    final color = isLevel
        ? AppColors.success
        : slopeClamped.abs() < 15
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: [
          const Text(
            'Slope Meter / Clinometer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Visual Clinometer
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _ClinometerPainter(
                angle: slopeClamped,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${slopeClamped.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      isLevel ? 'LEVEL' : 'TILTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeCard() {
    String classification;
    Color color;
    if (_slopeDegrees.abs() < 5) {
      classification = 'Dataran Rendah (Flat)';
      color = AppColors.success;
    } else if (_slopeDegrees.abs() < 15) {
      classification = 'Lereng Landai (Gentle Slope)';
      color = AppColors.warning;
    } else if (_slopeDegrees.abs() < 30) {
      classification = 'Lereng Curam (Steep Slope)';
      color = AppColors.error;
    } else {
      classification = 'Sangat Curam (Very Steep)';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.landscape_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classification,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Data kemiringan akan tersimpan sebagai metadata batch kebun',
                  style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panduan Penggunaan:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            '• Letakkan HP sejajar permukaan tanah/rak\n'
            '• Baca sudut kemiringan dari clinometer\n'
            '• Data kemiringan otomatis tersimpan\n'
            '• Ideal untuk mengukur lereng lahan kebun\n'
            '  atau kemiringan rak penjemuran biji kopi',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Clinometer Painter ──────────────────────────────────────

class _ClinometerPainter extends CustomPainter {
  final double angle;
  final Color color;

  _ClinometerPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer circle
    final outerPaint = Paint()
      ..color = const Color(0xFF3D2E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outerPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF5A4633)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 36; i++) {
      final tickAngle = i * 10 * pi / 180;
      final inner = i % 9 == 0 ? radius - 15 : radius - 8;
      final start = Offset(
        center.dx + cos(tickAngle) * inner,
        center.dy + sin(tickAngle) * inner,
      );
      final end = Offset(
        center.dx + cos(tickAngle) * radius,
        center.dy + sin(tickAngle) * radius,
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Bubble indicator
    final bubbleAngle = angle * pi / 180;
    final bubbleX = center.dx + sin(bubbleAngle) * (radius * 0.5);
    final bubbleY = center.dy;
    final bubblePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final bubbleGlow = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bubbleX, bubbleY), 16, bubbleGlow);
    canvas.drawCircle(Offset(bubbleX, bubbleY), 10, bubblePaint);

    // Center dot
    final centerPaint = Paint()
      ..color = const Color(0xFF5A4633)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _ClinometerPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
