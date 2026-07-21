import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/shared/sport_glass_decoration.dart';
import 'package:trio/src/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfAlreadySignedIn();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _redirectIfAlreadySignedIn() {
    final authService = ref.read(authServiceProvider);
    if (authService.currentUser != null) {
      if (mounted) context.go(AppRoutes.ranking);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        await authService.registerWithEmail(email, password);
      }
      await authService.waitForSignedIn();
      if (mounted) {
        context.go(AppRoutes.ranking);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Si è verificato un errore';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('configuration-not-found')) {
          errorMessage =
              'Firebase Auth non è configurato: abilita Email/Password e Google nella console Firebase.';
        } else if (errorStr.contains('user-not-found') ||
            errorStr.contains('invalid-credential')) {
          errorMessage = 'Credenziali non valide';
        } else if (errorStr.contains('wrong-password')) {
          errorMessage = 'Password errata';
        } else if (errorStr.contains('email-already-in-use')) {
          errorMessage = 'Email già in uso';
        } else if (errorStr.contains('weak-password')) {
          errorMessage = 'La password deve avere almeno 6 caratteri';
        } else if (errorStr.contains('invalid-email')) {
          errorMessage = 'Email non valida';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithGoogle();
      await authService.waitForSignedIn();
      if (mounted) {
        context.go(AppRoutes.ranking);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final message = errorStr.contains('configuration-not-found')
            ? 'Firebase Auth non è configurato: abilita Google nella console Firebase.'
            : 'Accesso con Google fallito o annullato: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.appDarkBackground,
                  AppColors.appDarkSurface,
                  AppColors.appDarkElevated,
                ],
              ),
            ),
          ),
          // Background glowing circles for glassmorphism
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violetHover.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SportGlassDecoration(
                  radius: 28,
                  blurRadius: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _AuthStep(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLogin: _isLogin,
                      isLoading: _isLoading,
                      onSubmit: _submit,
                      onGoogle: _submitGoogle,
                      onToggleMode: () => setState(() => _isLogin = !_isLogin),
                      textTheme: textTheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLogin,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogle,
    required this.onToggleMode,
    required this.textTheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLogin;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onToggleMode;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginTitle(
            textTheme: textTheme,
            subtitle: isLogin
                ? 'Accedi per tracciare le statistiche'
                : 'Crea un account per iniziare',
          ),
          const SizedBox(height: 8),
          FTextFormField(
            control: FTextFieldControl.managed(controller: emailController),
            keyboardType: TextInputType.emailAddress,
            hint: 'Email',
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Inserisci l\'email';
              }
              return null;
            },
          ),
          FTextFormField(
            control: FTextFieldControl.managed(controller: passwordController),
            obscureText: true,
            hint: 'Password',
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Inserisci la password';
              }
              if (!isLogin && val.length < 6) {
                return 'La password deve avere almeno 6 caratteri';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          FButton(
            onPress: isLoading ? null : onSubmit,
            child: Text(isLogin ? 'Accedi' : 'Registrati'),
          ),
          FButton(
            variant: .outline,
            onPress: isLoading ? null : onGoogle,
            child: const Text('Accedi con Google'),
          ),
          TextButton(
            onPressed: onToggleMode,
            child: Text(
              isLogin
                  ? 'Non hai un account? Registrati'
                  : 'Hai già un account? Accedi',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTitle extends StatelessWidget {
  const _LoginTitle({required this.textTheme, required this.subtitle});

  final TextTheme textTheme;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        Text(
          'TRIO',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.sportMutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
