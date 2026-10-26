import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/core/notifications/notification_service.dart';
import 'package:bean_origin/core/database/hive_service.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';
import 'package:bean_origin/features/weather/bloc/weather_bloc.dart';
import 'package:bean_origin/features/blockchain/data/blockchain_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Hive service (opens necessary boxes)
  await HiveService().initialize();

  // Initialize blockchain service (opens Hive box + loads chain)
  await BlockchainService().initialize();

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize Supabase if configured (offline-first fallback)
  if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL' && AppConstants.supabaseUrl.startsWith('http')) {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConstants.supabaseAnonKey,
      );
    } catch (_) {}
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BeanOriginApp());
}

class BeanOriginApp extends StatelessWidget {
  const BeanOriginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => BatchBloc()),
        BlocProvider(create: (_) => WeatherBloc()),
      ],
      child: MaterialApp(
        title: 'BeanOrigin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: AppRouter.navigatorKey,
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
        builder: (context, child) {
          return AuthNavigator(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
