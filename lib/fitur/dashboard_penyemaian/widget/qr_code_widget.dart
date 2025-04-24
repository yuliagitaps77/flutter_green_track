import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AestheticGreenTrackQR extends StatelessWidget {
  final String bibitId;

  const AestheticGreenTrackQR({
    Key? key,
    required this.bibitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // App theme colors
    final primaryGreen = Color(0xFF26A69A);
    final secondaryGreen = Color(0xFF81C784);
    final accentColor = Color(0xFFFFCC80);
    final backgroundColor = Color(0xFFF5F9FC);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withOpacity(0.1),
            backgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      margin: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with app name and decorative elements
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, secondaryGreen],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Green Track",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.eco, color: Colors.white),
              ],
            ),
          ),

          // QR Code with decorative elements
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Decorative plant icon
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_florist,
                    color: primaryGreen,
                    size: 36,
                  ),
                ),

                SizedBox(height: 20),

                // QR Container with inner shadow and border
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: secondaryGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: QrImageView(
                    data: bibitId,
                    version: QrVersions.auto,
                    size: screenWidth * 0.5,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: primaryGreen,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: primaryGreen,
                    ),
                    errorStateBuilder: (cxt, err) {
                      return Center(
                        child: Text(
                          "QR Error: $err",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Bibit ID with decorative elements
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: secondaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 16,
                        color: primaryGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        bibitId,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                // Caption text
                Text(
                  "Scan to track plant growth",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
