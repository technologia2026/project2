// lib/screens/alarm_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/medication.dart';

class AlarmScreen extends StatefulWidget {
  final Medication medication;
  final String doseTime; // "08:30" 같은 시간 문자열

  const AlarmScreen({
    super.key,
    required this.medication,
    required this.doseTime,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // 기존 설정 화면의 세련된 폰트 스타일 정의 참고
  TextStyle _titleStyle({double size = 20, Color color = Colors.black}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.8,
    );
  }

  TextStyle _subStyle({double size = 14, Color color = Colors.black87}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      letterSpacing: -0.5,
    );
  }

  // 💊 [먹었습니다] 버튼 로직 (기존 홈 화면 로직 참고)
  Future<void> _completeDose() async {
    final now = DateTime.now();
    String dateKey = DateFormat('yyyy-MM-dd').format(now);
    String key = "${dateKey}_${widget.doseTime}";

    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      List<Medication> allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
      
      int index = allMeds.indexWhere((m) => m.id == widget.medication.id);
      if (index != -1) {
        // 복용 완료 상태로 변경
        allMeds[index].completionStatus[key] = true;
        await prefs.setString('medications', jsonEncode(allMeds.map((m) => m.toJson()).toList()));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('💊 ${widget.medication.name} 복용을 완료했습니다!')),
          );
          // 알람 화면 닫고 앱 종료 (또는 홈 화면으로 이동)
          Navigator.pop(context); 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 기존 홈 화면의 브랜드 그라데이션 색상 참고
    const brandColor1 = Color(0xFF667eea);
    const brandColor2 = Color(0xFF764ba2);

    final now = DateTime.now();
    String formattedTime = DateFormat('HH:mm').format(now);
    String formattedDate = DateFormat('M월 d일 (E)', 'ko_KR').format(now); // 한국어 요일 표시

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // 아주 연한 블루톤 배경
      body: Container(
        // 상단 그라데이션 배경 (기존 SummaryCard 디자인 참고)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [brandColor1, brandColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 현재 시간 및 날짜 표시 (세련된 타이포그래피)
              Text(formattedDate, style: _subStyle(size: 16, color: Colors.white70)),
              const SizedBox(height: 10),
              Text(formattedTime, style: _titleStyle(size: 60, color: Colors.white)),
              const SizedBox(height: 50),

              // 2. 약 정보 카드 (기존 MedItem 디자인 참고 및 강화)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 아이콘 및 이름
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFF0F2FF),
                          child: const Icon(Icons.medication_liquid_rounded, color: brandColor1, size: 35),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('지금 드실 약은', style: _subStyle(color: Colors.grey)),
                              const SizedBox(height: 5),
                              Text(widget.medication.name, style: _titleStyle(size: 24)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40, thickness: 1),
                    // 약 종류 및 복용량
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoTag(Icons.category_outlined, widget.medication.type),
                        _buildInfoTag(Icons.balance_outlined, widget.medication.dosage),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // 3. 커다란 복용 완료 버튼 (기존 SummaryCard의 진도율 바 색상 참고)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 흰색 버튼으로 강조
                      foregroundColor: brandColor1,
                      elevation: 10,
                      shadowColor: brandColor1.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _completeDose, // 복용 완료 로직 연결
                    child: Text('💊 먹었습니다!', style: _titleStyle(size: 20, color: brandColor1)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. 나중에 버튼 (사용자를 위한 유연성)
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text('나중에 (5분 뒤 다시 알림)', style: _subStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 약 정보 태그 위젯 조립
  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF667eea), size: 18),
          const SizedBox(width: 8),
          Text(text, style: _subStyle(color: const Color(0xFF667eea))),
        ],
      ),
    );
  }
}