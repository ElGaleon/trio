import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'src/app.dart';
import 'src/firebase/firebase_bootstrap.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseBootstrapGate());
}

class FirebaseBootstrapGate extends StatefulWidget {
  const FirebaseBootstrapGate({super.key});

  @override
  State<FirebaseBootstrapGate> createState() => _FirebaseBootstrapGateState();
}

class _FirebaseBootstrapGateState extends State<FirebaseBootstrapGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await FirebaseBootstrap.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'firebase bootstrap',
        ),
      );
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) return FirebaseStartupErrorApp(error: error);
    if (_ready) return const ProviderScope(child: ScrimApp());
    return StartupLoadingApp(animation: _controller);
  }
}

class StartupLoadingApp extends StatelessWidget {
  const StartupLoadingApp({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const palette = AppColorPalette.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],

      home: Scaffold(
        backgroundColor: palette.bootstrapBackground,
        body: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.04).animate(animation),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TRIO',
                    style: TextStyle(
                      color: palette.onColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  SizedBox(height: 18),
                  SizedBox(
                    width: 42,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: palette.violetLight,
                      backgroundColor: palette.loginPanel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    const palette = AppColorPalette.dark;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: palette.bootstrapBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase non disponibile',
                    style: TextStyle(
                      color: palette.onColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Safari non riesce a inizializzare Firebase. Controlla la console del browser, eventuali content blocker e che www.gstatic.com non sia bloccato.',
                    style: TextStyle(
                      color: palette.bootstrapMutedText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    error.toString(),
                    style: TextStyle(color: palette.bootstrapWarning),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
