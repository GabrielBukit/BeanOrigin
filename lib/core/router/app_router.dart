import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/auth/presentation/splash_screen.dart';
import 'package:bean_origin/features/auth/presentation/login_screen.dart';
import 'package:bean_origin/features/auth/presentation/register_screen.dart';
import 'package:bean_origin/shared/widgets/bottom_nav_shell.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/presentation/batch_list_screen.dart';
import 'package:bean_origin/features/batch/presentation/batch_detail_screen.dart';
import 'package:bean_origin/features/market/presentation/market_price_screen.dart';
import 'package:bean_origin/features/sensor/presentation/sensor_monitor_screen.dart';
import 'package:bean_origin/features/weather/presentation/weather_monitor_screen.dart';
import 'package:bean_origin/features/ai_scanner/presentation/ai_scanner_screen.dart';
import 'package:bean_origin/features/llm_advisor/presentation/llm_advisor_screen.dart';
import 'package:bean_origin/features/blockchain/presentation/blockchain_cert_screen.dart';
import 'package:bean_origin/features/maps/presentation/map_screen.dart';
import 'package:bean_origin/features/game/presentation/bean_sorter_game.dart';
import 'package:bean_origin/features/batch/presentation/add_batch_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String batchList = '/batch-list';
  static const String batchDetail = '/batch-detail';
  static const String addBatch = '/add-batch';
  static const String marketPrice = '/market-price';
  static const String sensorMonitor = '/sensor-monitor';
  static const String weatherMonitor = '/weather-monitor';
  static const String aiScanner = '/ai-scanner';
  static const String llmAdvisor = '/llm-advisor';
  static const String blockchainCert = '/blockchain-cert';
  static const String mapScreen = '/map';
  static const String miniGame = '/mini-game';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      case register:
        return _slideRoute(const RegisterScreen(), settings);
      case main:
        return _fadeRoute(const MainShell(), settings);
      case batchList:
        return _slideRoute(const BatchListScreen(), settings);
      case batchDetail:
        final batch = settings.arguments as BatchModel;
        return _slideRoute(BatchDetailScreen(batch: batch), settings);
      case addBatch:
        return _slideRoute(const AddBatchScreen(), settings);
      case marketPrice:
        return _slideRoute(const MarketPriceScreen(), settings);
      case sensorMonitor:
        return _slideRoute(const SensorMonitorScreen(), settings);
      case weatherMonitor:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          WeatherMonitorScreen(
            latitude: args?['latitude'] as double?,
            longitude: args?['longitude'] as double?,
            locationName: args?['locationName'] as String?,
          ),
          settings,
        );
      case aiScanner:
        return _slideRoute(const AiScannerScreen(), settings);
      case llmAdvisor:
        final batch = settings.arguments as BatchModel?;
        return _slideRoute(LlmAdvisorScreen(batch: batch), settings);
      case blockchainCert:
        final batch = settings.arguments as BatchModel;
        return _slideRoute(BlockchainCertScreen(batch: batch), settings);
      case mapScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          MapScreen(
            focusLat: args?['latitude'] as double?,
            focusLon: args?['longitude'] as double?,
          ),
          settings,
        );
      case miniGame:
        return _slideRoute(const BeanSorterGame(), settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

/// Listens to AuthBloc and navigates accordingly
class AuthNavigator extends StatelessWidget {
  final Widget child;
  const AuthNavigator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.main,
            (route) => false,
          );
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (route) => false,
          );
        }
      },
      child: child,
    );
  }
}
