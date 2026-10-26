import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bean_origin/core/utils/constants.dart';

/// Data model for current weather conditions
class CurrentWeather {
  final double temperature;
  final int humidity;
  final double precipitation;
  final double rain;
  final int weatherCode;
  final double windSpeed;
  final DateTime fetchedAt;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.rain,
    required this.weatherCode,
    required this.windSpeed,
    required this.fetchedAt,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      precipitation: (json['precipitation'] as num).toDouble(),
      rain: (json['rain'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      fetchedAt: DateTime.now(),
    );
  }

  /// Whether it's currently raining
  bool get isRaining => rain > 0 || precipitation > 0;

  /// Weather emoji based on WMO weather code
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 57) return '🌧️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '🌨️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode <= 86) return '🌨️';
    if (weatherCode <= 99) return '⛈️';
    return '☁️';
  }

  /// Weather description in Bahasa Indonesia
  String get description {
    if (weatherCode == 0) return 'Cerah';
    if (weatherCode <= 3) return 'Berawan Sebagian';
    if (weatherCode <= 48) return 'Kabut / Berkabut';
    if (weatherCode <= 55) return 'Gerimis';
    if (weatherCode <= 57) return 'Gerimis Beku';
    if (weatherCode <= 65) return 'Hujan';
    if (weatherCode <= 67) return 'Hujan Beku';
    if (weatherCode <= 75) return 'Hujan Salju';
    if (weatherCode <= 77) return 'Butiran Salju';
    if (weatherCode <= 82) return 'Hujan Lebat';
    if (weatherCode <= 86) return 'Hujan Salju Lebat';
    if (weatherCode <= 99) return 'Badai Petir';
    return 'Tidak Diketahui';
  }

  /// Agronomic tips based on current conditions
  List<String> get agronomicTips {
    final tips = <String>[];
    if (temperature > 30) tips.add('🌡️ Suhu tinggi — lakukan penjemuran pagi hari saja');
    if (temperature < 15) tips.add('❄️ Suhu rendah — perlambat proses fermentasi');
    if (humidity > 85) tips.add('💧 Kelembaban tinggi — risiko jamur pada biji kopi!');
    if (humidity < 50) tips.add('🏜️ Udara kering — proses penjemuran akan lebih cepat');
    if (isRaining) tips.add('🌧️ Sedang hujan — segera angkat jemuran biji kopi!');
    if (tips.isEmpty) tips.add('👍 Kondisi cuaca ideal untuk penanganan kopi');
    return tips;
  }
}

/// Data model for daily forecast
class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitation;
  final int precipProbability;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitation,
    required this.precipProbability,
    required this.weatherCode,
  });

  /// Whether heavy rain is expected
  bool get isHeavyRain => precipitation > 10;

  /// Weather emoji
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '🌨️';
    if (weatherCode <= 86) return '🌨️';
    if (weatherCode <= 99) return '⛈️';
    return '☁️';
  }
}

/// Complete weather data for a location
class WeatherData {
  final CurrentWeather current;
  final List<DailyForecast> forecast;
  final String locationName;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.current,
    required this.forecast,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  /// Check if heavy rain is expected in the next N days
  bool heavyRainExpected({int days = 3}) {
    return forecast.take(days).any((f) => f.isHeavyRain);
  }

  /// Get summary text for LLM context injection
  String toLlmContext() {
    final buffer = StringBuffer();
    buffer.writeln('Lokasi: $locationName ($latitude, $longitude)');
    buffer.writeln('Suhu saat ini: ${current.temperature}°C');
    buffer.writeln('Kelembaban: ${current.humidity}%');
    buffer.writeln('Curah hujan: ${current.precipitation}mm');
    buffer.writeln('Kondisi: ${current.description}');
    if (forecast.isNotEmpty) {
      buffer.writeln('Prakiraan 3 hari:');
      for (final f in forecast.take(3)) {
        buffer.writeln(
            '  ${f.date.toIso8601String().split('T').first}: '
            '${f.tempMin.toStringAsFixed(0)}°-${f.tempMax.toStringAsFixed(0)}°C, '
            'hujan ${f.precipitation}mm (${f.precipProbability}%)');
      }
    }
    return buffer.toString();
  }
}

