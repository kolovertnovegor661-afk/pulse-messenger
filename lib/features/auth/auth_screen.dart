import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final s = ref.read(authServiceProvider);
      if (_isLogin) {
        await s.signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text);
      } else {
        final ok = await s.isUsernameAvailable(_userCtrl.text.trim());
        if (!ok) {
          setState(() { _error = 'Username already taken'; _isLoading = false; });
          return;
        }
        await s.signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            username: _userCtrl.text.trim().toLowerCase(),
            displayName: _nameCtrl.text.trim());
      }
      if (mounted) context.go('/');
    } catch (e) {
      setState(() { _error = _parseError(e.toString()); _isLoading = false; });
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result != null && mounted) context.go('/');
    } catch (e) {
      setState(() { _error = 'Google sign in failed'; _isLoading = false; });
    }
  }

  String _parseError(String e) {
    if (e.contains('user-not-found')) return 'No account with this email';
    if (e.contains('wrong-password')) return 'Wrong password';
    if (e.contains('email-already-in-use')) return 'Email already in use';
    if (e.contains('weak-password')) return 'Password too weak (min 6 chars)';
    if (e.contains('network-request-failed')) return 'No internet connection';
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Pulse', style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 26, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 48),
              Text(
                _isLogin ? 'Welcome back' : 'Create account',
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Sign in to continue' : 'Join Pulse today',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(children: [
                  if (!_isLogin) ...[
                    _field(_nameCtrl, 'Your name', Icons.person_outline_rounded,
                        validator: (v) => v!.isEmpty ? 'Enter your name' : null),
                    const SizedBox(height: 12),
                    _field(_userCtrl, 'Username', Icons.alternate_email_rounded,
                        validator: (v) {
                          if (v!.isEmpty) return 'Choose a username';
                          if (v.length < 3) return 'Min 3 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v))
                            return 'Only letters, numbers, underscores';
                          return null;
                        }),
                    const SizedBox(height: 12),
                  ],
                  _field(_emailCtrl, 'Email', Icons.mail_outline_rounded,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _field(_passCtrl, 'Password', Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textTertiary, size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Enter password';
                        if (!_isLogin && v.length < 6) return 'Min 6 characters';
                        return null;
                      }),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppColors.red, fontSize: 14))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmail,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Container(height: 0.5, color: AppColors.border)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ),
                Expanded(child: Container(height: 0.5, color: AppColors.border)),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: const Center(child: Text('G',
                          style: TextStyle(color: Color(0xFF4285F4),
                              fontSize: 14, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 12),
                    const Text('Continue with Google',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin ? "Don't have an account? " : 'Already have an account? ',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {
    TextInputType? type, bool obscure = false, Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}
