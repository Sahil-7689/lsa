import 'package:flutter/material.dart';
import 'controllers/verification_controller.dart';
import 'screen/lsa_verification_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabotConnectApp());
}

/// Root application widget configuring Material 3 theme and routing to LsaVerificationScreen.
class HabotConnectApp extends StatelessWidget {
  const HabotConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate controller for the LSA verification flow
    final VerificationController controller = VerificationController();

    return MaterialApp(
      title: 'HabotConnect — LSA Verification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFF2DD4BF),
          surface: Colors.white,
          error: const Color(0xFFDC2626),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: LsaVerificationScreen(controller: controller),
    );
  }
}
