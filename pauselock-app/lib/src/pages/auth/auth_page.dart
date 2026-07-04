import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/profile');
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> result;
      if (_isLogin) {
        result = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _error = 'Passwords do not match';
            _isLoading = false;
          });
          return;
        }
        result = await AuthService.register(
          _emailController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      if (result['error'] != null) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          context.go('/profile');
        }
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 400,
                decoration: AppTheme.glassDecoration,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'PAUSELOCK',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Sign in to your account' : 'Create an account',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.errorColor, fontSize: 13)),
                      ),
                    _buildTextField(
                        _emailController, 'Email', Icons.email, false),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                          _usernameController, 'Username', Icons.person, false),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField(
                        _passwordController, 'Password', Icons.lock, true),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      _buildTextField(_confirmPasswordController,
                          'Confirm Password', Icons.lock_outline, true),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(_isLogin ? 'Sign In' : 'Register',
                                style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Register"
                            : 'Already have an account? Sign in',
                        style: const TextStyle(color: AppTheme.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
