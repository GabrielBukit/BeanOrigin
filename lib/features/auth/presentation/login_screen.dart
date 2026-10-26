import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo & Title
                        _buildHeader(),
                        const SizedBox(height: 32),

                        // Quick Demo Chips
                        _buildQuickDemoChips(),
                        const SizedBox(height: 20),

                        // Email Field
                        _buildEmailField(),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildPasswordField(),
                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login Button
                        _buildLoginButton(),
                        const SizedBox(height: 16),

                        // Biometric Login
                        _buildBiometricButton(),
                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.3))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.3))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        _buildRegisterButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Bean Icon
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('🫘', style: TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'BeanOrigin',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rantai Pasok Kopi Nusantara',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'contoh@email.com',
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.accent),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email wajib diisi';
        if (!value.contains('@')) return 'Email tidak valid';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accent),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textHint,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password wajib diisi';
        if (value.length < 6) return 'Password minimal 6 karakter';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                          AuthLoginRequested(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          ),
                        );
                  }
                },
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.bgDark,
                  ),
                )
              : const Text('Masuk'),
        );
      },
    );
  }

  Widget _buildBiometricButton() {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<AuthBloc>().add(AuthBiometricRequested());
      },
      icon: const Icon(Icons.fingerprint, size: 22),
      label: const Text('Login dengan Fingerprint'),
    );
  }

  Widget _buildRegisterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Belum punya akun? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            // Navigate to register
            Navigator.of(context).pushNamed('/register');
          },
          child: const Text(
            'Daftar Sekarang',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDemoChips() {
    final demos = [
      {'label': '🌱 Petani', 'email': 'demo@beanorigin.id', 'pass': 'password123'},
      {'label': '🔬 Q-Grader', 'email': 'qgrader@beanorigin.id', 'pass': 'password123'},
      {'label': '📦 Eksportir', 'email': 'exporter@beanorigin.id', 'pass': 'password123'},
      {'label': '👤 Admin', 'email': 'admin@beanorigin.id', 'pass': 'admin123'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akun Demo (1-Tap):',
          style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: demos.map((d) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: AppColors.bgSurface,
                  side: const BorderSide(color: Color(0xFF3D2E22)),
                  label: Text(d['label']!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  onPressed: () {
                    setState(() {
                      _emailController.text = d['email']!;
                      _passwordController.text = d['pass']!;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
