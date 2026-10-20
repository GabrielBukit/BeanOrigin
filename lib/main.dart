import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/router/app_router.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: MaterialApp(
        title: 'BeanOrigin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
        builder: (context, child) {
          return AuthNavigator(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
