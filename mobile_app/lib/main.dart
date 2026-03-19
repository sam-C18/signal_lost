import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/sos_active_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for emergency usability
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SignalLostApp());
}

class SignalLostApp extends StatelessWidget {
  const SignalLostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignalLost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Named routes for clean navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/sos-active': (context) => const SosActiveScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
