import 'package:flutter/material.dart';
import 'package:flutter_green_track/admin_generator.dart';
import 'package:get/get.dart';
import '../../controllers/authentication/authentication_controller.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  static String? routeName = "/PageLogin";
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Get reference to the authentication controller
  final AuthenticationController controller =
      Get.put(AuthenticationController());

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;

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
  }

  @override
  void dispose() {
    _backgroundAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
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
                        GestureDetector(
                            onTap: () {
                              Get.to(AdminAccountCreatorScreen());
                            },
                            child: _buildAppLogo()),

                        SizedBox(height: 30),

                        // Welcome text
                        Text(
                          "Selamat Datang",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),

                        SizedBox(height: 10),

                        Text(
                          "Masuk untuk mulai melacak tanaman Anda",
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 50),

                        // Login form
                        _buildLoginForm(),

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

        // Floating leaves
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
            controller: controller.emailController,
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

        // Password field with animation
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
          child: Obx(() => TextField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Color(0xFF4CAF50),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: controller.togglePasswordVisibility,
                    child: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Color(0xFF757575),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
              )),
        ),

        // Error message (if any)
        Obx(() => controller.errorMessage.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              )
            : SizedBox.shrink()),

        SizedBox(height: 10),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.forgotPassword,
            child: Text(
              "Lupa Password?",
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: 30),

        // Login button with animation
        Obx(() => GestureDetector(
              onTap: controller.loginStatus.value == LoginStatus.loading
                  ? null
                  : controller.login,
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
                child: controller.loginStatus.value == LoginStatus.loading
                    ? Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "MASUK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            )),
      ],
    );
  }
}
