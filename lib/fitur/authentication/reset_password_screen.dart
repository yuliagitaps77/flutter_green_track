import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class ResetPasswordScreen extends StatefulWidget {
  static String? routeName = "/routeName";
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  // Gunakan satu controller saja untuk menghindari kebingungan
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();
  final TextEditingController _emailController = TextEditingController();

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the email field if available in the auth controller
    if (_authController.emailController.text.isNotEmpty) {
      _emailController.text = _authController.emailController.text;
    } else if (_authController.currentUser.value != null) {
      _emailController.text = _authController.currentUser.value!.email;
    }

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
  }

  @override
  void dispose() {
    _backgroundAnimController.dispose();
    _formAnimController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _success = false;
    });

    try {
      // Validate email
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        throw Exception('Email tidak boleh kosong');
      }

      if (!GetUtils.isEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      // Send reset password email
      await _authController.resetPassword(email);

      setState(() {
        _isLoading = false;
        _success = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // Tampilkan error di UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage?.replaceAll('Exception: ', '') ??
              'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
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
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.08),

                        // App logo
                        _buildAppLogo(),

                        SizedBox(height: 30),

                        // Welcome text
                        Text(
                          "Ubah Kata Sandi",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        // Welcome text
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Masukan alamat email anda untuk menerima tautan reset password",
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 50),

                        // Login form
                        if (!_success) _buildLoginForm(),
                        if (_success)
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 60,
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Tautan Reset Terkirim!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Silakan periksa email Anda untuk tautan reset password. Jika tidak menemukannya, periksa folder spam.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              TextButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Kirim Ulang'),
                                onPressed: () {
                                  setState(() {
                                    _success = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        Spacer(),

                        SizedBox(height: 20),
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
        // Animated circles
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

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field with animation
        Container(
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
            controller:
                _emailController, // PERBAIKAN: Gunakan _emailController daripada controller.emailController
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Email",
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Color(0xFF4CAF50),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Error message (if any)
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!.replaceAll('Exception: ', ''),
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),

        SizedBox(height: 30),

        // Login button with animation
        GestureDetector(
            onTap: _isLoading
                ? null
                : _sendResetLink, // Pastikan ini tidak kosong saat loading
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Center(
                      child: Text(
                        'Kirim Tautan Reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ))
      ],
    );
  }
}
