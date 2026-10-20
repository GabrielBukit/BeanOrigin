import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';

class WeatherMonitorScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const WeatherMonitorScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  State<WeatherMonitorScreen> createState() => _WeatherMonitorScreenState();
}

class _WeatherMonitorScreenState extends State<WeatherMonitorScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];

  // Default coords: Aceh Tengah (Gayo highlands)
  late double _lat;
  late double _lon;
  late String _locName;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitude ?? 4.6167;
    _lon = widget.longitude ?? 96.8333;
    _locName = widget.locationName ?? 'Aceh Tengah (Gayo)';
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = '${AppConstants.openMeteoBaseUrl}/forecast'
          '?latitude=$_lat&longitude=$_lon'
          '&current=temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max'
          '&forecast_days=7&timezone=Asia/Jakarta';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'] as Map<String, dynamic>;
        final daily = data['daily'] as Map<String, dynamic>;

        setState(() {
          _currentWeather = current;

          // Build 7-day forecast
          final dates = (daily['time'] as List).cast<String>();
          final maxTemps = (daily['temperature_2m_max'] as List);
          final minTemps = (daily['temperature_2m_min'] as List);
          final precip = (daily['precipitation_sum'] as List);
          final precipProb = (daily['precipitation_probability_max'] as List);
          final codes = (daily['weather_code'] as List);

          _forecast = List.generate(dates.length, (i) => <String, dynamic>{
            'date': dates[i],
            'temp_max': maxTemps[i],
            'temp_min': minTemps[i],
            'precipitation': precip[i],
            'precip_prob': precipProb[i],
            'weather_code': codes[i],
          });

          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data cuaca: $e';
        // Fallback data
        _currentWeather = {
          'temperature_2m': 22.5,
          'relative_humidity_2m': 78,
          'precipitation': 0.0,
          'rain': 0.0,
          'weather_code': 1,
          'wind_speed_10m': 5.2,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca Kebun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _fetchWeather,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Header
                  _buildLocationHeader(),
                  const SizedBox(height: 16),

                  // Current Weather
                  if (_currentWeather != null) _buildCurrentWeather(),
                  const SizedBox(height: 16),

                  // Weather Metrics
                  if (_currentWeather != null) _buildWeatherMetrics(),
                  const SizedBox(height: 20),

                  // Rain Alert
                  if (_currentWeather != null) _buildRainAlert(),
                  const SizedBox(height: 20),

                  // 7-Day Forecast
                  _buildForecastSection(),
                  const SizedBox(height: 16),

                  // Agronomy Tips
                  _buildAgronomyTips(),
                  const SizedBox(height: 16),

                  // API Credit
                  _buildApiCredit(),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5A4633), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final temp = _currentWeather!['temperature_2m'];
    final weatherCode = _currentWeather!['weather_code'] as int;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        children: [
          Text(
            _getWeatherEmoji(weatherCode),
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            '${temp is double ? temp.toStringAsFixed(1) : temp}°C',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getWeatherDescription(weatherCode),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetrics() {
    final humidity = _currentWeather!['relative_humidity_2m'];
    final precip = _currentWeather!['precipitation'];
    final rain = _currentWeather!['rain'];
    final wind = _currentWeather!['wind_speed_10m'];

    return Row(
      children: [
        _buildMetricCard(Icons.water_drop_rounded, '${humidity}%', 'Kelembaban', const Color(0xFF42A5F5)),
        const SizedBox(width: 8),
        _buildMetricCard(Icons.umbrella_rounded, '${precip}mm', 'Curah Hujan', const Color(0xFF5C6BC0)),
        const SizedBox(width: 8),
        _buildMetricCard(Icons.grain_rounded, '${rain}mm', 'Hujan', const Color(0xFF26A69A)),
        const SizedBox(width: 8),
        _buildMetricCard(Icons.air_rounded, '${wind}km/h', 'Angin', const Color(0xFF78909C)),
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildRainAlert() {
    final rain = (_currentWeather!['rain'] as num?) ?? 0;
    // Check forecast for heavy rain
    bool heavyRainSoon = false;
    for (final day in _forecast.take(3)) {
      if (((day['precipitation'] as num?) ?? 0) > 10) {
        heavyRainSoon = true;
        break;
      }
    }

    if (rain > 0 || heavyRainSoon) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Peringatan Hujan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    heavyRainSoon
                        ? 'Prakiraan hujan lebat dalam 3 hari ke depan. Pertimbangkan untuk mengangkat jemuran biji kopi!'
                        : 'Sedang hujan. Pastikan biji kopi terlindung!',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '✅ Cuaca cerah — aman untuk penjemuran biji kopi',
              style: TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    if (_forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Prakiraan 7 Hari',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._forecast.map((day) {
          final date = DateTime.parse(day['date'] as String);
          final dayName = DateFormat('EEE, dd MMM').format(date);
          final maxTemp = day['temp_max'];
          final minTemp = day['temp_min'];
          final precip = day['precipitation'];
          final precipProb = day['precip_prob'];
          final weatherCode = day['weather_code'] as int;
          final isToday = date.day == DateTime.now().day;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? AppColors.accent.withValues(alpha: 0.08) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? AppColors.accent.withValues(alpha: 0.3) : const Color(0xFF3D2E22),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    _getWeatherEmoji(weatherCode),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    isToday ? 'Hari ini' : dayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, color: AppColors.info.withValues(alpha: 0.5), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${precipProb}%',
                        style: const TextStyle(fontSize: 11, color: AppColors.info),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${precip}mm',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${_numToStr(minTemp)}° / ${_numToStr(maxTemp)}°',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAgronomyTips() {
    if (_currentWeather == null) return const SizedBox.shrink();

    final temp = (_currentWeather!['temperature_2m'] as num).toDouble();
    final humidity = (_currentWeather!['relative_humidity_2m'] as num).toDouble();

    List<String> tips = [];
    if (temp > 30) tips.add('🌡️ Suhu tinggi — lakukan penjemuran pagi hari saja');
    if (temp < 15) tips.add('❄️ Suhu rendah — perlambat proses fermentasi');
    if (humidity > 85) tips.add('💧 Kelembaban tinggi — risiko jamur pada biji kopi!');
    if (humidity < 50) tips.add('🏜️ Udara kering — proses penjemuran akan lebih cepat');
    if (tips.isEmpty) tips.add('👍 Kondisi cuaca ideal untuk penanganan kopi');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text(
                'Tips Agronomis',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              )),
        ],
      ),
    );
  }

  Widget _buildApiCredit() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data cuaca dari Open-Meteo API (free, tanpa API key)',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌧️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '☁️';
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Cerah';
    if (code <= 3) return 'Berawan Sebagian';
    if (code <= 48) return 'Kabut / Berkabut';
    if (code <= 55) return 'Gerimis';
    if (code <= 57) return 'Gerimis Beku';
    if (code <= 65) return 'Hujan';
    if (code <= 67) return 'Hujan Beku';
    if (code <= 75) return 'Hujan Salju';
    if (code <= 77) return 'Butiran Salju';
    if (code <= 82) return 'Hujan Lebat';
    if (code <= 86) return 'Hujan Salju Lebat';
    if (code <= 99) return 'Badai Petir';
    return 'Tidak Diketahui';
  }

  String _numToStr(dynamic n) {
    if (n is double) return n.toStringAsFixed(0);
    return n.toString();
  }
}
