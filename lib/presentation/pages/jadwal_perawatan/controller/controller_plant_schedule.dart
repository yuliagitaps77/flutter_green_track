import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class CareScheduleItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final String type;
  final IconData icon;
  final Color color;
  bool isCompleted;

  CareScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    required this.icon,
    required this.color,
    this.isCompleted = false,
  });
}

class PlantCareController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Animation variables
  late AnimationController breathingController;
  late Animation<double> breathingAnimation;

  // Calendar variables
  var calendarFormat = CalendarFormat.month.obs;
  var focusedDay = DateTime.now().obs;
  var selectedDay = DateTime.now().obs;

  // Schedule data
  final Rx<Map<DateTime, List<CareScheduleItem>>> careEvents =
      Rx<Map<DateTime, List<CareScheduleItem>>>({});
  final RxList<CareScheduleItem> selectedEvents = <CareScheduleItem>[].obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final timeController = TextEditingController();
  final isAddingSchedule = false.obs;
  final selectedTypeIndex = 0.obs;

  // Care types data
  final List<Map<String, dynamic>> careTypes = [
    {
      'name': 'Penyiraman',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF2196F3)
    },
    {
      'name': 'Pemupukan',
      'icon': Icons.eco_outlined,
      'color': Color(0xFF4CAF50)
    },
    {
      'name': 'Pengecekan',
      'icon': Icons.search_outlined,
      'color': Color(0xFFFF9800)
    },
    {
      'name': 'Penyiangan',
      'icon': Icons.cut_outlined,
      'color': Color(0xFFE91E63)
    },
    {
      'name': 'Penyemprotan',
      'icon': Icons.sanitizer_outlined,
      'color': Color(0xFF9C27B0)
    },
    {
      'name': 'Pemangkasan',
      'icon': Icons.content_cut_outlined,
      'color': Color(0xFF795548)
    },
  ];

  @override
  void onInit() {
    super.onInit();

    // Initialize animation controller
    breathingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Generate dummy data
    generateDummySchedule();

    // Initialize events for today
    updateSelectedEvents();
  }

  @override
  void onClose() {
    breathingController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    timeController.dispose();
    super.onClose();
  }

  // Generate dummy schedule data
  void generateDummySchedule() {
    final now = DateTime.now();
    final Map<DateTime, List<CareScheduleItem>> events = {};

    // Clean up time variables for date comparison
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final tomorrow = today.add(Duration(days: 1));
    final dayAfterTomorrow = today.add(Duration(days: 2));

    // Today's schedule
    events[today] = [
      CareScheduleItem(
        id: '1',
        title: 'Penyiraman Bibit Mahoni',
        description: 'Penyiraman rutin untuk bibit mahoni usia 2 bulan',
        time: '08:00',
        type: careTypes[0]['name'],
        icon: careTypes[0]['icon'],
        color: careTypes[0]['color'],
      ),
      CareScheduleItem(
        id: '2',
        title: 'Pemupukan Bibit Jati',
        description: 'Pemberian pupuk NPK untuk bibit jati',
        time: '09:30',
        type: careTypes[1]['name'],
        icon: careTypes[1]['icon'],
        color: careTypes[1]['color'],
      ),
    ];

    // Yesterday's schedule
    events[yesterday] = [
      CareScheduleItem(
        id: '3',
        title: 'Pengecekan Kesehatan Bibit',
        description: 'Pemeriksaan kondisi daun dan batang',
        time: '10:00',
        type: careTypes[2]['name'],
        icon: careTypes[2]['icon'],
        color: careTypes[2]['color'],
        isCompleted: true,
      ),
    ];

    // Tomorrow's schedule
    events[tomorrow] = [
      CareScheduleItem(
        id: '4',
        title: 'Penyiangan Gulma',
        description: 'Membersihkan gulma di sekitar bibit',
        time: '08:30',
        type: careTypes[3]['name'],
        icon: careTypes[3]['icon'],
        color: careTypes[3]['color'],
      ),
    ];

    // Day after tomorrow's schedule
    events[dayAfterTomorrow] = [
      CareScheduleItem(
        id: '5',
        title: 'Penyemprotan Pestisida',
        description: 'Penyemprotan pestisida organik untuk pencegahan hama',
        time: '15:00',
        type: careTypes[4]['name'],
        icon: careTypes[4]['icon'],
        color: careTypes[4]['color'],
      ),
      CareScheduleItem(
        id: '6',
        title: 'Pemangkasan Daun Kering',
        description: 'Memangkas daun-daun kering dan tidak sehat',
        time: '16:30',
        type: careTypes[5]['name'],
        icon: careTypes[5]['icon'],
        color: careTypes[5]['color'],
      ),
    ];

    careEvents.value = events;
  }

  void showDatePickerDialog(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDay.value,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4CAF50),
              ),
            ),
          ),
          child: child ?? SizedBox(), // Cegah error jika child null
        );
      },
    );

    if (picked != null) {
      changeSelectedDay(picked);
    }
  }

  // Get events for a specific day
  List<CareScheduleItem> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return careEvents.value[normalizedDay] ?? [];
  }

  // Update selected events
  void updateSelectedEvents() {
    selectedEvents.value = getEventsForDay(selectedDay.value);
  }

  // Change selected day
  void changeSelectedDay(DateTime day) {
    selectedDay.value = day;
    focusedDay.value = day;
    updateSelectedEvents();
  }

  // Change calendar format
  void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  // Change focused day
  void changeFocusedDay(DateTime day) {
    focusedDay.value = day;
  }

  // Add new care schedule
  void addCareSchedule() {
    if (titleController.text.isEmpty) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final selectedType = careTypes[selectedTypeIndex.value];

    final newSchedule = CareScheduleItem(
      id: newId,
      title: titleController.text,
      description: descriptionController.text,
      time: timeController.text.isEmpty ? '08:00' : timeController.text,
      type: selectedType['name'],
      icon: selectedType['icon'],
      color: selectedType['color'],
    );

    final normalizedDay = DateTime(
        selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);

    final updatedEvents =
        Map<DateTime, List<CareScheduleItem>>.from(careEvents.value);

    if (updatedEvents[normalizedDay] != null) {
      updatedEvents[normalizedDay]!.add(newSchedule);
    } else {
      updatedEvents[normalizedDay] = [newSchedule];
    }

    careEvents.value = updatedEvents;

    // Reset form
    titleController.clear();
    descriptionController.clear();
    timeController.clear();
    isAddingSchedule.value = false;
    selectedTypeIndex.value = 0;

    // Update view
    updateSelectedEvents();
  }

  // Toggle completed status
  void toggleCompleteStatus(String id) {
    final normalizedDay = DateTime(
        selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);

    final updatedEvents =
        Map<DateTime, List<CareScheduleItem>>.from(careEvents.value);

    if (updatedEvents[normalizedDay] != null) {
      final index =
          updatedEvents[normalizedDay]!.indexWhere((item) => item.id == id);
      if (index != -1) {
        updatedEvents[normalizedDay]![index].isCompleted =
            !updatedEvents[normalizedDay]![index].isCompleted;

        careEvents.value = updatedEvents;
        updateSelectedEvents();
      }
    }
  }

  // Delete schedule
  void deleteSchedule(String id) {
    final normalizedDay = DateTime(
        selectedDay.value.year, selectedDay.value.month, selectedDay.value.day);

    final updatedEvents =
        Map<DateTime, List<CareScheduleItem>>.from(careEvents.value);

    if (updatedEvents[normalizedDay] != null) {
      updatedEvents[normalizedDay]!.removeWhere((item) => item.id == id);
      careEvents.value = updatedEvents;
      updateSelectedEvents();
    }
  }

  // Show schedule detail
  void showScheduleDetail(CareScheduleItem item) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with color from item
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 30,
                        color: item.color,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: item.color,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Date and time
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today_rounded,
                      title: "Tanggal",
                      value:
                          "${selectedDay.value.day}/${selectedDay.value.month}/${selectedDay.value.year}",
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.access_time_rounded,
                      title: "Waktu",
                      value: item.time,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Description
              _buildDetailItem(
                icon: Icons.description_outlined,
                title: "Deskripsi",
                value: item.description,
                color: Color(0xFF4CAF50),
                isMultiLine: true,
              ),

              SizedBox(height: 25),

              // Action buttons
              Row(
                children: [
                  // Delete button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        deleteSchedule(item.id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        side: BorderSide(color: Colors.red[400]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Hapus"),
                    ),
                  ),
                  SizedBox(width: 15),
                  // Complete/Incomplete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        toggleCompleteStatus(item.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isCompleted
                            ? Colors.orange[400]
                            : Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        item.isCompleted ? "Belum Selesai" : "Tandai Selesai",
                      ),
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

  // Build detail item widget for dialog
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isMultiLine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
            maxLines: isMultiLine ? 5 : 1,
            overflow: isMultiLine ? TextOverflow.ellipsis : TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}
