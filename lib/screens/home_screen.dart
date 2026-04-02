// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import '../models/medication.dart';
import 'add_medication_screen.dart';

class YakShotUI extends StatefulWidget {
  const YakShotUI({super.key});
  @override
  State<YakShotUI> createState() => _YakShotUIState();
}

class _YakShotUIState extends State<YakShotUI> {
  List<Medication> _displayMeds = [];
  DateTime _selectedDate = DateTime.now(); // 현재 보고 있는 날짜
  String _currentTime = "";
  Timer? _timer;
  
  int _totalDoses = 0;
  int _completedDoses = 0;

  @override
  void initState() {
    super.initState();
    _loadMedsForDate();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    String formatted = DateFormat('HH:mm').format(now);
    if (_currentTime != formatted) {
      setState(() => _currentTime = formatted);
      _checkAlarms(formatted);
    }
  }

  // 선택된 날짜에 맞는 약 불러오기
  Future<void> _loadMedsForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      List<Medication> allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
      
      int weekday = _selectedDate.weekday;
      setState(() {
        _displayMeds = allMeds.where((m) => m.selectedDays.contains(weekday)).toList();
      });
      _calculateProgress();
    }
  }

  // 선택된 날짜의 진도율 계산
  void _calculateProgress() {
    int total = 0;
    int completed = 0;
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    for (var med in _displayMeds) {
      total += med.doseTimes.length;
      for (var time in med.doseTimes) {
        if (med.completionStatus["${dateKey}_$time"] == true) completed++;
      }
    }
    setState(() { _totalDoses = total; _completedDoses = completed; });
  }

  // 약 복용 체크 토글 로직
  Future<void> _toggleDose(Medication med, String time, bool isDone) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String key = "${dateKey}_$time";

    setState(() {
      med.completionStatus[key] = isDone;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      List<Medication> allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
      
      int index = allMeds.indexWhere((m) => m.id == med.id);
      if (index != -1) {
        allMeds[index].completionStatus[key] = isDone;
        await prefs.setString('medications', jsonEncode(allMeds.map((m) => m.toJson()).toList()));
      }
    }
    _calculateProgress(); 
  }

  // 약 삭제 로직
  Future<void> _deleteMedication(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      List<Medication> allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
      allMeds.removeWhere((m) => m.id == id);
      await prefs.setString('medications', jsonEncode(allMeds.map((m) => m.toJson()).toList()));
      _loadMedsForDate();
    }
  }

  // 알람 체크 (오늘 날짜일 때만 울림)
  void _checkAlarms(String currentTime) {
    final now = DateTime.now();
    // 달력을 다른 날로 넘겨보고 있을 때는 알람을 안 띄움
    if (_selectedDate.year != now.year || _selectedDate.month != now.month || _selectedDate.day != now.day) return;

    String dateKey = DateFormat('yyyy-MM-dd').format(now);
    for (var med in _displayMeds) {
      if (med.doseTimes.contains(currentTime)) {
        if (med.completionStatus["${dateKey}_$currentTime"] != true) {
          _showAlarmDialog(med, currentTime);
        }
      }
    }
  }

  void _showAlarmDialog(Medication med, String time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💊 ${med.name} 드실 시간!', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('$time입니다. 약을 복용하셨나요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('나중에')),
          ElevatedButton(
            onPressed: () {
              _toggleDose(med, time, true);
              Navigator.pop(context);
            },
            child: const Text('먹었습니다'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy년 MM월 dd일').format(_selectedDate);

    // 오늘인지 확인해서 '오늘' 표시 띄우기 위함
    final now = DateTime.now();
    bool isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('나의 약속', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667eea),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicationScreen()));
          _loadMedsForDate(); 
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            
            // 날짜 선택기 네비게이터
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, size: 30), onPressed: () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  _loadMedsForDate();
                }),
                Column(
                  children: [
                    Text(formattedDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isToday) 
                      const Text('오늘', style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.chevron_right, size: 30), onPressed: () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  _loadMedsForDate();
                }),
              ],
            ),
            
            const SizedBox(height: 10),
            Expanded(
              child: _displayMeds.isEmpty 
                ? const Center(child: Text("이날은 예정된 약이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    itemCount: _displayMeds.length,
                    itemBuilder: (context, index) => _buildMedItem(_displayMeds[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 요약 카드 (진도율)
  Widget _buildSummaryCard() {
    double progress = _totalDoses == 0 ? 0.0 : _completedDoses / _totalDoses;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('선택한 날짜의 복용 진도', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text('$_totalDoses회 중 $_completedDoses회 완료!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.white24, 
              color: Colors.white,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 개별 약 카드 
  Widget _buildMedItem(Medication med) {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFF0F2FF), child: Icon(Icons.medication, color: Color(0xFF667eea))),
                const SizedBox(width: 15),
                Expanded(child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                
                // 수정/삭제 메뉴
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => AddMedicationScreen(medicationToEdit: med)));
                      _loadMedsForDate();
                    } else if (value == 'delete') {
                      // 삭제 전 확인 창 띄우기
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('약 삭제'),
                          content: const Text('정말로 이 약을 삭제하시겠습니까?\n기존 복용 기록도 함께 사라집니다.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                _deleteMedication(med.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('삭제', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        )
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('설정 수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const Divider(),
            ...med.doseTimes.map((time) {
              String key = "${dateKey}_$time";
              bool isDone = med.completionStatus[key] ?? false;
              
              return InkWell(
                onTap: () => _toggleDose(med, time, !isDone),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time, style: TextStyle(
                        fontSize: 16, 
                        color: isDone ? Colors.grey : Colors.black87,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      )),
                      Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, 
                           color: isDone ? Colors.green : Colors.grey.shade300, size: 28),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}