/// Service to fetch weather data from Open-Meteo API
class WeatherService {
  // Singleton
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Cache to avoid excessive API calls
  final Map<String, WeatherData> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Fetch weather data for given coordinates
  /// Returns cached data if available and not expired
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String locationName = 'Unknown',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';

    // Check cache
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      final age = DateTime.now().difference(cached.current.fetchedAt);
      if (age < _cacheExpiry) {
        return cached;
      }
    }

    try {
      final url = '${AppConstants.openMeteoBaseUrl}/forecast'
          '?latitude=$latitude&longitude=$longitude'
          '&current=temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max'
          '&forecast_days=7&timezone=Asia/Jakarta';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = CurrentWeather.fromJson(
          data['current'] as Map<String, dynamic>,
        );

        final daily = data['daily'] as Map<String, dynamic>;
        final dates = (daily['time'] as List).cast<String>();
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;
        final precip = daily['precipitation_sum'] as List;
        final precipProb = daily['precipitation_probability_max'] as List;
        final codes = daily['weather_code'] as List;

        final forecast = List<DailyForecast>.generate(
          dates.length,
          (i) => DailyForecast(
            date: DateTime.parse(dates[i]),
            tempMax: (maxTemps[i] as num).toDouble(),
            tempMin: (minTemps[i] as num).toDouble(),
            precipitation: (precip[i] as num).toDouble(),
            precipProbability: (precipProb[i] as num).toInt(),
            weatherCode: (codes[i] as num).toInt(),
          ),
        );

        final weatherData = WeatherData(
          current: current,
          forecast: forecast,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
        );

        // Cache result
        _cache[cacheKey] = weatherData;

        return weatherData;
      } else {
        throw WeatherException('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is WeatherException) rethrow;

      // Return fallback data on network error
      return getFallbackData(latitude, longitude, locationName);
    }
  }

  /// Fetch weather for a plantation location with rain alert check
  Future<RainAlertResult> checkRainAlert({
    required double latitude,
    required double longitude,
    String locationName = 'Kebun',
    double thresholdMm = 10.0,
  }) async {
    final weather = await fetchWeather(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    final isRainingNow = weather.current.isRaining;
    final heavyRainSoon = weather.heavyRainExpected();
    final maxPrecip = weather.forecast.take(3).fold<double>(
          0,
          (max, f) => f.precipitation > max ? f.precipitation : max,
        );

    return RainAlertResult(
      shouldAlert: isRainingNow || heavyRainSoon,
      isRainingNow: isRainingNow,
      heavyRainExpected: heavyRainSoon,
      maxPrecipitationMm: maxPrecip,
      locationName: locationName,
      weather: weather,
    );
  }

  /// Get fallback data when API is unreachable
  WeatherData getFallbackData(double lat, double lon, String name) {
    return WeatherData(
      current: CurrentWeather(
        temperature: 22.5,
        humidity: 78,
        precipitation: 0.0,
        rain: 0.0,
        weatherCode: 1,
        windSpeed: 5.2,
        fetchedAt: DateTime.now(),
      ),
      forecast: [],
      locationName: '$name (offline)',
      latitude: lat,
      longitude: lon,
    );
  }

  /// Clear the weather cache
  void clearCache() => _cache.clear();
}

/// Rain alert check result
class RainAlertResult {
  final bool shouldAlert;
  final bool isRainingNow;
  final bool heavyRainExpected;
  final double maxPrecipitationMm;
  final String locationName;
  final WeatherData weather;

  RainAlertResult({
    required this.shouldAlert,
    required this.isRainingNow,
    required this.heavyRainExpected,
    required this.maxPrecipitationMm,
    required this.locationName,
    required this.weather,
  });
}

/// Weather exception
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
