// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _vibration = true;

  // 폰트 스타일 정의 (자간 조절로 세련미 추가)
  TextStyle _titleStyle({double size = 16, Color color = Colors.black}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.8, // 자간을 줄여서 더 단단한 느낌을 줌
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

  // 🔥 모든 데이터 초기화 전용 경고창 (모던 디자인)
  Future<void> _showResetWarning() async {
    bool? confirm = await showDialog(
      context: context,
      barrierDismissible: false, // 배경 클릭해서 끄기 방지
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('데이터 초기화', style: _titleStyle(size: 20)),
          ],
        ),
        content: Text(
          '정말로 모든 데이터를 삭제하시겠습니까?\n이 작업은 절대로 되돌릴 수 없으며, 모든 복용 기록이 영구적으로 삭제됩니다.',
          style: _subStyle(color: Colors.black54),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: _subStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('네, 삭제할게요', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 데이터가 초기화되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor1 = Color(0xFF667eea);
    const brandColor2 = Color(0xFF764ba2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // 아주 연한 블루톤 배경
      appBar: AppBar(
        title: Text("앱 설정", style: _titleStyle(size: 20)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // 1. 프리미엄 배너 (보호자 관리, 사진 인증 강조)
          _buildPremiumBanner(brandColor1, brandColor2),

          const SizedBox(height: 10),

          // 2. 알림 설정
          _buildSectionTitle('알림'),
          _buildSettingGroup([
            _buildSwitchTile('푸시 알림', '약 먹을 시간을 놓치지 않게 알려드려요', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _buildSwitchTile('진동', '알림 시 진동을 울립니다', _vibration, (v) => setState(() => _vibration = v)),
          ]),

          // 3. 앱 정보
          _buildSectionTitle('정보'),
          _buildSettingGroup([
            _buildListTile(Icons.info_outline, '앱 버전', trailing: const Text('v1.0.0')),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _buildListTile(Icons.policy_outlined, '이용약관 및 개인정보 처리방침'),
          ]),

          // 4. 데이터 관리 (위험)
          _buildSectionTitle('관리'),
          _buildSettingGroup([
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: Text("모든 데이터 초기화", style: _subStyle(color: Colors.redAccent)),
              onTap: _showResetWarning, // 강화된 경고창 연결
            ),
          ]),

          const SizedBox(height: 40),
          Center(child: Text('YakShot ver 1.0.0', style: _subStyle(size: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  // --- 위젯 조립 부품들 ---

  Widget _buildPremiumBanner(Color c1, Color c2) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: c1.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text('YakShot Premium', style: _titleStyle(size: 20, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 15),
          _buildPremiumFeature(Icons.family_restroom, '보호자 실시간 관리 기능'),
          _buildPremiumFeature(Icons.camera_alt, '복용 완료 사진 인증 시스템'),
          _buildPremiumFeature(Icons.analytics, '의사 제출용 월간 복용 리포트'),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(text, style: _subStyle(size: 13, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 24, bottom: 10),
      child: Text(title, style: _titleStyle(size: 14, color: Colors.grey)),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFFB)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: _subStyle()),
      subtitle: Text(sub, style: _subStyle(size: 12, color: Colors.grey)),
      value: val,
      activeColor: const Color(0xFF667eea),
      onChanged: onChanged,
    );
  }

  Widget _buildListTile(IconData icon, String title, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF667eea), size: 22),
      title: Text(title, style: _subStyle()),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}