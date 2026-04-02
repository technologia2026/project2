// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Medication> _allMeds = [];
  List<DailyRecord> _last7DaysRecord = [];
  double _weeklyAverage = 0.0;
  DateTime _focusedMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      _allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
    }

    // 1. 최근 7일 기록 계산
    List<DailyRecord> records = [];
    int totalWeeklyDoses = 0;
    int completedWeeklyDoses = 0;

    for (int i = 0; i < 7; i++) {
      DateTime targetDate = DateTime.now().subtract(Duration(days: i));
      String dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      int weekday = targetDate.weekday; 

      int dailyTotal = 0;
      int dailyCompleted = 0;

      for (var med in _allMeds) {
        if (med.selectedDays.contains(weekday)) {
          dailyTotal += med.doseTimes.length;
          for (var time in med.doseTimes) {
            String key = "${dateStr}_$time";
            if (med.completionStatus[key] == true) {
              dailyCompleted++;
            }
          }
        }
      }

      totalWeeklyDoses += dailyTotal;
      completedWeeklyDoses += dailyCompleted;

      records.add(DailyRecord(
        date: targetDate,
        totalDoses: dailyTotal,
        completedDoses: dailyCompleted,
      ));
    }

    setState(() {
      _last7DaysRecord = records;
      _weeklyAverage = totalWeeklyDoses == 0 ? 0.0 : completedWeeklyDoses / totalWeeklyDoses;
      _isLoading = false;
    });
  }

  // 2. 특정 날짜(달력용) 복용률 계산
  double _getCompletionRate(DateTime date) {
    String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    int weekday = date.weekday;
    int total = 0;
    int completed = 0;

    for (var med in _allMeds) {
      if (med.selectedDays.contains(weekday)) {
        total += med.doseTimes.length;
        for (var time in med.doseTimes) {
          if (med.completionStatus["${dateStr}_$time"] == true) {
            completed++;
          }
        }
      }
    }
    return total == 0 ? -1.0 : completed / total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('나의 복용 기록', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklySummaryCard(),
            const SizedBox(height: 25),
            
            const Text('최근 7일 상세 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // 스크롤 충돌을 막기 위해 ListView 대신 Column 사용
            Column(
              children: _last7DaysRecord.asMap().entries.map((entry) {
                return _buildDailyRecordCard(entry.value, entry.key == 0);
              }).toList(),
            ),
            const SizedBox(height: 35),
            
            const Text('월간 기록 달력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildCalendarSection(),
            const SizedBox(height: 15),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // --- 위젯 1: 주간 요약 카드 ---
  Widget _buildWeeklySummaryCard() {
    int percentage = (_weeklyAverage * 100).toInt();
    String message = "아주 잘하고 있어요! 👏";
    if (percentage < 50) message = "조금만 더 힘내볼까요? 💪";
    if (percentage == 100) message = "완벽해요! 건강 마스터! 👑";

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('최근 7일 달성률', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: CircularProgressIndicator(
                  value: _weeklyAverage,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF667eea),
                ),
              ),
              Text('$percentage%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
        ],
      ),
    );
  }

  // --- 위젯 2: 7일 리스트 카드 ---
  Widget _buildDailyRecordCard(DailyRecord record, bool isToday) {
    List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    String dayStr = weekdays[record.date.weekday - 1];
    
    double progress = record.totalDoses == 0 ? 0 : record.completedDoses / record.totalDoses;
    bool isPerfect = record.totalDoses > 0 && record.totalDoses == record.completedDoses;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF667eea) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(isToday ? '오늘' : dayStr, style: TextStyle(color: isToday ? Colors.white : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${record.date.day}', style: TextStyle(color: isToday ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(record.totalDoses == 0 ? '예정된 약 없음' : '${record.completedDoses} / ${record.totalDoses} 회 복용', 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isPerfect) const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: record.totalDoses == 0 ? 0 : progress,
                      backgroundColor: Colors.grey.shade200,
                      color: isPerfect ? Colors.green : const Color(0xFF667eea),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 위젯 3: 월간 달력 ---
  Widget _buildCalendarSection() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; 

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
              Text('${_focusedMonth.year}년 ${_focusedMonth.month}월', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['일','월','화','수','목','금','토'].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))).toList(),
          ),
          const Divider(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: daysInMonth + firstWeekday,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox(); 
              
              int day = index - firstWeekday + 1;
              DateTime date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              double rate = _getCompletionRate(date);
              
              bool isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 35, height: 35,
                    decoration: BoxDecoration(
                      color: _getCalendarColor(rate, date),
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: const Color(0xFF667eea), width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text('$day', style: TextStyle(
                      color: Colors.black,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                    )),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getCalendarColor(double rate, DateTime date) {
    if (date.isAfter(DateTime.now())) return Colors.transparent; 
    if (rate == -1.0) return Colors.grey.withOpacity(0.05); 
    if (rate == 1.0) return Colors.green.shade200; 
    if (rate >= 0.5) return Colors.orange.shade200; 
    if (rate > 0.0) return Colors.red.shade100; 
    return Colors.red.shade50; 
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green.shade200, "성공"),
        const SizedBox(width: 15),
        _legendItem(Colors.orange.shade200, "부분"),
        const SizedBox(width: 15),
        _legendItem(Colors.red.shade100, "미흡"),
        const SizedBox(width: 15),
        _legendItem(Colors.grey.shade200, "없음"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class DailyRecord {
  final DateTime date;
  final int totalDoses;
  final int completedDoses;

  DailyRecord({required this.date, required this.totalDoses, required this.completedDoses});
}   