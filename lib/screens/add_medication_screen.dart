// lib/screens/add_medication_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 스피너(스크롤) 픽커를 위해 추가
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';


class AddMedicationScreen extends StatefulWidget {
  final Medication? medicationToEdit;

  const AddMedicationScreen({super.key, this.medicationToEdit});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: "1정"); // 복용량 추가
  List<String> _doseTimes = [];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  String _selectedType = '알약'; // 약 종류 추가

  final List<String> _medTypes = ['알약', '캡슐', '가루약', '물약', '기타'];

@override
  void initState() {
    super.initState();
    if (widget.medicationToEdit != null) {
      _nameController.text = widget.medicationToEdit!.name;
      _selectedType = widget.medicationToEdit!.type; // 👈 이거 추가
      _dosageController.text = widget.medicationToEdit!.dosage; // 👈 이거 추가
      _doseTimes = List.from(widget.medicationToEdit!.doseTimes);
      _selectedDays = List.from(widget.medicationToEdit!.selectedDays);
    }
  }

Future<void> _saveMedication() async {
    if (_nameController.text.isEmpty || _doseTimes.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String? medsJson = prefs.getString('medications');
    List<Medication> allMeds = [];
    
    if (medsJson != null) {
      List<dynamic> decoded = jsonDecode(medsJson);
      allMeds = decoded.map((m) => Medication.fromJson(m)).toList();
    }

    // 💡 알림 등록에 사용할 '최종 약 데이터'를 담을 변수를 미리 만듭니다.
    late Medication medicationToSchedule;

    if (widget.medicationToEdit != null) {
      // 수정 모드
      int index = allMeds.indexWhere((m) => m.id == widget.medicationToEdit!.id);
      if (index != -1) {
        allMeds[index] = Medication(
          id: widget.medicationToEdit!.id,
          name: _nameController.text,
          type: _selectedType, 
          dosage: _dosageController.text, 
          doseTimes: _doseTimes,
          selectedDays: _selectedDays,
          completionStatus: widget.medicationToEdit!.completionStatus,
        );
        medicationToSchedule = allMeds[index]; // 수정한 데이터를 변수에 할당
      }
    } else {
      // 신규 추가 모드
      final newMed = Medication(
        id: const Uuid().v4(), 
        name: _nameController.text,
        type: _selectedType, 
        dosage: _dosageController.text, 
        doseTimes: _doseTimes,
        selectedDays: _selectedDays,
        completionStatus: {},
      );
      allMeds.add(newMed);
      medicationToSchedule = newMed; // 새로 만든 데이터를 변수에 할당
    }

    // 데이터 저장
    await prefs.setString('medications', jsonEncode(allMeds.map((m) => m.toJson()).toList()));
    
    // 🔔 드디어 안전하게 알림 스케줄 등록!
    // 위에서 만든 'medicationToSchedule'을 사용하니까 이제 에러가 안 날 거예요.
    await NotificationService().scheduleMedicationNotifications(medicationToSchedule);

    if (mounted) Navigator.pop(context);
  }

  // 구린 기본 픽커 대신 하단에서 올라오는 쿠퍼티노(아이폰 스타일) 픽커 사용
  void _showTimePickerBottomSheet() {
    DateTime tempTime = DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    const Text('시간 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          String formattedTime = "${tempTime.hour.toString().padLeft(2, '0')}:${tempTime.minute.toString().padLeft(2, '0')}";
                          if (!_doseTimes.contains(formattedTime)) {
                            _doseTimes.add(formattedTime);
                            _doseTimes.sort();
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('확인', style: TextStyle(color: Color(0xFF667eea), fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.medicationToEdit == null ? '새로운 약 추가' : '약 정보 수정', 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 약 이름 입력
            const Text("약 이름", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "예: 아침 혈압약, 멀티비타민",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // 2. 약 종류 선택 (새로 추가된 UI)
            const Text("형태", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _medTypes.map((type) {
                  bool isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                      selectedColor: const Color(0xFF667eea).withOpacity(0.2),
                      labelStyle: TextStyle(color: isSelected ? const Color(0xFF667eea) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.transparent)),
                      backgroundColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // 3. 1회 복용량 (새로 추가된 UI)
            const Text("1회 복용량", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(
                hintText: "예: 1정, 2포, 10ml",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // 4. 복용 요일
            const Text("복용 요일", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                int day = index + 1;
                bool isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(['월','화','수','목','금','토','일'][index]),
                  selected: isSelected,
                  selectedColor: const Color(0xFF667eea).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.transparent)),
                  backgroundColor: Colors.white,
                  onSelected: (val) {
                    setState(() => val ? _selectedDays.add(day) : _selectedDays.remove(day));
                  },
                );
              }),
            ),
            const SizedBox(height: 30),

            // 5. 복용 시간 (디자인 개선)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("알림 시간", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _showTimePickerBottomSheet, // 새로운 픽커 연결
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF667eea)),
                  label: const Text("시간 추가", style: TextStyle(color: Color(0xFF667eea))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_doseTimes.isEmpty)
               const Center(child: Text("복용 시간을 추가해주세요", style: TextStyle(color: Colors.grey))),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _doseTimes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.black54),
                  title: Text(_doseTimes[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), 
                    onPressed: () => setState(() => _doseTimes.removeAt(index))),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // 6. 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: _saveMedication,
                child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}