import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class ResetPasswordScreen extends StatefulWidget {
  static String routeName = "/reset-password";

  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();
  final TextEditingController _emailController = TextEditingController();

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
  }

  @override
  void dispose() {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50).withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: Color(0xFF4CAF50),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Masukkan alamat email Anda untuk menerima tautan reset password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 30),
                      if (!_success)
                        Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Masukkan email Anda',
                                prefixIcon:
                                    Icon(Icons.email, color: Color(0xFF4CAF50)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Color(0xFF4CAF50), width: 2),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            if (_errorMessage != null)
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4CAF50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _sendResetLink,
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      )
                                    : Text(
                                        'Kirim Tautan Reset',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
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
                      SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Kembali',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class ResetPasswordScreen extends StatefulWidget {
//   static String routeName = "/reset-password";

//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen>
//     with TickerProviderStateMixin {
//   // Get reference to the authentication controller
//   final AuthenticationController controller =
//       Get.find<AuthenticationController>();

//   late AnimationController _backgroundAnimController;
//   late AnimationController _formAnimController;
//   late Animation<double> _formAnimation;

//   final TextEditingController emailController = TextEditingController();
//   final RxBool isLoading = false.obs;
//   final RxString resultMessage = ''.obs;
//   final RxBool isSuccess = false.obs;

//   @override
//   void initState() {
//     super.initState();

//     // If coming from login screen, use the email already entered
//     if (controller.emailController.text.isNotEmpty) {
//       emailController.text = controller.emailController.text;
//     }

//     _backgroundAnimController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: 30),
//     )..repeat();

//     _formAnimController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 1200),
//     );

//     _formAnimation = CurvedAnimation(
//       parent: _formAnimController,
//       curve: Curves.easeOutQuint,
//     );

//     _formAnimController.forward();
//   }

//   @override
//   void dispose() {
//     _backgroundAnimController.dispose();
//     _formAnimController.dispose();
//     emailController.dispose();
//     super.dispose();
//   }

//   // Handle reset password request
//   Future<void> resetPassword() async {
//     final email = emailController.text.trim();
//     if (email.isEmpty) {
//       resultMessage.value = 'Masukkan email Anda terlebih dahulu';
//       isSuccess.value = false;
//       return;
//     }

//     try {
//       isLoading.value = true;

//       // Send password reset email
//       await controller.resetPassword(email);

//       isSuccess.value = true;
//       resultMessage.value = 'Link reset password telah dikirim ke email Anda';
//     } catch (error) {
//       isSuccess.value = false;
//       resultMessage.value =
//           'Gagal mengirim link reset password: ${error.toString()}';
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: Stack(
//         children: [
//           // Animated background
//           AnimatedBuilder(
//             animation: _backgroundAnimController,
//             builder: (context, child) {
//               return Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topRight,
//                     end: Alignment.bottomLeft,
//                     colors: [
//                       Colors.white,
//                       Color(0xFFE8F5E9),
//                       Color(0xFFC8E6C9),
//                     ],
//                     stops: [
//                       0,
//                       0.5 +
//                           0.1 *
//                               math.sin(_backgroundAnimController.value *
//                                   2 *
//                                   math.pi),
//                       1.0,
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),

//           // Background decorative elements
//           _buildBackgroundDecorations(),

//           // Main content
//           SafeArea(
//             child: SingleChildScrollView(
//               child: Container(
//                 height: MediaQuery.of(context).size.height -
//                     MediaQuery.of(context).padding.top -
//                     kToolbarHeight,
//                 child: AnimatedBuilder(
//                   animation: _formAnimation,
//                   builder: (context, child) {
//                     return Opacity(
//                       opacity: _formAnimation.value,
//                       child: Transform.translate(
//                         offset: Offset(0, 30 * (1 - _formAnimation.value)),
//                         child: child,
//                       ),
//                     );
//                   },
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 30),
//                     child: Column(
//                       children: [
//                         SizedBox(
//                             height: MediaQuery.of(context).size.height * 0.05),

//                         // App logo
//                         _buildAppLogo(),

//                         SizedBox(height: 30),

