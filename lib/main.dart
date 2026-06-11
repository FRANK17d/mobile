import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo portrait — la app usa AdaptiveScaffold para tablets
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pre-calentar fuentes para evitar lag en primer frame del home
  GoogleFonts.poppins();
  GoogleFonts.inter();

  runApp(const ProviderScope(child: TokeApp()));
}
