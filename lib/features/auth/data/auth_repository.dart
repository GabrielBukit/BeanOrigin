import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/shared/models/user_model.dart';

class AuthRepository {
  // Singleton
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // In-memory user store (simulates Supabase users table)
  final Map<String, Map<String, dynamic>> _usersDb = {
    'demo@beanorigin.id': {
      'id': 'user_001',
      'name': 'Ahmad Gayo',
      'email': 'demo@beanorigin.id',
      'role': 'farmer',
      'phone': '+6281234567890',
      'password_hash': _hashPasswordStatic('password123'),
      'created_at': '2026-01-15T10:00:00Z',
    },
    'qgrader@beanorigin.id': {
      'id': 'user_002',
      'name': 'Budi Toraja',
      'email': 'qgrader@beanorigin.id',
      'role': 'q_grader',
      'phone': '+6289876543210',
      'password_hash': _hashPasswordStatic('password123'),
      'created_at': '2026-02-20T08:30:00Z',
    },
    'exporter@beanorigin.id': {
      'id': 'user_003',
      'name': 'Charlie Eksportir',
      'email': 'exporter@beanorigin.id',
      'role': 'exporter',
      'phone': '+6281122334455',
      'password_hash': _hashPasswordStatic('password123'),
      'created_at': '2026-03-10T14:00:00Z',
    },
    'admin@beanorigin.id': {
      'id': 'user_004',
      'name': 'Admin BeanOrigin',
      'email': 'admin@beanorigin.id',
      'role': 'admin',
      'phone': '+6280000000000',
      'password_hash': _hashPasswordStatic('admin123'),
      'created_at': '2026-01-01T00:00:00Z',
    },
  };

  // ─── Password Hashing ────────────────────────────────────

  /// Hash password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String _hashPasswordStatic(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ─── JWT Token Generation (simulated) ────────────────────

  /// Generate a simulated JWT token
  /// In production, this would come from Supabase/server
  String _generateJwt(UserModel user) {
    final header = base64Url.encode(utf8.encode(jsonEncode({
      'alg': 'HS256',
      'typ': 'JWT',
    })));

    final now = DateTime.now().toUtc();
    final expiry = now.add(const Duration(hours: 3)); // Sesi aktif selama 3 jam
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': user.id,
      'email': user.email,
      'name': user.name,
      'role': user.role,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    })));

    // Simplified signature (in production, use server-side HMAC)
    final signatureInput = '$header.$payload';
    final signatureBytes = utf8.encode('${signatureInput}bean_origin_secret_key');
    final signature = base64Url.encode(sha256.convert(signatureBytes).bytes);

    return '$header.$payload.$signature';
  }

  // ─── Login ───────────────────────────────────────────────

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userData = _usersDb[normalizedEmail];

    if (userData == null) {
      throw AuthException('Akun tidak ditemukan');
    }

    final passwordHash = hashPassword(password);
    if (userData['password_hash'] != passwordHash) {
      throw AuthException('Password salah');
    }

    final user = UserModel(
      id: userData['id'] as String,
      email: userData['email'] as String,
      name: userData['name'] as String,
      role: userData['role'] as String,
      phone: userData['phone'] as String?,
      createdAt: DateTime.parse(userData['created_at'] as String),
    );

    // Generate and store JWT
    final jwt = _generateJwt(user);
    await _secureStorage.write(key: AppConstants.keyJwtToken, value: jwt);
    await _secureStorage.write(key: AppConstants.keyUserId, value: user.id);

    // Store user data for biometric re-login
    await _secureStorage.write(
      key: 'cached_user',
      value: jsonEncode(user.toJson()),
    );

    return user;
  }

  // ─── Register ────────────────────────────────────────────

  /// Register a new account
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_usersDb.containsKey(normalizedEmail)) {
      throw AuthException('Email sudah terdaftar');
    }

    if (password.length < 6) {
      throw AuthException('Password minimal 6 karakter');
    }

    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toUtc();
    final passwordHash = hashPassword(password);

    // Store in memory DB
    _usersDb[normalizedEmail] = {
      'id': userId,
      'name': name,
      'email': normalizedEmail,
      'role': role,
      'password_hash': passwordHash,
      'created_at': now.toIso8601String(),
    };

    final user = UserModel(
      id: userId,
      email: normalizedEmail,
      name: name,
      role: role,
      createdAt: now,
    );

    // Generate and store JWT
    final jwt = _generateJwt(user);
    await _secureStorage.write(key: AppConstants.keyJwtToken, value: jwt);
    await _secureStorage.write(key: AppConstants.keyUserId, value: userId);
    await _secureStorage.write(
      key: 'cached_user',
      value: jsonEncode(user.toJson()),
    );

    return user;
  }

  // ─── Biometric Login ─────────────────────────────────────

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Enable biometric login (store flag)
  Future<void> enableBiometric() async {
    await _secureStorage.write(
      key: AppConstants.keyBiometricEnabled,
      value: 'true',
    );
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  /// Authenticate using biometric (fingerprint/face)
  Future<UserModel> biometricLogin() async {
    // Check if biometric was previously enabled
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) {
      throw AuthException('Login biometric belum diaktifkan');
    }

    // Check for cached user
    final cachedUserJson = await _secureStorage.read(key: 'cached_user');
    if (cachedUserJson == null) {
      throw AuthException('Tidak ada sesi tersimpan. Silakan login manual.');
    }

    // Attempt biometric authentication
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke BeanOrigin',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) {
        throw AuthException('Autentikasi biometric gagal');
      }

      final userData = jsonDecode(cachedUserJson) as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      // Refresh JWT
      final jwt = _generateJwt(user);
      await _secureStorage.write(key: AppConstants.keyJwtToken, value: jwt);

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Biometric error: ${e.toString()}');
    }
  }

  // ─── Session Check ───────────────────────────────────────

  /// Check if user has a valid session (JWT not expired)
  Future<UserModel?> checkSession() async {
    try {
      final jwt = await _secureStorage.read(key: AppConstants.keyJwtToken).timeout(
            const Duration(seconds: 1),
            onTimeout: () => null,
          );
      if (jwt == null) return null;

      // Check JWT expiry
      if (JwtDecoder.isExpired(jwt)) {
        await logout();
        return null;
      }

      // Decode user from cached data
      final cachedUserJson = await _secureStorage.read(key: 'cached_user').timeout(
            const Duration(seconds: 1),
            onTimeout: () => null,
          );
      if (cachedUserJson != null) {
        final userData = jsonDecode(cachedUserJson) as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get current JWT token
  Future<String?> getToken() async {
    return _secureStorage.read(key: AppConstants.keyJwtToken);
  }

  // ─── Logout ──────────────────────────────────────────────

  /// Clear all session data
  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.keyJwtToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
    await _secureStorage.delete(key: AppConstants.keyUserId);
    // Keep 'cached_user' and 'biometric_enabled' for biometric re-login
  }

  /// Full logout (clear everything including biometric)
  Future<void> fullLogout() async {
    await _secureStorage.deleteAll();
  }
}

// ─── Custom Exception ────────────────────────────────────

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
