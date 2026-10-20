import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bean_origin/shared/models/user_model.dart';

// ─── Events ─────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
  @override
  List<Object?> get props => [name, email, password, role];
}

class AuthBiometricRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

// ─── States ─────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckAuth);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthBiometricRequested>(_onBiometricLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckAuth(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1500));
    // TODO: Check JWT token from flutter_secure_storage
    emit(AuthUnauthenticated());
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Replace with real Supabase auth
      // Simulasi login berhasil
      if (event.email.isNotEmpty && event.password.length >= 6) {
        final user = UserModel(
          id: 'user_001',
          email: event.email,
          name: event.email.split('@').first,
          role: 'farmer',
          createdAt: DateTime.now(),
        );
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Email atau password salah'));
      }
    } catch (e) {
      emit(AuthError('Login gagal: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Replace with real Supabase registration
      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: event.email,
        name: event.name,
        role: event.role,
        createdAt: DateTime.now(),
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Registrasi gagal: ${e.toString()}'));
    }
  }

  Future<void> _onBiometricLogin(AuthBiometricRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // TODO: Implement local_auth biometric + retrieve stored JWT
      await Future.delayed(const Duration(seconds: 1));
      emit(const AuthError('Biometric belum dikonfigurasi'));
    } catch (e) {
      emit(AuthError('Biometric gagal: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Clear JWT, clear Hive cache
    await Future.delayed(const Duration(milliseconds: 500));
    emit(AuthUnauthenticated());
  }
}
