// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; 
import 'screens/settings_screen.dart'; 
import 'screens/history_screen.dart'; // 💡 1. 새로 만든 기록 화면을 임포트합니다!
import 'services/notification_service.dart'; // 👈 이거 추가
import 'package:flutter/foundation.dart';

void main() async {
  // 1. 플러터 엔진과 위젯 바인딩 초기화 (앱 실행 전 세팅할 때 필수)
  WidgetsFlutterBinding.ensureInitialized(); 
  
if (!kIsWeb) { 
    try {
      await NotificationService().init();
      await NotificationService().requestPermissions();
    } catch (e) {
      print("알림 초기화 실패 (모바일 아님): $e");
    }
  }

  // 3. 앱 실행
  runApp(
    const MaterialApp(
      home: MainNavigation(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  // 💡 2. _pages 리스트의 1번 인덱스를 HistoryScreen으로 교체합니다!
  final List<Widget> _pages = [
    const YakShotUI(),
    const HistoryScreen(), // <- 여기를 바꿨어요!
    const SettingsScreen(),
  ];

// ... (아래 코드는 기존과 동일) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '기록'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
        ],
      ),
    );
  }
}