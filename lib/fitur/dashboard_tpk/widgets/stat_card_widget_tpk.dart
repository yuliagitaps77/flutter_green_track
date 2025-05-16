import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatCardWidgetTPK extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final List<FlSpot> spots;
  final Color color;
  final Animation<double> breathingAnimation;
  final VoidCallback onTap;

  const StatCardWidgetTPK({
    Key? key,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.spots,
    required this.color,
    required this.breathingAnimation,
    required this.onTap,
  }) : super(key: key);

  String _formatChartDate(double value) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: (6 - value).toInt()));
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: breathingAnimation,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              final cardPadding = isSmallScreen ? 12.0 : 15.0;

              return Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15 * breathingAnimation.value),
                      blurRadius: 10 * breathingAnimation.value,
                      offset: Offset(0, 3),
                      spreadRadius: 1 * (breathingAnimation.value - 0.92) * 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: isSmallScreen ? 14 : 16,
                            color: color,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Chart Section
                    if (spots.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 12 : 15),
                      Container(
                        height: isSmallScreen ? 60 : 80,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        _formatChartDate(value),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isSmallScreen ? 8 : 9,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 12,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isSmallScreen ? 8 : 9,
                                        fontFamily: 'Poppins',
                                      ),
                                    );
                                  },
                                  reservedSize: 15,
                                  interval: _calculateInterval(spots),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minY: 0,
                            maxY: _calculateMaxY(spots),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: color,
                                barWidth: isSmallScreen ? 2.0 : 2.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: isSmallScreen ? 2.5 : 3,
                                      color: Colors.white,
                                      strokeWidth: isSmallScreen ? 1.5 : 2,
                                      strokeColor: color,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withOpacity(0.3),
                                      color.withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipRoundedRadius: 8,
                                tooltipBorder: BorderSide(
                                  color: color.withOpacity(0.2),
                                  width: 1,
                                ),
                                tooltipPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                tooltipMargin: 6,
                                getTooltipItems:
                                    (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toInt()} (${_formatChartDate(spot.x)})',
                                      TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 10 : 12,
                                        fontFamily: 'Poppins',
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Trend Section
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    Text(
                      trend,
                      style: TextStyle(
                        color: color,
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _calculateInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxY <= 5 ? 1 : (maxY / 5).ceil().toDouble();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 5;
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxY <= 5 ? 5 : (maxY * 1.2).ceilToDouble();
  }
}
