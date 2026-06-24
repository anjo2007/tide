import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/providers/auth_provider.dart';
import 'package:tide/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        auth.signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Circles for Premium Light Ambient Style
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldLight.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.infoBlue.withOpacity(0.15),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                width: isDesktop ? 450 : size.width * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: AppTheme.creamCard.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.premiumShadow,
                  border: Border.all(
                    color: const Color(0xFFECE7DF),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppTheme.goldLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.waves_rounded,
                          size: 36,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Brand Header
                    Text(
                      'Tide',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Organize like the gentle tides',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Mock Mode Option Slider Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECE7DF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline / Mock Mode',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontSize: 13,
                                        color: AppTheme.textDark,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  auth.isMockMode 
                                      ? 'Active - in-memory data' 
                                      : 'Inactive - connects to Firebase',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: auth.isMockMode,
                            activeColor: AppTheme.goldAccent,
                            activeTrackColor: AppTheme.goldLight,
                            onChanged: (val) {
                              auth.setMockMode(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle Auth Tabs
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLogin = true),
                            child: Column(
                              children: [
                                Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: _isLogin ? AppTheme.textDark : AppTheme.textMuted,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 3,
                                  color: _isLogin ? AppTheme.goldAccent : Colors.transparent,
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLogin = false),
                            child: Column(
                              children: [
                                Text(
                                  'Register',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: !_isLogin ? AppTheme.textDark : AppTheme.textMuted,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 3,
                                  color: !_isLogin ? AppTheme.goldAccent : Colors.transparent,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Form Fields
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your name',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'yourname@example.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.textMuted),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dangerRose.withOpacity(0.3)),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: Color(0xFFC05A5A), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(_isLogin ? 'Sign In' : 'Create Account'),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFECE7DF))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFECE7DF))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In Button
                    OutlinedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              auth.signInWithGoogle();
                            },
                      style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.white),
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red, width: 1.5),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Continue with Google'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
