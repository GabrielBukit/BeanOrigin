import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bean_origin/features/weather/data/weather_service.dart';

// ─── Events ────────────────────────────────────────────────

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  @override
  List<Object?> get props => [];
}

class WeatherFetchRequested extends WeatherEvent {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool forceRefresh;

  const WeatherFetchRequested({
    required this.latitude,
    required this.longitude,
    this.locationName = 'Unknown',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [latitude, longitude, locationName, forceRefresh];
}

class WeatherCheckRainAlert extends WeatherEvent {
  final double latitude;
  final double longitude;
  final String locationName;

  const WeatherCheckRainAlert({
    required this.latitude,
    required this.longitude,
    this.locationName = 'Kebun',
  });

  @override
  List<Object?> get props => [latitude, longitude, locationName];
}

// ─── States ────────────────────────────────────────────────

abstract class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherData weatherData;
  final RainAlertResult? rainAlert;

  const WeatherLoaded({
    required this.weatherData,
    this.rainAlert,
  });

  @override
  List<Object?> get props => [weatherData, rainAlert];
}

class WeatherError extends WeatherState {
  final String message;
  final WeatherData? fallbackData;

  const WeatherError(this.message, {this.fallbackData});

  @override
  List<Object?> get props => [message, fallbackData];
}

// ─── Bloc ──────────────────────────────────────────────────

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService _weatherService = WeatherService();

  WeatherBloc() : super(WeatherInitial()) {
    on<WeatherFetchRequested>(_onFetchWeather);
    on<WeatherCheckRainAlert>(_onCheckRainAlert);
  }

  Future<void> _onFetchWeather(
    WeatherFetchRequested event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());
    try {
      final weatherData = await _weatherService.fetchWeather(
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: event.locationName,
        forceRefresh: event.forceRefresh,
      );

      // Also check rain alert
      final rainAlert = await _weatherService.checkRainAlert(
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: event.locationName,
      );

      emit(WeatherLoaded(
        weatherData: weatherData,
        rainAlert: rainAlert,
      ));
    } catch (e) {
      emit(WeatherError(
        'Gagal memuat cuaca: $e',
        fallbackData: _weatherService.getFallbackData(
          event.latitude,
          event.longitude,
          event.locationName,
        ),
      ));
    }
  }

  Future<void> _onCheckRainAlert(
    WeatherCheckRainAlert event,
    Emitter<WeatherState> emit,
  ) async {
    try {
      final rainAlert = await _weatherService.checkRainAlert(
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: event.locationName,
      );

      if (state is WeatherLoaded) {
        emit(WeatherLoaded(
          weatherData: (state as WeatherLoaded).weatherData,
          rainAlert: rainAlert,
        ));
      } else {
        emit(WeatherLoaded(
          weatherData: rainAlert.weather,
          rainAlert: rainAlert,
        ));
      }
    } catch (e) {
      // Don't override loaded state on rain alert check failure
      if (state is! WeatherLoaded) {
        emit(WeatherError('Gagal cek peringatan hujan: $e'));
      }
    }
  }
}
