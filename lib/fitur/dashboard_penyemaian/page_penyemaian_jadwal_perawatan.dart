import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:flutter_green_track/service/notification_service.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Model untuk Jadwal Perawatan
class JadwalPerawatan {
  final String id;
  final String bibitId;
  final String namaBibit;
  final String jenisPerawatan;
  final DateTime tanggal;
  final String waktu; // Simpan waktu sebagai string "HH:mm"
  final String catatan;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool selesai;

  JadwalPerawatan({
    required this.id,
    required this.bibitId,
    required this.namaBibit,
    required this.jenisPerawatan,
    required this.tanggal,
    required this.waktu,
    required this.catatan,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.selesai = false,
  });

  factory JadwalPerawatan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JadwalPerawatan(
      id: doc.id,
      bibitId: data['bibit_id'] ?? '',
      namaBibit: data['nama_bibit'] ?? '',
      jenisPerawatan: data['jenis_perawatan'] ?? '',
      tanggal: (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      waktu: data['waktu'] ?? '08:00', // Default waktu jika tidak ada
      catatan: data['catatan'] ?? '',
      createdBy: data['created_by'] ?? '',
      createdByName: data['created_by_name'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selesai: data['selesai'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bibit_id': bibitId,
      'nama_bibit': namaBibit,
      'jenis_perawatan': jenisPerawatan,
      'tanggal': tanggal,
      'waktu': waktu,
      'catatan': catatan,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt,
      'selesai': selesai,
    };
  }

  // Helper untuk membandingkan waktu jadwal dengan waktu sekarang
  bool get isToday {
    final now = DateTime.now();
    return tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return tanggal.isAfter(DateTime(now.year, now.month, now.day));
  }

  bool get isPast {
    final now = DateTime.now();
    return tanggal.isBefore(DateTime(now.year, now.month, now.day));
  }

  // Copy with method untuk mengubah status selesai
  JadwalPerawatan copyWith({bool? selesai}) {
    return JadwalPerawatan(
      id: this.id,
      bibitId: this.bibitId,
      namaBibit: this.namaBibit,
      jenisPerawatan: this.jenisPerawatan,
      tanggal: this.tanggal,
      waktu: this.waktu,
      catatan: this.catatan,
      createdBy: this.createdBy,
      createdByName: this.createdByName,
      createdAt: this.createdAt,
      selesai: selesai ?? this.selesai,
    );
  }
}

// Controller untuk Jadwal Perawatan
class JadwalPerawatanController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService =
      Get.put(NotificationService());

  // Calendar variables
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final RxMap<DateTime, List<JadwalPerawatan>> jadwalEvents =
      RxMap<DateTime, List<JadwalPerawatan>>({});

  // Loading state
  final RxBool isLoading = false.obs;

  // Selected bibit for detail
  final Rx<Bibit?> selectedBibit = Rx<Bibit?>(null);

  // List of all bibit
  final RxList<Bibit> bibitList = <Bibit>[].obs;

  // Jadwal for selected date
  final RxList<JadwalPerawatan> selectedDateJadwal = <JadwalPerawatan>[].obs;

  // Selected category tab
  final RxString selectedCategory = "semua".obs;

  // Form variables
  final Rx<Bibit?> selectedBibitForJadwal = Rx<Bibit?>(null);
  final Rx<String> selectedJenisPerawatan = "penyiraman".obs;
  final TextEditingController catatanController = TextEditingController();
  final RxString selectedTime = "08:00".obs;
  final RxBool isFormValid = false.obs;

  // Current user
  String? currentUserId;
  String? currentUserName;

  // List jenis perawatan
  final List<String> jenisPerawatan = [
    "penyiraman",
    "pemupukan",
    "pengecekan",
    "penyiangan",
    "penyemprotan",
    "pemangkasan"
  ];

  // Icons for jenis perawatan
  final Map<String, IconData> jenisPerawatanIcons = {
    "penyiraman": Icons.water_drop,
    "pemupukan": Icons.eco,
    "pengecekan": Icons.check_circle,
    "penyiangan": Icons.grass,
    "penyemprotan": Icons.sanitizer,
    "pemangkasan": Icons.content_cut,
  };

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('id_ID');
    initUserData();
    fetchBibitList();
    fetchJadwalPerawatan();
    _notificationService.initNotification();

    // Add listener to catatanController
    catatanController.addListener(_validateForm);
  }

