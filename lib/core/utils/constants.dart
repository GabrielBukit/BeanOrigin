class AppConstants {
  // App Info
  static const String appName = 'BeanOrigin';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Rantai Pasok & Verifikasi Ekspor Kopi Nusantara';

  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Gemini API
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-1.5-flash';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  // External APIs
  static const String frankfurterBaseUrl = 'https://api.frankfurter.app';
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // Currencies
  static const List<String> supportedCurrencies = ['IDR', 'USD', 'GBP', 'EUR'];

  // Time Zones
  static const Map<String, int> timeZoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  // Coffee Varieties
  static const List<String> coffeeVarieties = [
    'Arabika Gayo',
    'Arabika Toraja',
    'Arabika Kintamani',
    'Arabika Wamena',
    'Arabika Temanggung',
    'Arabika Flores',
    'Arabika Java',
    'Robusta Lampung',
    'Robusta Dampit',
    'Robusta Temanggung',
    'Liberika Meranti',
  ];

  // Coffee Origins
  static const List<String> coffeeOrigins = [
    'Aceh Tengah',
    'Aceh Barat',
    'Temanggung',
    'Toraja',
    'Kintamani',
    'Wamena',
    'Flores Bajawa',
    'Lampung',
    'Dampit Malang',
    'Garut',
    'Bandung',
  ];

  // Coffee Processes
  static const List<String> coffeeProcesses = [
    'Washed',
    'Natural',
    'Honey',
    'Semi-Washed',
    'Wet-Hulled (Giling Basah)',
    'Anaerobic',
  ];

  // Batch Status
  static const String statusPending = 'pending';
  static const String statusVerified = 'verified';
  static const String statusExported = 'exported';
  static const String statusSold = 'sold';

  // User Roles
  static const String roleFarmer = 'farmer';
  static const String roleQGrader = 'q_grader';
  static const String roleExporter = 'exporter';
  static const String roleAdmin = 'admin';

  // Sensor Thresholds
  static const double shockThresholdG = 2.0;
  static const double shakeThresholdG = 15.0;

  // London ICE Futures Europe
  static const int londonOpenHour = 10; // 10:00 London time
  static const int londonCloseHour = 18; // 18:00 London time

  // Hive Box Names
  static const String hiveBatchBox = 'batch_cache';
  static const String hiveBlockBox = 'blockchain_cache';
  static const String hiveUserBox = 'user_cache';
  static const String hiveSettingsBox = 'settings_cache';

  // Secure Storage Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyBiometricEnabled = 'biometric_enabled';
}