//                         // Title
//                         Text(
//                           "Reset Password",
//                           style: Theme.of(context).textTheme.displayLarge,
//                         ),

//                         SizedBox(height: 10),

//                         Text(
//                           "Masukkan email Anda untuk menerima link reset password",
//                           style: TextStyle(
//                             color: Color(0xFF757575),
//                             fontSize: 16,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),

//                         SizedBox(height: 50),

//                         // Reset password form
//                         _buildResetForm(),

//                         Spacer(),

//                         SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackgroundDecorations() {
//     return Stack(
//       children: [
//         // Animated circles
//         Positioned(
//           top: -80,
//           right: -40,
//           child: AnimatedBuilder(
//             animation: _backgroundAnimController,
//             builder: (context, child) {
//               return Transform.translate(
//                 offset: Offset(
//                   15 * math.sin(_backgroundAnimController.value * 2 * math.pi),
//                   10 * math.cos(_backgroundAnimController.value * 2 * math.pi),
//                 ),
//                 child: Container(
//                   height: 200,
//                   width: 200,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Color(0xFF81C784).withOpacity(0.2),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         Positioned(
//           bottom: MediaQuery.of(context).size.height * 0.4,
//           left: -60,
//           child: AnimatedBuilder(
//             animation: _backgroundAnimController,
//             builder: (context, child) {
//               return Transform.translate(
//                 offset: Offset(
//                   10 * math.cos(_backgroundAnimController.value * 2 * math.pi),
//                   15 * math.sin(_backgroundAnimController.value * 2 * math.pi),
//                 ),
//                 child: Container(
//                   height: 150,
//                   width: 150,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Color(0xFF66BB6A).withOpacity(0.15),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAppLogo() {
//     return Container(
//       height: 100,
//       width: 100,
//       child: Center(
//         child: Image.asset(
//           "assets/icon/ic_app.png",
//           width: 120,
//         ),
//       ),
//     );
//   }

//   Widget _buildResetForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // Email field
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(15),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 15,
//                 offset: Offset(0, 5),
//               ),
//             ],
//           ),
//           child: TextField(
//             controller: emailController,
//             keyboardType: TextInputType.emailAddress,
//             decoration: InputDecoration(
//               hintText: "Email",
//               prefixIcon: Icon(
//                 Icons.email_outlined,
//                 color: Color(0xFF4CAF50),
//               ),
//               border: InputBorder.none,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 20,
//               ),
//             ),
//           ),
//         ),

//         // Result message (if any)
//         Obx(() => resultMessage.isNotEmpty
//             ? Padding(
//                 padding: const EdgeInsets.only(top: 16.0),
//                 child: Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isSuccess.value ? Colors.green[50] : Colors.red[50],
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: isSuccess.value
//                           ? Colors.green.shade300
//                           : Colors.red.shade300,
//                     ),
//                   ),
//                   child: Text(
//                     resultMessage.value,
//                     style: TextStyle(
//                       color:
//                           isSuccess.value ? Colors.green[700] : Colors.red[700],
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               )
//             : SizedBox.shrink()),

//         SizedBox(height: 30),

//         // Reset password button
//         Obx(() => GestureDetector(
//               onTap: isLoading.value ? null : resetPassword,
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 18),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Color(0xFF66BB6A),
//                       Color(0xFF4CAF50),
//                       Color(0xFF388E3C),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Color(0xFF4CAF50).withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: isLoading.value
//                     ? Center(
//                         child: SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 3,
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         ),
//                       )
//                     : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "KIRIM LINK RESET",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Icon(
//                             Icons.send,
//                             color: Colors.white,
//                             size: 18,
//                           ),
//                         ],
//                       ),
//               ),
//             )),

//         SizedBox(height: 20),

//         // Back to login
//         GestureDetector(
//           onTap: () => Get.back(),
//           child: Container(
//             padding: EdgeInsets.symmetric(vertical: 15),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: Color(0xFF4CAF50),
//                 width: 1.5,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "KEMBALI KE LOGIN",
//                 style: TextStyle(
//                   color: Color(0xFF4CAF50),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   letterSpacing: 1,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
