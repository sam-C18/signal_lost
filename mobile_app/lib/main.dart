import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/sos_active_screen.dart';
import 'screens/sos_confirmation_screen.dart';
import 'screens/settings_screen.dart';
import 'models/sos_message.dart';
import 'network/wifi_direct_manager.dart';
import 'network/ble_manager.dart';
import 'widgets/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize mesh networking in background
  _initializeMeshNetworking();

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

/// Start mesh networking (WiFi Direct + BLE) in background
Future<void> _initializeMeshNetworking() async {
  try {
    final wifiManager = WifiDirectManager();
    final bleManager = BleManager();

    // Start WiFi Direct advertising and discovery
    await wifiManager.startAdvertising(deviceName: 'SignalLost_Device');
    await wifiManager.startDiscovery();

    // Start BLE advertising and scanning
    await bleManager.startAdvertising(deviceName: 'SignalLost_Device');
    await bleManager.startScanning();

    print('[Main] Mesh networking initialized');
  } catch (e) {
    print('[Main] Mesh networking init error: $e');
  }
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
      onGenerateRoute: (settings) {
        if (settings.name == '/sos-confirm') {
          final message = settings.arguments as SosMessage;
          return MaterialPageRoute(
            builder: (context) => SosConfirmationScreen(message: message),
          );
        }
        return null;
      },
    );
  }
}
