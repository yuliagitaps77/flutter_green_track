import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';

class OtpVerificationScreen extends StatefulWidget {
  static String? routeName = "/PageOtpVerification";
  final String email;

  const OtpVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;
  final RxBool isVerifying = false.obs;
  final RxInt resendCounter = 60.obs;
  late RxString otpErrorMessage = ''.obs;

  @override
  void initState() {
    super.initState();

    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..repeat();

    _formAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _formAnimation = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutQuint,
    );

    _formAnimController.forward();

    // Start the countdown for OTP resend
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (resendCounter.value > 0) {
        resendCounter.value--;
        _startResendTimer();
      }
    });
  }

  void _resetOtpFields() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(focusNodes[0]);
    otpErrorMessage.value = '';
  }

  String _getOtpCode() {
    return otpControllers.map((controller) => controller.text).join();
  }

  void _verifyOtp() {
    final otpCode = _getOtpCode();

    if (otpCode.length != 4) {
      otpErrorMessage.value = 'Masukkan 4 digit kode OTP';
      return;
    }

    isVerifying.value = true;

    // Simulate verification process
    Future.delayed(Duration(seconds: 2), () {
      isVerifying.value = false;

      // For demo purposes, any code works as valid
      // In a real app, you'd verify this against a backend
      Get.off(() => MainNavigationContainer(
            userRole: widget.email.contains('penyemaian')
                ? UserRole.adminPenyemaian
                : UserRole.adminTPK,
          ));
    });
  }

  @override
  void dispose() {
    _backgroundAnimController.dispose();
    _formAnimController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background (same as login page)
          AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white,
                      Color(0xFFE8F5E9),
                      Color(0xFFC8E6C9),
                    ],
                    stops: [
                      0,
                      0.5 +
                          0.1 *
                              math.sin(_backgroundAnimController.value *
                                  2 *
                                  math.pi),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Background decorative elements
          _buildBackgroundDecorations(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                child: AnimatedBuilder(
                  animation: _formAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _formAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _formAnimation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 20),

                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Color(0xFF4CAF50)),
                            onPressed: () => Get.back(),
                          ),
                        ),

                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),

                        // App logo
                        _buildAppLogo(),

                        SizedBox(height: 30),

                        // Title
                        Text(
                          "Verifikasi OTP",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),

                        SizedBox(height: 10),

                        Text(
                          "Masukkan kode 4 digit yang telah dikirim ke\n${widget.email}",
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 50),

                        // OTP input
                        _buildOtpForm(),

                        SizedBox(height: 15),

                        // Error message
                        Obx(() => otpErrorMessage.value.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  otpErrorMessage.value,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : SizedBox.shrink()),

                        SizedBox(height: 20),

                        // Verify button
                        _buildVerifyButton(),

                        SizedBox(height: 30),

                        // Resend code option
                        _buildResendOption(),

                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Animated circles (same as login page)
        Positioned(
          top: -80,
          right: -40,
          child: AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  15 * math.sin(_backgroundAnimController.value * 2 * math.pi),
                  10 * math.cos(_backgroundAnimController.value * 2 * math.pi),
                ),
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF81C784).withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.4,
          left: -60,
          child: AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  10 * math.cos(_backgroundAnimController.value * 2 * math.pi),
                  15 * math.sin(_backgroundAnimController.value * 2 * math.pi),
                ),
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF66BB6A).withOpacity(0.15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppLogo() {
    return Container(
      height: 100,
      width: 100,
      child: Center(
        child: Image.asset(
          "assets/icon/ic_app.png",
          width: 120,
        ),
      ),
    );
  }

  Widget _buildOtpForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        4,
        (index) => _buildOtpDigitField(index),
      ),
    );
  }

  Widget _buildOtpDigitField(int index) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        onChanged: (value) {
          if (value.length == 1) {
            // Move to next field
            if (index < 3) {
              FocusScope.of(context).requestFocus(focusNodes[index + 1]);
            } else {
              // Last field, hide keyboard
              FocusScope.of(context).unfocus();
            }
          }
          // Clear error message when user is typing
          if (otpErrorMessage.value.isNotEmpty) {
            otpErrorMessage.value = '';
          }
        },
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(() => GestureDetector(
          onTap: isVerifying.value ? null : _verifyOtp,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF4CAF50),
                  Color(0xFF388E3C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: isVerifying.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "VERIFIKASI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ));
  }

  Widget _buildResendOption() {
    return Column(
      children: [
        Text(
          "Belum menerima kode?",
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 5),
        Obx(() => TextButton(
              onPressed: resendCounter.value > 0
                  ? null
                  : () {
                      // Reset counter and show message
                      resendCounter.value = 60;
                      _startResendTimer();
                      _resetOtpFields();
                      Get.snackbar(
                        "Kode Dikirim Ulang",
                        "Silakan cek email Anda untuk kode OTP baru",
                        backgroundColor: Color(0xFF4CAF50).withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: EdgeInsets.all(15),
                        borderRadius: 10,
                        duration: Duration(seconds: 3),
                      );
                    },
              child: Text(
                resendCounter.value > 0
                    ? "Kirim Ulang Kode (${resendCounter.value}s)"
                    : "Kirim Ulang Kode",
                style: TextStyle(
                  color: resendCounter.value > 0
                      ? Color(0xFF9E9E9E)
                      : Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
      ],
    );
  }
}
