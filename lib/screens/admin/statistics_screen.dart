import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Statistics')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data?.docs ?? [];
          final totalClasses = classes.length;
          int totalStudents = 0;
          int totalAttendance = 0;

          // Calculate statistics
          for (var classDoc in classes) {
            final classData = classDoc.data() as Map<String, dynamic>;
            final attendedStudents =
                (classData['attendedStudentIds'] as List?)?.length ?? 0;
            totalAttendance += attendedStudents;
          }

          // Get total students count
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .snapshots(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.hasError) {
                return Center(child: Text('Error: ${studentSnapshot.error}'));
              }

              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              totalStudents = studentSnapshot.data?.docs.length ?? 0;
              final averageAttendance = totalClasses > 0 && totalStudents > 0
                  ? (totalAttendance / (totalClasses * totalStudents) * 100)
                        .toStringAsFixed(1)
                  : '0';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Classes',
                            totalClasses.toString(),
                            Icons.class_,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Students',
                            totalStudents.toString(),
                            Icons.people,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Average Attendance',
                            '$averageAttendance%',
                            Icons.insert_chart,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Attendance',
                            totalAttendance.toString(),
                            Icons.check_circle,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Attendance Trend Graph
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attendance Trend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildAttendanceTrendGraph(classes),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Class-wise Attendance
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class-wise Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildClassWiseAttendanceGraph(
                                classes,
                                totalStudents,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendGraph(List<QueryDocumentSnapshot> classes) {
    // Sort classes by date
    final sortedClasses = classes.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MapEntry(
        DateTime.parse(data['startTime'] as String),
        (data['attendedStudentIds'] as List?)?.length ?? 0,
      );
    }).toList()..sort((a, b) => a.key.compareTo(b.key));

    if (sortedClasses.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedClasses.length) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      DateFormat(
                        'MM/dd',
                      ).format(sortedClasses[value.toInt()].key),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: sortedClasses.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildClassWiseAttendanceGraph(
    List<QueryDocumentSnapshot> classes,
    int totalStudents,
  ) {
    if (classes.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalStudents.toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < classes.length) {
                  final classData =
                      classes[value.toInt()].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      classData['className']?.toString().substring(0, 3) ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: classes.asMap().entries.map((entry) {
          final classData = entry.value.data() as Map<String, dynamic>;
          final attendance =
              (classData['attendedStudentIds'] as List?)?.length ?? 0;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: attendance.toDouble(),
                color: Colors.purple,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
