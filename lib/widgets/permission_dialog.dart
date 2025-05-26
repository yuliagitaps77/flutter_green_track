import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final Function() onPermissionGranted;

  const NotificationPermissionDialog({
    Key? key,
    required this.onPermissionGranted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: Color(0xFF2E7D32),
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Izinkan Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Untuk mendapatkan pengingat jadwal perawatan tanaman, kami membutuhkan izin untuk mengirim notifikasi ke perangkat Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Nanti Saja'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final isAllowed = await AwesomeNotifications()
                          .requestPermissionToSendNotifications(
                        permissions: [
                          NotificationPermission.Alert,
                          NotificationPermission.Sound,
                          NotificationPermission.Badge,
                          NotificationPermission.Vibration,
                          NotificationPermission.Light,
                          NotificationPermission.FullScreenIntent,
                          NotificationPermission.CriticalAlert,
                          NotificationPermission.PreciseAlarms,
                        ],
                      );

                      if (isAllowed) {
                        onPermissionGranted();
                        Get.back();
                        Get.snackbar(
                          'Berhasil',
                          'Izin notifikasi telah diberikan',
                          backgroundColor: Color(0xFF2E7D32),
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Perhatian',
                          'Izin notifikasi diperlukan untuk fitur pengingat',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Izinkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
