import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/admin_dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  static String? routeName = "/PageLogin";
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;

  // Controller untuk loading state lokal
  final RxBool isLocalLoading = false.obs;

  // Reference ke AuthController untuk login
  late final AuthController _authController;

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize auth controller
    _initAuthController();

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

  // Initialize auth controller dengan pengecekan jika sudah ada
  void _initAuthController() {
    try {
      if (Get.isRegistered<AuthController>()) {
        _authController = Get.find<AuthController>();
        print('AuthController ditemukan');
      } else {
        print('Mendaftarkan AuthController baru');
        _authController = Get.put(AuthController(), permanent: true);
      }
    } catch (e) {
      print('Error saat inisialisasi AuthController: $e');
      // Fall back to creating a new instance if there's an issue
      _authController = Get.put(AuthController(), permanent: true);
    }
  }

  @override
  void dispose() {
    _backgroundAnimController.dispose();
    _formAnimController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
                        _buildAppLogo(),

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

                        // Obx widget untuk menampilkan loading indicator saat sedang login
                        Obx(() => isLocalLoading.value ||
                                _authController.isLoading.value
                            ? Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4CAF50)),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Proses login...',
                                    style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  )
                                ],
                              )
                            : SizedBox.shrink()),

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
            controller: emailController,
            keyboardType:
                TextInputType.emailAddress, // Ensure proper keyboard type
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
                controller: passwordController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Color(0xFF4CAF50),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        isPasswordVisible.value = !isPasswordVisible.value,
                    child: Icon(
                      isPasswordVisible.value
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

        SizedBox(height: 10),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword,
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
        GestureDetector(
          onTap: _handleLogin,
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
            child: Row(
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
        ),
      ],
    );
  }

  // Handle login button press
  void _handleLogin() async {
    // Set loading state
    isLocalLoading.value = true;

    try {
      // Validate inputs
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        Get.snackbar('Error', 'Email dan password harus diisi',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }

      // Debugging
      print('Attempting login with email: $email');

      // Attempt login
      bool success = await _authController.login(email, password);

      // Handling berdasarkan hasil login
      if (success) {
        print('Login successful');

        // Tambahan: Cek role dan navigasi ke halaman yang sesuai
        final role = _authController.userRole.value;

        print(
            'User role: ${role == UserRole.adminTPK ? "Admin TPK" : "Admin Penyemaian"}');

        // Navigate to the appropriate screen
        Get.offAll(() => MainNavigationContainer(
              userRole: role,
            ));
      } else {
        print('Login failed');
        // AuthController sudah menampilkan snackbar error
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      // Reset loading state
      isLocalLoading.value = false;
    }
  }

  // Handle forgot password
  void _handleForgotPassword() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('Error', 'Masukkan email Anda terlebih dahulu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    // Set loading state
    isLocalLoading.value = true;

    // Panggil fungsi reset password
    _authController.resetPassword(email).then((success) {
      if (success) {
        // Feedback sukses sudah ditampilkan di AuthController
      }
    }).catchError((error) {
      print('Error resetting password: $error');
      Get.snackbar('Error', 'Terjadi kesalahan saat reset password',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }).whenComplete(() {
      // Reset loading state
      isLocalLoading.value = false;
    });
  }
}
