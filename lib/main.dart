import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/setting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wstdtpzjbvlvwquftdab.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzdGR0cHpqYnZsdndxdWZ0ZGFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzOTUyODYsImV4cCI6MjA5NTk3MTI4Nn0.LAN2TVnuCRnetL5mqpaSuU-v9tGGvVOGdKz2gYuyK6I',
  );

  runApp(const EduScanApp());
}

class EduScanApp extends StatelessWidget {
  const EduScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduScan',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0055E5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0055E5)),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':   (_) => const SplashScreen(),
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const HomeScreen(),
        '/scanner':  (_) => const ScannerScreen(),
        '/admin':    (_) => const AdminScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}