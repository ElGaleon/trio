import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/components/shared/sport_glass_decoration.dart';
import 'package:trio/providers/auth_provider.dart';
import 'package:trio/theme/app_colors.dart';

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Si è verificato un errore';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('user-not-found') || errorStr.contains('invalid-credential')) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accesso con Google fallito o annullato: $e'),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Title / Logo
                          Column(
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
                                _isLogin
                                    ? 'Accedi per tracciare le statistiche'
                                    : 'Crea un account per iniziare',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.sportMutedText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Email Field
                          FTextFormField(
                            control: FTextFieldControl.managed(
                              controller: _emailController,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            hint: 'Email',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Inserisci l\'email';
                              }
                              return null;
                            },
                          ),
                          // Password Field
                          FTextFormField(
                            control: FTextFieldControl.managed(
                              controller: _passwordController,
                            ),
                            obscureText: true,
                            hint: 'Password',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Inserisci la password';
                              }
                              if (!_isLogin && val.length < 6) {
                                return 'La password deve avere almeno 6 caratteri';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          // Submit Button
                          FButton(
                            onPress: _isLoading ? null : _submit,
                            child: Text(_isLogin ? 'Accedi' : 'Registrati'),
                          ),
                          // Google Login Button
                          FButton(
                            variant: .outline,
                            onPress: _isLoading ? null : _submitGoogle,
                            child: const Text('Accedi con Google'),
                          ),
                          // View Switcher
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
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