  void _validateForm() {
    isFormValid.value = selectedBibitForJadwal.value != null &&
        catatanController.text.trim().isNotEmpty;
  }

  @override
  void onClose() {
    catatanController.removeListener(_validateForm);
    catatanController.dispose();
    super.onClose();
  }

  // Initialize user data
  Future<void> initUserData() async {
    try {
      isLoading.value = true;
      // Get current user from local storage
      final user = await _firebaseService.getLocalUser();

      if (user != null) {
        currentUserId = user.id;
        currentUserName = user.name;
      } else {
        // If no user in local storage, check Firebase Auth
        final firebaseUser = _firebaseService.getCurrentFirebaseUser();
        if (firebaseUser != null) {
          final userData = await _firebaseService.getUserData(firebaseUser.uid);
          if (userData != null) {
            currentUserId = userData.id;
            currentUserName = userData.name;
          }
        }
      }
    } catch (e) {
      print('Error initializing user data: ${e}');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch list of bibit from Firestore
  Future<void> fetchBibitList() async {
    try {
      isLoading.value = true;

      final QuerySnapshot snapshot = await _firestore.collection('bibit').get();

      bibitList.clear();
      for (var doc in snapshot.docs) {
        bibitList.add(Bibit.fromFirestore(doc));
      }
    } catch (e) {
      print('Error fetching bibit list: ${e}');
      Get.snackbar('Error', 'Gagal memuat daftar bibit');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch jadwal perawatan from Firestore
  Future<void> fetchJadwalPerawatan() async {
    try {
      isLoading.value = true;

      final QuerySnapshot snapshot =
          await _firestore.collection('jadwal_perawatan').get();

      Map<DateTime, List<JadwalPerawatan>> tempEvents = {};

      for (var doc in snapshot.docs) {
        final jadwal = JadwalPerawatan.fromFirestore(doc);

        // Create DateTime with only year, month, day for event key
        final eventDate = DateTime(
          jadwal.tanggal.year,
          jadwal.tanggal.month,
          jadwal.tanggal.day,
        );

        if (tempEvents[eventDate] != null) {
          tempEvents[eventDate]!.add(jadwal);
        } else {
          tempEvents[eventDate] = [jadwal];
        }
      }

      jadwalEvents.value = tempEvents;
      updateSelectedDateEvents();
    } catch (e) {
      print('Error fetching jadwal perawatan: ${e}');
      Get.snackbar('Error', 'Gagal memuat jadwal perawatan');
    } finally {
      isLoading.value = false;
    }
  }

  // Get events for selected day
  List<JadwalPerawatan> getEventsForDay(DateTime day) {
    final eventDate = DateTime(day.year, day.month, day.day);
    return jadwalEvents[eventDate] ?? [];
  }

  // Update events for selected date
  void updateSelectedDateEvents() {
    final eventDate = DateTime(
      selectedDay.value.year,
      selectedDay.value.month,
      selectedDay.value.day,
    );

    selectedDateJadwal.value = jadwalEvents[eventDate] ?? [];
  }

  // Set selected category
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  // Get filtered jadwal based on selected category
  List<JadwalPerawatan> getFilteredJadwal() {
    switch (selectedCategory.value) {
      case "selesai":
        return selectedDateJadwal.where((jadwal) => jadwal.selesai).toList();
      case "belum":
        return selectedDateJadwal.where((jadwal) => !jadwal.selesai).toList();
      case "hari_ini":
        return selectedDateJadwal.where((jadwal) => jadwal.isToday).toList();
      default:
        return selectedDateJadwal;
    }
  }

  // Select a day
  void onDaySelected(DateTime selected, DateTime focused) {
    if (!isSameDay(selectedDay.value, selected)) {
      selectedDay.value = selected;
      focusedDay.value = focused;
      updateSelectedDateEvents();
    }
  }

  // Select a bibit for detail view
  void selectBibit(Bibit bibit) {
    selectedBibit.value = bibit;
  }

  // Set bibit for new jadwal
  void setBibitForNewJadwal(Bibit bibit) {
    selectedBibitForJadwal.value = bibit;
    _validateForm();
  }

  // Set jenis perawatan
  void setJenisPerawatan(String jenis) {
    selectedJenisPerawatan.value = jenis;
    _validateForm();
  }

  // Set waktu jadwal
  void setWaktuJadwal(String time) {
    selectedTime.value = time;
    _validateForm();
  }

  String _formatJenisPerawatan(String jenis) {
    if (jenis.isEmpty) return jenis;

    // Split string into characters to handle first character capitalization
    final chars = jenis.split('');
    if (chars.isNotEmpty) {
      chars[0] = chars[0].toUpperCase();
    }
    return chars.join('');
  }

  // Create new jadwal perawatan
  Future<void> createJadwalPerawatan() async {
    try {
      if (selectedBibitForJadwal.value == null) {
        Get.snackbar('Error', 'Silahkan pilih bibit terlebih dahulu');
        return;
      }

      if (catatanController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Silahkan isi catatan perawatan');
        return;
      }

      isLoading.value = true;

      // Parse waktu jadwal
      final timeParts = selectedTime.value.split(':');
      final scheduledDateTime = DateTime(
        selectedDay.value.year,
        selectedDay.value.month,
        selectedDay.value.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Check if scheduled time is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        Get.snackbar(
          'Error',
          'Waktu yang dipilih sudah lewat. Silahkan pilih waktu yang akan datang.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final newJadwal = JadwalPerawatan(
        id: '', // Will be assigned by Firestore
        bibitId: selectedBibitForJadwal.value!.id,
        namaBibit: selectedBibitForJadwal.value!.namaBibit,
        jenisPerawatan: selectedJenisPerawatan.value,
        tanggal: selectedDay.value,
        waktu: selectedTime.value,
        catatan: catatanController.text.trim(),
        createdBy: currentUserId ?? '',
        createdByName: currentUserName ?? 'Admin',
        createdAt: DateTime.now(),
        selesai: false,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('jadwal_perawatan')
          .add(newJadwal.toMap());

      print('Scheduling notification for: ${scheduledDateTime.toString()}');

      // Schedule notification
      await _notificationService
          .scheduleNotification(
        title: 'Jadwal ${_formatJenisPerawatan(selectedJenisPerawatan.value)}',
        body:
            'Waktunya melakukan ${selectedJenisPerawatan.value} untuk tanaman ${selectedBibitForJadwal.value!.namaBibit}\n${catatanController.text.trim()}',
        scheduledDate: scheduledDateTime,
        payload: docRef.id,
      )
          .then((_) {
        print('Notification scheduled successfully');
      }).catchError((error) {
        print('Error scheduling notification: $error');
      });

      // Record activity
      AppController.to.recordActivity(
        activityType: ActivityTypes.addJadwalRawat,
        name: '${selectedBibitForJadwal.value!.namaBibit}',
        targetId: selectedBibitForJadwal.value!.id,
        metadata: {
          'jenisPerawatan': selectedJenisPerawatan.value,
          'tanggal': selectedDay.value.toString(),
          'waktu': selectedTime.value,
          'catatan': catatanController.text.trim(),
          'timestamp': DateTime.now().toString(),
        },
      );

      // Create jadwal with actual ID from Firestore
      final jadwalWithId = JadwalPerawatan(
        id: docRef.id,
        bibitId: newJadwal.bibitId,
        namaBibit: newJadwal.namaBibit,
        jenisPerawatan: newJadwal.jenisPerawatan,
        tanggal: newJadwal.tanggal,
        waktu: newJadwal.waktu,
        catatan: newJadwal.catatan,
        createdBy: newJadwal.createdBy,
        createdByName: newJadwal.createdByName,
        createdAt: newJadwal.createdAt,
        selesai: newJadwal.selesai,
      );

      // Update local data
      final eventDate = DateTime(
        selectedDay.value.year,
        selectedDay.value.month,
        selectedDay.value.day,
      );

      if (jadwalEvents[eventDate] != null) {
        jadwalEvents[eventDate]!.add(jadwalWithId);
      } else {
        jadwalEvents[eventDate] = [jadwalWithId];
      }

      updateSelectedDateEvents();

      // Reset form
      catatanController.clear();
      selectedBibitForJadwal.value = null;
      selectedTime.value = "08:00";

      Get.snackbar(
        'Berhasil',
        'Jadwal perawatan berhasil ditambahkan dan notifikasi telah diatur',
        backgroundColor: const Color(0xFF2E7D32),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error creating jadwal perawatan: $e');
      Get.snackbar(
        'Error',
        'Gagal menambahkan jadwal perawatan: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mark jadwal as completed or not completed
  Future<void> toggleJadwalStatus(JadwalPerawatan jadwal) async {
    try {
      isLoading.value = true;

      // Update in Firestore
      await _firestore.collection('jadwal_perawatan').doc(jadwal.id).update({
        'selesai': !jadwal.selesai,
      });

      // Update local data
      final eventDate = DateTime(
        jadwal.tanggal.year,
        jadwal.tanggal.month,
        jadwal.tanggal.day,
      );

      if (jadwalEvents[eventDate] != null) {
        final index =
            jadwalEvents[eventDate]!.indexWhere((item) => item.id == jadwal.id);
        if (index != -1) {
          final updatedJadwal = jadwal.copyWith(selesai: !jadwal.selesai);
          jadwalEvents[eventDate]![index] = updatedJadwal;
        }
      }

      updateSelectedDateEvents();

      Get.snackbar(
          'Berhasil',
          jadwal.selesai
              ? 'Jadwal ditandai belum selesai'
              : 'Jadwal ditandai selesai');

      AppController.to.recordActivity(
          activityType: ActivityTypes.completeJadwalRawat,
          name: "${jadwal.jenisPerawatan} | ${jadwal.namaBibit}",
          metadata: {
            'timestamp': DateTime.now().toString(),
          });
    } catch (e) {
      print('Error toggling jadwal status: ${e}');
      Get.snackbar('Error', 'Gagal mengubah status jadwal');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete jadwal perawatan
  Future<void> deleteJadwalPerawatan(JadwalPerawatan jadwal) async {
    try {
      isLoading.value = true;

      // Delete from Firestore
      await _firestore.collection('jadwal_perawatan').doc(jadwal.id).delete();

      // Update local data
      final eventDate = DateTime(
        jadwal.tanggal.year,
        jadwal.tanggal.month,
        jadwal.tanggal.day,
      );

      if (jadwalEvents[eventDate] != null) {
        jadwalEvents[eventDate]!.removeWhere((item) => item.id == jadwal.id);

        // If empty list, remove the date entry
        if (jadwalEvents[eventDate]!.isEmpty) {
          jadwalEvents.remove(eventDate);
        }
      }

      updateSelectedDateEvents();
      AppController.to.recordActivity(
          activityType: ActivityTypes.deleteJadwalRawat,
          name: "${jadwal.jenisPerawatan} | ${jadwal.namaBibit}",
          metadata: {
            'timestamp': DateTime.now().toString(),
          });
      Get.snackbar('Berhasil', 'Jadwal perawatan berhasil dihapus');
    } catch (e) {
      print('Error deleting jadwal perawatan: ${e}');
      Get.snackbar('Error', 'Gagal menghapus jadwal perawatan');
    } finally {
      isLoading.value = false;
    }
  }
}

class JadwalPerawatanPage extends StatelessWidget {
  final JadwalPerawatanController controller =
      Get.put(JadwalPerawatanController());

  JadwalPerawatanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          "Jadwal Perawatan",
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Obx(() => controller.isLoading.value
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Calendar
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, 12, 8, 16),
                      child: TableCalendar<JadwalPerawatan>(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: controller.focusedDay.value,
                        selectedDayPredicate: (day) =>
                            isSameDay(controller.selectedDay.value, day),
                        calendarFormat: CalendarFormat.month,
                        eventLoader: controller.getEventsForDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarStyle: CalendarStyle(
                          markersMaxCount: 3,
                          markerDecoration: BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Color(0xFF4CAF50).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(color: Colors.red[300]),
                          outsideTextStyle: TextStyle(color: Colors.grey[400]),
                          defaultTextStyle:
                              TextStyle(fontWeight: FontWeight.w500),
                        ),
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left,
                              color: Color(0xFF4CAF50)),
                          rightChevronIcon: Icon(Icons.chevron_right,
                              color: Color(0xFF4CAF50)),
                          headerPadding: EdgeInsets.symmetric(vertical: 12),
                          headerMargin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.red[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onDaySelected: controller.onDaySelected,
                      ),
                    ),
                  ),

                  // Date Selector
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Color(0xFF4CAF50).withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                  .format(controller.selectedDay.value),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: controller.selectedDateJadwal.isNotEmpty
                                ? Color(0xFF2E7D32)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${controller.selectedDateJadwal.length} Jadwal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category tabs
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    height: 40,
                    child: Row(
                      children: [
                        _buildCategoryTab("semua", "Semua", Icons.list),
                        SizedBox(width: 8),
                        _buildCategoryTab("hari_ini", "Hari Ini", Icons.today),
                        SizedBox(width: 8),
                        _buildCategoryTab(
                            "selesai", "Selesai", Icons.check_circle),
                        SizedBox(width: 8),
                        _buildCategoryTab(
                            "belum", "Belum Selesai", Icons.pending_actions),
                      ],
                    ),
                  ),

                  // Jadwal List Container
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildJadwalContent(),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      floatingActionButton: Obx(() {
        final selectedDay = controller.selectedDay.value;
        final now = DateTime.now();
        final isPastDate = selectedDay.year < now.year ||
            (selectedDay.year == now.year && selectedDay.month < now.month) ||
            (selectedDay.year == now.year &&
                selectedDay.month == now.month &&
                selectedDay.day < now.day);

        return FloatingActionButton.extended(
          onPressed: isPastDate ? null : () => _showAddJadwalDialog(),
          backgroundColor: isPastDate ? Colors.grey : Color(0xFF4CAF50),
          elevation: 3,
          tooltip: isPastDate
              ? 'Tidak dapat menambahkan jadwal untuk hari yang telah lewat'
              : 'Tambah Jadwal',
          label: Column(
            children: [
              Icon(Icons.add),
              SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryTab(String value, String label, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.setCategory(value),
        borderRadius: BorderRadius.circular(30),
        child: Obx(() {
          final isSelected = controller.selectedCategory.value == value;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF4CAF50) : Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildJadwalContent() {
    return Obx(() {
      final filteredList = controller.getFilteredJadwal();

      if (filteredList.isEmpty) {
        return Column(
          children: [
            // Empty state
            Icon(
              Icons.event_busy,
              size: 100,
              color: Colors.grey[300],
            ),
            SizedBox(height: 24),
            Text(
              'Tidak ada jadwal perawatan',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                controller.selectedCategory.value == "semua"
                    ? 'Tambahkan jadwal perawatan untuk bibit tanaman Anda'
                    : 'Tidak ada jadwal dalam kategori ini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showAddJadwalDialog(),
              icon: Icon(Icons.add, color: Color(0xFF4CAF50)),
              label: Text(
                'Tambah Jadwal Baru',
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            // Jadwal list
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jadwal Perawatan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Urutkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            ...filteredList.map((jadwal) => _buildJadwalCard(jadwal)),
            // Tambahan ruang di bagian bawah untuk FAB
            SizedBox(height: 80),
          ],
        );
      }
    });
  }

  Widget _buildJadwalCard(JadwalPerawatan jadwal) {
    // Get card color based on jenis perawatan
    Color cardColor;
    Color iconBgColor;

    switch (jadwal.jenisPerawatan) {
      case 'penyiraman':
        cardColor = Colors.blue[50]!;
        iconBgColor = Colors.blue[400]!;
        break;
      case 'pemupukan':
        cardColor = Colors.green[50]!;
        iconBgColor = Colors.green[400]!;
        break;
      case 'pengecekan':
        cardColor = Colors.purple[50]!;
        iconBgColor = Colors.purple[400]!;
        break;
      case 'penyiangan':
        cardColor = Colors.orange[50]!;
        iconBgColor = Colors.orange[400]!;
        break;
      case 'penyemprotan':
        cardColor = Colors.teal[50]!;
        iconBgColor = Colors.teal[400]!;
        break;
      case 'pemangkasan':
        cardColor = Colors.red[50]!;
        iconBgColor = Colors.red[400]!;
        break;
      default:
        cardColor = Colors.grey[50]!;
        iconBgColor = Colors.grey[400]!;
    }

    // Adjust colors if completed
    if (jadwal.selesai) {
      cardColor = Colors.grey[100]!;
      iconBgColor = Colors.grey[400]!;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final bibit = controller.bibitList
                    .firstWhereOrNull((b) => b.id == jadwal.bibitId);
                if (bibit != null) {
                  controller.selectBibit(bibit);
                  _showBibitDetailDialog(bibit);
                }
              },
              child: Column(
                children: [
                  // Top colored section
                  Container(
                    color: cardColor,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.jenisPerawatanIcons[
                                    jadwal.jenisPerawatan] ??
                                Icons.spa,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatJenisPerawatan(jadwal.jenisPerawatan),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: jadwal.selesai
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                  decoration: jadwal.selesai
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    jadwal.waktu,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  jadwal.selesai ? Icons.refresh : Icons.check,
                                  color: jadwal.selesai
                                      ? Colors.amber[700]
                                      : Colors.green[700],
                                  size: 20,
                                ),
                                onPressed: () =>
                                    controller.toggleJadwalStatus(jadwal),
                                constraints: BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400], size: 20),
                                onPressed: () => _confirmDeleteJadwal(jadwal),
                                constraints: BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bibit name with visual emphasis
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Color(0xFF4CAF50).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.eco_outlined,
                                    size: 14,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    jadwal.namaBibit,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Catatan with visually separated design
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan Perawatan:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                jadwal.catatan,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[900],
                                  decoration: jadwal.selesai
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Creator info
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  jadwal.createdByName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: jadwal.selesai
                                    ? Colors.green[50]
                                    : jadwal.isToday
                                        ? Colors.amber[50]
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: jadwal.selesai
                                      ? Colors.green[200]!
                                      : jadwal.isToday
                                          ? Colors.amber[200]!
                                          : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                jadwal.selesai
                                    ? 'Selesai'
                                    : jadwal.isToday
                                        ? 'Hari Ini'
                                        : jadwal.isUpcoming
                                            ? 'Mendatang'
                                            : 'Terlewat',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: jadwal.selesai
                                      ? Colors.green[700]
                                      : jadwal.isToday
                                          ? Colors.amber[700]
                                          : jadwal.isUpcoming
                                              ? Colors.grey[700]
                                              : Colors.red[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to format jenis perawatan
  String _formatJenisPerawatan(String jenis) {
    if (jenis.isEmpty) return jenis;

    // Split string into characters to handle first character capitalization
    final chars = jenis.split('');
    if (chars.isNotEmpty) {
      chars[0] = chars[0].toUpperCase();
    }
    return chars.join('');
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ': $value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showBibitDetailDialog(Bibit bibit) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            width: Get.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image
                Stack(
                  children: [
                    // Image
                    if (bibit.gambarImage.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        child: Image.network(
                          bibit.gambarImage[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: Color(0xFF4CAF50),
                              child: Center(
                                child: Icon(
                                  Icons.eco_outlined,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: Color(0xFF4CAF50),
                        child: Center(
                          child: Icon(
                            Icons.eco_outlined,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),

                    // Image overlay gradient
                    if (bibit.gambarImage.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Back button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.black87),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ),

                    // Bibit name overlay
                    if (bibit.gambarImage.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bibit.namaBibit,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                bibit.varietas,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // If no image, show the title here
                if (bibit.gambarImage.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bibit.namaBibit,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          bibit.varietas,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Lokasi
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Tanaman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLocationDetail('KPH', bibit.kph),
                                  SizedBox(height: 4),
                                  _buildLocationDetail('BKPH', bibit.bkph),
                                  SizedBox(height: 4),
                                  _buildLocationDetail('RKPH', bibit.rkph),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // // Button
                // Padding(
                //   padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                //   child: SizedBox(
                //     width: double.infinity,
                //     child: ElevatedButton.icon(
                //       onPressed: () {
                //         Get.back();
                //         controller.setBibitForNewJadwal(bibit);
                //         _showAddJadwalDialog();
                //       },
                //       icon: Icon(Icons.calendar_today),
                //       label: Text('Jadwalkan Perawatan'),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Color(0xFF4CAF50),
                //         foregroundColor: Colors.white,
                //         padding: EdgeInsets.symmetric(vertical: 16),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //         elevation: 2,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteJadwal(JadwalPerawatan jadwal) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Jadwal Perawatan?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin menghapus jadwal perawatan ini? Tindakan ini tidak dapat dibatalkan.',
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
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteJadwalPerawatan(jadwal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddJadwalDialog() {
    controller.catatanController.clear();
    controller.selectedTime.value = "08:00";

    if (controller.bibitList.isEmpty) {
      Get.snackbar(
        'Error',
        'Daftar bibit kosong. Silahkan tambahkan bibit terlebih dahulu.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        borderRadius: 10,
      );
      return;
    }

    // Create color map for jenis perawatan
    final Map<String, Color> jenisPerawatanColors = {
      'penyiraman': Colors.blue[600]!,
      'pemupukan': Colors.green[600]!,
      'pengecekan': Colors.purple[600]!,
      'penyiangan': Colors.orange[600]!,
      'penyemprotan': Colors.teal[600]!,
      'pemangkasan': Colors.red[600]!,
    };

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Jadwal Perawatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                  .format(controller.selectedDay.value),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pilih Bibit
                      Text(
                        'Pilih Bibit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Obx(() => DropdownButtonFormField<Bibit>(
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.eco_outlined,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              hint: Text('Pilih Bibit Tanaman'),
                              value: controller.selectedBibitForJadwal.value,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF4CAF50)),
                              dropdownColor: Colors.white,
                              items: controller.bibitList.map((bibit) {
                                return DropdownMenuItem<Bibit>(
                                  value: bibit,
                                  child: Text(
                                    bibit.namaBibit,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.setBibitForNewJadwal(value);
                                }
                              },
                            )),
                      ),
                      SizedBox(height: 20),

                      // Waktu Perawatan
                      Text(
                        'Waktu Perawatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: Get.context!,
                            initialTime: TimeOfDay(
                              hour: int.parse(
                                  controller.selectedTime.value.split(':')[0]),
                              minute: int.parse(
                                  controller.selectedTime.value.split(':')[1]),
                            ),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF4CAF50),
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            final formattedTime =
                                '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                            controller.setWaktuJadwal(formattedTime);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Obx(() => Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Color(0xFF4CAF50),
                                    size: 22,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    controller.selectedTime.value,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              )),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Jenis Perawatan
                      Text(
                        'Jenis Perawatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.2,
                          physics: NeverScrollableScrollPhysics(),
                          children: controller.jenisPerawatan.map((jenis) {
                            return Obx(() {
                              final isSelected =
                                  controller.selectedJenisPerawatan.value ==
                                      jenis;
                              final color = jenisPerawatanColors[jenis] ??
                                  Colors.grey[600]!;

                              return InkWell(
                                onTap: () =>
                                    controller.setJenisPerawatan(jenis),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.15)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected ? color : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        color.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          controller
                                                  .jenisPerawatanIcons[jenis] ??
                                              Icons.spa,
                                          size: 18,
                                          color:
                                              isSelected ? Colors.white : color,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _formatJenisPerawatan(jenis),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? color
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Catatan
                      Text(
                        'Catatan Perawatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: controller.catatanController,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan catatan tentang perawatan...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          maxLines: 4,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF4CAF50),
                                side: BorderSide(color: Color(0xFF4CAF50)),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Batal'),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Obx(() => ElevatedButton(
                                  onPressed: controller.isFormValid.value
                                      ? () {
                                          Get.back();
                                          controller.createJadwalPerawatan();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.isFormValid.value
                                            ? Color(0xFF4CAF50)
                                            : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Simpan Jadwal'),
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
