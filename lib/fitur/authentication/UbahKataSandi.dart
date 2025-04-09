import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class UbahKataSandiScreen extends StatefulWidget {
  static const String routeName = "/PageUbahKataSandi";

  const UbahKataSandiScreen({Key? key}) : super(key: key);

  @override
  _UbahKataSandiScreenState createState() => _UbahKataSandiScreenState();
}

class _UbahKataSandiScreenState extends State<UbahKataSandiScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Using RxBool from GetX for reactive state
  final _isPasswordVisible = false.obs;
  final _isConfirmPasswordVisible = false.obs;
  final _isLoading = false.obs;
  final _passwordError = ''.obs;
  final _confirmPasswordError = ''.obs;
  final _emailError = ''.obs;

  late AnimationController _backgroundAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = true;

    // Reset errors
    _emailError.value = '';
    _passwordError.value = '';
    _confirmPasswordError.value = '';

    // Validate email
    if (emailController.text.isEmpty) {
      _emailError.value = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!GetUtils.isEmail(emailController.text)) {
      _emailError.value = 'Format email tidak valid';
      isValid = false;
    }

    // Validate password
    if (passwordController.text.isEmpty) {
      _passwordError.value = 'Kata sandi tidak boleh kosong';
      isValid = false;
    } else if (passwordController.text.length < 6) {
      _passwordError.value = 'Kata sandi minimal 6 karakter';
      isValid = false;
    }

    // Validate confirm password
    if (confirmPasswordController.text.isEmpty) {
      _confirmPasswordError.value = 'Konfirmasi kata sandi tidak boleh kosong';
      isValid = false;
    } else if (confirmPasswordController.text != passwordController.text) {
      _confirmPasswordError.value = 'Kata sandi tidak cocok';
      isValid = false;
    }

    if (isValid) {
      _submitForm();
    }
  }

  void _submitForm() {
    _isLoading.value = true;

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      _isLoading.value = false;

      // Show success message
      Get.snackbar(
        "Berhasil",
        "Kata sandi berhasil diubah",
        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );

      // Go back to previous screen
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
    });
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
                    colors: const [
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
              child: SizedBox(
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
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Color(0xFF4CAF50)),
                            onPressed: () => Get.back(),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildAppLogo(),
                        // Title
                        const Text(
                          "Ubah Kata Sandi",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Form
                        _buildForm(),

                        const Spacer(),

                        const SizedBox(height: 20),
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
                    color: const Color(0xFF81C784).withOpacity(0.2),
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
                    color: const Color(0xFF66BB6A).withOpacity(0.15),
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _emailError.value = '',
                decoration: const InputDecoration(
                  hintText: "Masukkan Email",
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
              Positioned(
                top: 0,
                right: 0,
                child: Obx(() => _emailError.value.isNotEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 5, right: 10),
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 18,
                        ),
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        ),

        Obx(() => _emailError.value.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Text(
                  _emailError.value,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 20),

        // Password field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Obx(() => TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible.value,
                    onChanged: (_) => _passwordError.value = '',
                    decoration: InputDecoration(
                      hintText: "Masukkan Kata Sandi",
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF4CAF50),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => _isPasswordVisible.value =
                            !_isPasswordVisible.value,
                        child: Icon(
                          _isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  )),
              Positioned(
                top: 0,
                right: 40, // adjusted to not overlap with visibility icon
                child: Obx(() => _passwordError.value.isNotEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 5, right: 10),
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 18,
                        ),
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        ),

        Obx(() => _passwordError.value.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Text(
                  _passwordError.value,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 20),

        // Confirm Password field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Obx(() => TextField(
                    controller: confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible.value,
                    onChanged: (_) => _confirmPasswordError.value = '',
                    decoration: InputDecoration(
                      hintText: "Masukkan konfirmasi Kata sandi",
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF4CAF50),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => _isConfirmPasswordVisible.value =
                            !_isConfirmPasswordVisible.value,
                        child: Icon(
                          _isConfirmPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  )),
              Positioned(
                top: 0,
                right: 40,
                child: Obx(() => _confirmPasswordError.value.isNotEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 5, right: 10),
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 18,
                        ),
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        ),

        Obx(() => _confirmPasswordError.value.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Text(
                  _confirmPasswordError.value,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
            : const SizedBox.shrink()),

        const SizedBox(height: 40),

        // Submit button
        Obx(() => GestureDetector(
              onTap: _isLoading.value ? null : _validateForm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Selanjutnya",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            )),
      ],
    );
  }
}
