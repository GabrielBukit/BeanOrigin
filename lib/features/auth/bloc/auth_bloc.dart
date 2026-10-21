import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bean_origin/shared/models/user_model.dart';
import 'package:bean_origin/features/auth/data/auth_repository.dart';

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

class AuthEnableBiometric extends AuthEvent {}

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
  final AuthRepository _repository = AuthRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckAuth);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthBiometricRequested>(_onBiometricLogin);
    on<AuthEnableBiometric>(_onEnableBiometric);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckAuth(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final user = await _repository.checkSession();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Login gagal: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Registrasi gagal: ${e.toString()}'));
    }
  }

  Future<void> _onBiometricLogin(AuthBiometricRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isAvailable = await _repository.isBiometricAvailable();
      if (!isAvailable) {
        emit(const AuthError('Perangkat tidak mendukung autentikasi biometric'));
        return;
      }

      final user = await _repository.biometricLogin();
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Biometric gagal: ${e.toString()}'));
    }
  }

  Future<void> _onEnableBiometric(AuthEnableBiometric event, Emitter<AuthState> emit) async {
    try {
      final isAvailable = await _repository.isBiometricAvailable();
      if (!isAvailable) {
        // Silently fail — biometric not available
        return;
      }
      await _repository.enableBiometric();
    } catch (_) {
      // Non-critical, don't change state
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.logout();
    } catch (_) {
      // Continue with logout even if secure storage fails
    }
    emit(AuthUnauthenticated());
  }
}
