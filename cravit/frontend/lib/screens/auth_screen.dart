import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _showOTP = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: AppTheme.nopeRed,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    Supabase.instance.client.auth.signInWithOtp(
      phone: formattedPhone,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOTP = true;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${error.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    });
  }

  void _verifyOTP() {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP code'),
          backgroundColor: AppTheme.nopeRed,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    final token = _otpController.text.trim();

    Supabase.instance.client.auth.verifyOTP(
      phone: formattedPhone,
      token: token,
      type: OtpType.sms,
    ).then((response) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verification failed: ${error.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    });
  }

  void _loginWithSocial(String provider) {
    setState(() {
      _isLoading = true;
    });

    // For frictionless testing without OAuth setups, login anonymously
    Supabase.instance.client.auth.signInAnonymously().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully logged in anonymously!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${error.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    });
  }

  void _resendOTP() {
    _sendOTP();
  }

  @override
  Widget build(BuildContext context) {
    // Custom Pin Input Theme definitions
    final defaultPinTheme = PinTheme(
      width: 44,
      height: 48,
      textStyle: TextStyle(fontSize: 18, color: AppTheme.textWhite, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppTheme.cardObsidianLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.primaryCoral, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppTheme.cardObsidian,
      ),
    );

    return Scaffold(
      body: Container(
        color: AppTheme.bgObsidian,
        child: Stack(
          children: [
            // Top Food Backdrop with blur
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/auth_background.png',
                    fit: BoxFit.cover,
                  ),
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.bgObsidian.withOpacity(0.5),
                          AppTheme.bgObsidian,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Ambient glow
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryPink.withOpacity(0.1),
                      blurRadius: 130,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    
                    // Brand / Logo info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cardObsidian,
                              border: Border.all(color: AppTheme.borderGray, width: 1),
                            ),
                            child: const Text('😋', style: TextStyle(fontSize: 36)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to Cravit',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find your next meal with your squad',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Auth Input Card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: !_showOTP
                          ? Card(
                              key: const ValueKey('phone-input-card'),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Log in or Sign up',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(color: AppTheme.textWhite),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.phone_iphone, color: AppTheme.textGray),
                                        hintText: 'Enter phone number',
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _sendOTP,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryCoral,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Continue with OTP'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Card(
                              key: const ValueKey('otp-verify-card'),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Row to go back
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: IconButton(
                                        icon: Icon(Icons.arrow_back, color: AppTheme.textGray, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _showOTP = false;
                                            _otpController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                    
                                    // Concentric Circle OTP Logo
                                    Center(
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryCoral.withOpacity(0.12),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primaryCoral.withOpacity(0.25),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.primaryCoral,
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'OTP',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    Center(
                                      child: Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        'Enter the 6-digit code sent to +91 ${_phoneController.text}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.textGray,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Pinput Widget for 6 digits
                                    Center(
                                      child: Pinput(
                                        controller: _otpController,
                                        length: 6,
                                        defaultPinTheme: defaultPinTheme,
                                        focusedPinTheme: focusedPinTheme,
                                        submittedPinTheme: submittedPinTheme,
                                        keyboardType: TextInputType.number,
                                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Resend Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Didn't receive code? ",
                                          style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: _resendOTP,
                                          child: const Text(
                                            'Resend OTP',
                                            style: TextStyle(
                                              color: AppTheme.primaryCoral,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _verifyOTP,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryCoral,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Verify OTP'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    
                    // Hide divider and social buttons if verifying OTP
                    if (!_showOTP) ...[
                      const SizedBox(height: 32),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.borderGray, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'or',
                              style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.borderGray, thickness: 1)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),

                      // Social buttons
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _loginWithSocial('Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textWhite,
                          side: BorderSide(color: AppTheme.borderGray, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _loginWithSocial('Apple'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textWhite,
                          side: BorderSide(color: AppTheme.borderGray, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(Icons.apple, size: 24, color: AppTheme.textWhite),
                        label: const Text(
                          'Continue with Apple',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
