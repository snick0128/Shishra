import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:shishra/globals/app_state.dart';
import 'package:shishra/pages/main_navigation.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shishra/pages/onboarding_page.dart';
import 'package:shishra/main.dart';
import 'dart:developer' as developer;
import 'package:shishra/firestore_service.dart';
import 'package:shishra/pages/registration_page.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isResendingOtp = false;
  int _resendTimer = 30;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
    _otpFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        return true;
      }
      return false;
    });
  }

  void _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResendingOtp = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${widget.phoneNumber}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification logic if needed
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          _showErrorSnackBar(e.message ?? 'Failed to resend OTP');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendTimer = 30;
          });
          _startResendTimer();
          _showSuccessSnackBar('OTP resent successfully!');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to resend OTP');
    } finally {
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
      }
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      _showErrorSnackBar('Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      await AppState.of(context, listen: false).login(
          userCredential.user!.uid,
          widget.phoneNumber,
          userCredential.user!.displayName ?? 'Jewelry Lover');
      await _handlePostLogin(userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(e.message ?? 'Invalid OTP');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Something went wrong');
      }
    }
  }

  Future<void> _handlePostLogin(User? user) async {
    if (!mounted) return;

    try {
      if (user != null) {
        final firestoreService = FirestoreService();
        final userExists = await firestoreService.userExists(user.uid);

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (userExists) {
              final hasOnboarded =
                  sharedPrefs.getBool('onboarded_${user.uid}') ?? false;
              if (!hasOnboarded) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const OnboardingPage()),
                  (route) => false,
                );
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const MainNavigation()),
                  (route) => false,
                );
              }
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => RegistrationPage(
                    uid: user.uid,
                    phoneNumber: user.phoneNumber ?? '+91${widget.phoneNumber}',
                  ),
                ),
                (route) => false,
              );
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to check user existence.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    ).show(context);
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Phone Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "We need to register your phone without getting started!",
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 30,
              ),
              Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                controller: _otpController,
                focusNode: _otpFocusNode,
                onCompleted: (pin) => _verifyOtp(),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "Verify Phone Number",
                            style: TextStyle(color: Colors.white),
                          )),
              ),
              Row(
                children: [
                  TextButton(
                      onPressed: _resendTimer > 0 ? null : _resendOtp,
                      child: Text(
                        _resendTimer > 0
                            ? "Resend OTP in $_resendTimer s"
                            : "Resend OTP",
                        style: const TextStyle(color: Colors.black),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}