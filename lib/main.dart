import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (requerido antes de usar FCM)
  await Firebase.initializeApp();

  // Inicializar push notifications (registra handler de background)
  await PushNotificationService.instance.init();

  // Solo portrait — la app usa AdaptiveScaffold para tablets
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pre-calentar fuentes para evitar lag en primer frame del home
  GoogleFonts.poppins();
  GoogleFonts.inter();

  runApp(const ProviderScope(child: TokeApp()));
}
