import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skrim/src/extensions/theme_extension.dart';
import 'package:skrim/src/features/auth/application/login_service.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/shared/app_background.dart';
import 'package:skrim/src/shared/google_logo.dart';
import 'package:skrim/src/shared/responsive_layout.dart';
import 'package:skrim/src/shared/sport_glass_decoration.dart';
import 'package:skrim/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLogin = true;
  String? _loadingAction;
  bool _acceptedTerms = true;
  bool _obscurePassword = true;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _redirectIfAlreadySignedIn() {
    if (ref.read(loginServiceProvider).isSignedIn) {
      if (mounted) context.go(_initialAppRoute());
    }
  }

  Future<void> _submit() async {
    if (_loadingAction != null) return;
    final loginService = ref.read(loginServiceProvider);
    if (!_formKey.currentState!.validate()) return;
    if (loginService.requiresAcceptedTerms(
      isLogin: _isLogin,
      acceptedTerms: _acceptedTerms,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginService.termsRequiredMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _loadingAction = 'email';
    });

    try {
      await loginService.submitWithEmail(
        isLogin: _isLogin,
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (mounted) {
        context.go(_initialAppRoute());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginService.errorMessage(e, isGoogle: false)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAction = null;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    if (_loadingAction != null) return;
    setState(() {
      _loadingAction = 'google';
    });

    final loginService = ref.read(loginServiceProvider);
    try {
      await loginService.submitWithGoogle();
      if (mounted) {
        context.go(_initialAppRoute());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginService.errorMessage(e, isGoogle: true)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final loginService = ref.read(loginServiceProvider);

    return SystemOverlayStyleWrapper(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.25,
              colors: AppColors.sportBackgroundGradient(context),
              stops: const [0, 0.46, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, viewport) {
              final cardHeight = viewport.maxHeight - 48;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cardHeight),
                  child: SportGlassDecoration(
                    radius: 16,
                    blurRadius: 44,
                    gradient: LinearGradient(
                      colors: [colors.loginPanel, colors.loginPanel],
                    ),
                    child: SizedBox(
                      height: cardHeight,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 760;
                          final authStep = Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 70 : 24,
                              vertical: isWide ? 36 : 24,
                            ),
                            child: _AuthStep(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              isLogin: _isLogin,
                              isBusy: _loadingAction != null,
                              isEmailLoading: _loadingAction == 'email',
                              isGoogleLoading: _loadingAction == 'google',
                              acceptedTerms: _acceptedTerms,
                              obscurePassword: _obscurePassword,
                              onSubmit: _submit,
                              onGoogle: _submitGoogle,
                              onToggleMode: () =>
                                  setState(() => _isLogin = !_isLogin),
                              onToggleTerms: (value) => setState(
                                () => _acceptedTerms = value ?? false,
                              ),
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              loginService: loginService,
                              textTheme: textTheme,
                            ),
                          );

                          if (!isWide) return authStep;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: _LoginShowcase(),
                                ),
                              ),
                              Expanded(child: authStep),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _initialAppRoute() {
    return ResponsiveLayout.isWide(context)
        ? AppRoutes.dashboard
        : AppRoutes.ranking;
  }
}

class _LoginShowcase extends StatefulWidget {
  const _LoginShowcase();

  @override
  State<_LoginShowcase> createState() => _LoginShowcaseState();
}

class _LoginShowcaseState extends State<_LoginShowcase> {
  static const _slides = [
    'https://images.unsplash.com/photo-1585953074857-19f89c2ed52f?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://images.unsplash.com/photo-1584846884362-e1ea3d18e53f?q=80&w=2071&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://images.unsplash.com/photo-1715801903028-aaf7e1c526e0?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ];

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _showSlide((_page + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showSlide(int page) {
    if (!mounted || !_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                if (slide.startsWith('http')) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          colors.mutedForeground,
                          BlendMode.saturation,
                        ),
                        child: Image.network(slide, fit: BoxFit.cover),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _showcaseGradient(context),
                        ),
                      ),
                    ],
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(slide, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _showcaseGradient(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.transparent,
                    colors.sportBackgroundMid.withValues(alpha: 0.34),
                    colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: _ShowcaseArrow(
                icon: Icons.chevron_left,
                onPressed: () =>
                    _showSlide((_page - 1 + _slides.length) % _slides.length),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: _ShowcaseArrow(
                icon: Icons.chevron_right,
                onPressed: () => _showSlide((_page + 1) % _slides.length),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 36,
                children: [
                  Text(
                    'SKRIM',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.onColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Cattura i momenti,\ncrea la memoria',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.onColor,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => _showSlide(index),
                          child: _ShowcaseDot(active: index == _page),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient _showcaseGradient(BuildContext context) {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: AppColors.sportBackgroundTransparentGradient(context),
      stops: const [0, 0.46, 1],
    );
  }
}

class _ShowcaseArrow extends StatelessWidget {
  const _ShowcaseArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon),
        color: colors.onColor,
        style: IconButton.styleFrom(
          backgroundColor: colors.shadow.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}

class _ShowcaseDot extends StatelessWidget {
  const _ShowcaseDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 48 : 36,
      height: 4,
      decoration: BoxDecoration(
        color: active ? colors.violet : colors.onColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.firstNameController,
    required this.lastNameController,
    required this.isLogin,
    required this.isBusy,
    required this.isEmailLoading,
    required this.isGoogleLoading,
    required this.acceptedTerms,
    required this.obscurePassword,
    required this.onSubmit,
    required this.onGoogle,
    required this.onToggleMode,
    required this.onToggleTerms,
    required this.onTogglePassword,
    required this.loginService,
    required this.textTheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isLogin;
  final bool isBusy;
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final bool acceptedTerms;
  final bool obscurePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onToggleMode;
  final ValueChanged<bool?> onToggleTerms;
  final VoidCallback onTogglePassword;
  final LoginService loginService;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoginTitle(
                      textTheme: textTheme,
                      isLogin: isLogin,
                      onToggleMode: onToggleMode,
                    ),
                    if (!isLogin)
                      Row(
                        spacing: 14,
                        children: [
                          Expanded(
                            child: _LoginField(
                              controller: firstNameController,
                              hint: 'Fletcher',
                              textCapitalization: TextCapitalization.words,
                              validator: loginService.validateFirstName,
                            ),
                          ),
                          Expanded(
                            child: _LoginField(
                              controller: lastNameController,
                              hint: 'Cognome',
                              textCapitalization: TextCapitalization.words,
                              validator: loginService.validateLastName,
                            ),
                          ),
                        ],
                      ),
                    _LoginField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'Email',
                      validator: loginService.validateEmail,
                    ),
                    _LoginField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      hint: 'Inserisci la password',
                      suffix: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.sportMutedText,
                          size: 20,
                        ),
                      ),
                      validator: (value) => loginService.validatePassword(
                        value,
                        isLogin: isLogin,
                      ),
                    ),
                    if (!isLogin)
                      _TermsRow(
                        value: acceptedTerms,
                        onChanged: onToggleTerms,
                        textTheme: textTheme,
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: isBusy ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.violetMid,
                          foregroundColor: colors.onColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: isEmailLoading
                            ? SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: colors.onColor,
                                ),
                              )
                            : Text(isLogin ? 'Accedi' : 'Crea account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SocialDivider(
                      label: isLogin
                          ? 'Oppure accedi con'
                          : 'Oppure registrati con',
                    ),
                    const SizedBox(height: 4),
                    _SocialButton(
                      label: 'Accedi con Google',
                      icon: GoogleLogo(size: 16),
                      isLoading: isGoogleLoading,
                      onPressed: isBusy ? null : onGoogle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginTitle extends StatelessWidget {
  const _LoginTitle({
    required this.textTheme,
    required this.isLogin,
    required this.onToggleMode,
  });

  final TextTheme textTheme;
  final bool isLogin;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLogin ? 'Accedi' : 'Crea un account',
          style: textTheme.displaySmall?.copyWith(
            color: colors.onColor,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(
              isLogin ? 'Non hai un account?' : 'Hai già un account?',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.sportMutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: onToggleMode,
              child: Text(
                isLogin ? 'Crea un account' : 'Accedi',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.violetLight,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.violetLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(color: colors.onColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        constraints: const BoxConstraints(minHeight: 48),
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.onColor.withValues(alpha: 0.36),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: colors.loginField,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        suffixIcon: suffix,
        border: _fieldBorder(colors.transparent),
        enabledBorder: _fieldBorder(colors.transparent),
        focusedBorder: _fieldBorder(colors.violetLight),
        errorBorder: _fieldBorder(colors.danger),
        focusedErrorBorder: _fieldBorder(colors.danger),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: color, width: 1.4),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.value,
    required this.onChanged,
    required this.textTheme,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      spacing: 16,
      children: [
        SizedBox.square(
          dimension: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: colors.onColor,
            checkColor: colors.shadow,
            side: BorderSide(color: colors.onColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Accetto i ',
              children: [
                TextSpan(
                  text: 'Termini e condizioni',
                  style: TextStyle(
                    color: colors.violetLight,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.violetLight,
                  ),
                ),
              ],
            ),
            style: textTheme.bodySmall?.copyWith(
              color: colors.onColor.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.loginDivider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label,
            style: TextStyle(
              color: colors.onColor.withValues(alpha: 0.42),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.loginDivider)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onPressed,
  });

  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.onColor,
                ),
              )
            : icon,
        label: Text(
          isLoading ? 'Accesso...' : label,
          style: context.textTheme.bodyMedium?.copyWith(color: colors.onColor),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onColor,
          side: BorderSide(color: colors.loginOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
