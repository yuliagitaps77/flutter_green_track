import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/jadwal_perawatan/controller/controller_plant_schedule.dart';
import 'package:get/get.dart';
import '../../controllers/jadwal_perawatan/jadwal_perawatan_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class PlantCareScheduleScreen extends StatelessWidget {
  static const routeName = '/PlantCareScheduleScreen';
  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(PlantCareController());

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F9F5),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(),

                // Calendar
                _buildCalendar(controller),

                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 20),
                ),

                // Schedule list
                _buildScheduleList(controller),
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            right: 20,
            bottom: 20,
            child: _buildAddButton(controller),
          ),

          // Form overlay
          Obx(() => controller.isAddingSchedule.value
              ? _buildAddScheduleForm(context, controller)
              : SizedBox.shrink()),
        ],
      ),
    );
  }

  // App Bar
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Icon(
                Icons.eco_outlined,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                "Jadwal Perawatan",
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          // Action button (filter)
          GestureDetector(
            onTap: () {
              // Show filter options
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calendar widget
  Widget _buildCalendar(PlantCareController controller) {
    return Obx(() => Container(
          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: controller.focusedDay.value,
            calendarFormat: controller.calendarFormat.value,
            eventLoader: controller.getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(controller.selectedDay.value, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              controller.changeSelectedDay(selectedDay);
            },
            onFormatChanged: (format) {
              controller.changeCalendarFormat(format);
            },
            onPageChanged: (focusedDay) {
              controller.changeFocusedDay(focusedDay);
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.red[300]),
            ),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: TextStyle(color: Color(0xFF4CAF50)),
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
  }

  // Schedule list
  Widget _buildScheduleList(PlantCareController controller) {
    return Expanded(
      child: Obx(() {
        if (controller.selectedEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 70,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 20),
                Text(
                  "Tidak ada jadwal perawatan",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Ketuk + untuk menambahkan jadwal baru",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
          physics: BouncingScrollPhysics(),
          itemCount: controller.selectedEvents.length,
          itemBuilder: (context, index) {
            final event = controller.selectedEvents[index];
            return _buildScheduleItem(controller, event);
          },
        );
      }),
    );
  }

  // Schedule item card
  Widget _buildScheduleItem(
      PlantCareController controller, CareScheduleItem item) {
    return AnimatedBuilder(
      animation: controller.breathingAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(item.isCompleted
                    ? 0.0
                    : 0.15 * controller.breathingAnimation.value),
                blurRadius: 10 * controller.breathingAnimation.value,
                offset: Offset(0, 3),
                spreadRadius: item.isCompleted
                    ? 0
                    : 1 * (controller.breathingAnimation.value - 0.92) * 3,
              ),
            ],
            border: Border.all(
              color: item.isCompleted
                  ? Colors.grey[300]!
                  : item.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Dismissible(
            key: Key(item.id),
            background: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              controller.deleteSchedule(item.id);
            },
            child: InkWell(
              onTap: () {
                // Show detail or edit
                controller.showScheduleDetail(item);
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        controller.toggleCompleteStatus(item.id);
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          color: item.isCompleted
                              ? item.color
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.isCompleted
                                ? item.color
                                : item.color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: item.isCompleted
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),

                    SizedBox(width: 15),

                    // Type icon
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: item.color,
                      ),
                    ),

                    SizedBox(width: 15),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: item.isCompleted
                                  ? Colors.grey
                                  : Colors.grey[800],
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: item.isCompleted
                                  ? Colors.grey
                                  : Colors.grey[600],
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color:
                                    item.isCompleted ? Colors.grey : item.color,
                              ),
                              SizedBox(width: 5),
                              Text(
                                item.time,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: item.isCompleted
                                      ? Colors.grey
                                      : item.color,
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(
                                      item.isCompleted ? 0.1 : 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: item.isCompleted
                                        ? Colors.grey
                                        : item.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Add button with breathing
  // Add button with breathing effect
  Widget _buildAddButton(PlantCareController controller) {
    return AnimatedBuilder(
      animation: controller.breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.breathingAnimation.value * 0.05 + 0.95,
          child: GestureDetector(
            onTap: () {
              controller.isAddingSchedule.value = true;
            },
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50)
                        .withOpacity(0.3 * controller.breathingAnimation.value),
                    blurRadius: 12 * controller.breathingAnimation.value,
                    offset: Offset(0, 5),
                    spreadRadius:
                        2 * (controller.breathingAnimation.value - 0.92) * 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  // Form tambah jadwal
  Widget _buildAddScheduleForm(
      BuildContext context, PlantCareController controller) {
    return GestureDetector(
      onTap: () {
        controller.isAddingSchedule.value = false;
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside the form
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tambah Jadwal Perawatan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            controller.isAddingSchedule.value = false;
                          },
                          icon: Icon(Icons.close),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Form fields
                    Text(
                      "Tanggal",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => controller.showDatePickerDialog(context),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 10),
                            Obx(() => Text(
                                  "${controller.selectedDay.value.day}/${controller.selectedDay.value.month}/${controller.selectedDay.value.year}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                )),
                            Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF4CAF50),
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 15),
                    Text(
                      "Waktu",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      controller: controller.timeController,
                      decoration: InputDecoration(
                        hintText: "contoh: 08:00",
                        prefixIcon: Icon(Icons.access_time_rounded,
                            color: Color(0xFF2E7D32)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      "Jenis Perawatan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.careTypes.length,
                        itemBuilder: (context, index) {
                          return Obx(() {
                            final isSelected =
                                controller.selectedTypeIndex.value == index;
                            return GestureDetector(
                              onTap: () {
                                controller.selectedTypeIndex.value = index;
                              },
                              child: Container(
                                width: 80,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? controller.careTypes[index]['color']
                                          .withOpacity(0.15)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? controller.careTypes[index]['color']
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      controller.careTypes[index]['icon'],
                                      size: 30,
                                      color: controller.careTypes[index]
                                          ['color'],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      controller.careTypes[index]['name'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? controller.careTypes[index]
                                                ['color']
                                            : Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      "Judul",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      controller: controller.titleController,
                      decoration: InputDecoration(
                        hintText: "contoh: Penyiraman Bibit Mahoni",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      "Deskripsi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      controller: controller.descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "contoh: Penyiraman rutin untuk bibit yang berusia 2 bulan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.all(15),
                      ),
                    ),

                    SizedBox(height: 25),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.addCareSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Simpan Jadwal",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
    );
  }
}

class ScheduleDetailPage extends StatelessWidget {
  static const routeName = '/ScheduleDetailPage';
  final CareScheduleItem scheduleItem;
  final PlantCareController controller;

  const ScheduleDetailPage({
    Key? key,
    required this.scheduleItem,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Jadwal",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F9F5),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with color from item
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheduleItem.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: scheduleItem.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        scheduleItem.icon,
                        size: 40,
                        color: scheduleItem.color,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheduleItem.type,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: scheduleItem.color,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            scheduleItem.title,
                            style: TextStyle(
                              fontSize: 22,
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

              SizedBox(height: 25),

              // Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: scheduleItem.isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      scheduleItem.isCompleted
                          ? Icons.check_circle_outline
                          : Icons.timelapse_rounded,
                      color: scheduleItem.isCompleted
                          ? Colors.green
                          : Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      scheduleItem.isCompleted ? "Selesai" : "Belum Dilakukan",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheduleItem.isCompleted
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Date and time section
              Text(
                "Informasi Waktu",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today_rounded,
                      title: "Tanggal",
                      value:
                          "${controller.selectedDay.value.day}/${controller.selectedDay.value.month}/${controller.selectedDay.value.year}",
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.access_time_rounded,
                      title: "Waktu Pelaksanaan",
                      value: scheduleItem.time,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 25),

              // Description section
              Text(
                "Deskripsi Kegiatan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 15),
              _buildDetailItem(
                icon: Icons.description_outlined,
                title: "Detail Perawatan",
                value: scheduleItem.description,
                color: Color(0xFF4CAF50),
                isMultiLine: true,
              ),

              SizedBox(height: 30),

              // Notes section (could be expanded in the future)
              Text(
                "Catatan Tambahan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Belum ada catatan tambahan",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  // Delete button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.deleteSchedule(scheduleItem.id);
                      },
                      icon: Icon(Icons.delete_outline),
                      label: Text("Hapus"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        side: BorderSide(color: Colors.red[400]!),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  // Complete/Incomplete button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.toggleCompleteStatus(scheduleItem.id);
                        Get.back();
                      },
                      icon: Icon(
                        scheduleItem.isCompleted
                            ? Icons.replay
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        scheduleItem.isCompleted
                            ? "Tandai Belum Selesai"
                            : "Tandai Selesai",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheduleItem.isCompleted
                            ? Colors.orange[400]
                            : Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  // Detail item widget for information display
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
            maxLines: isMultiLine ? null : 1,
            overflow:
                isMultiLine ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
