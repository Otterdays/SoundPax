import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/screens/pad_screen.dart';
import 'package:soundpax/src/rust/frb_generated.dart';
import 'package:soundpax/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Tablet-friendly landscape default for pad grid
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SoundPaxApp(),
    ),
  );
}

class SoundPaxApp extends StatelessWidget {
  const SoundPaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundPax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const PadScreen(),
    );
  }
}
