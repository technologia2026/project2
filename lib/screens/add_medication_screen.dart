import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medicationToEdit;

  const AddMedicationScreen({super.key, this.medicationToEdit});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  List<String> _doseTimes = [];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    if (widget.medicationToEdit != null) {
      _nameController.text = widget.medicationToEdit!.name;
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

    if (widget.medicationToEdit != null) {
      int index = allMeds.indexWhere((m) => m.id == widget.medicationToEdit!.id);
      if (index != -1) {
        allMeds[index] = Medication(
          id: widget.medicationToEdit!.id,
          name: _nameController.text,
          doseTimes: _doseTimes,
          selectedDays: _selectedDays,
          completionStatus: widget.medicationToEdit!.completionStatus,
        );
      }
    } else {
      final newMed = Medication(
        id: Uuid().v4(), // 에러 없도록 const 제거된 깔끔한 상태
        name: _nameController.text,
        doseTimes: _doseTimes,
        selectedDays: _selectedDays,
        completionStatus: {},
      );
      allMeds.add(newMed);
    }

    await prefs.setString('medications', jsonEncode(allMeds.map((m) => m.toJson()).toList()));
    if (mounted) Navigator.pop(context);
  }

  void _addTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        _doseTimes.add("${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}");
        _doseTimes.sort();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 전체 배경색 유지
      appBar: AppBar(
        title: Text(widget.medicationToEdit == null ? '약 추가하기' : '약 설정 수정', 
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
            const Text("약 이름", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "예: 멀티비타민",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    setState(() => val ? _selectedDays.add(day) : _selectedDays.remove(day));
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("복용 시간", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text("시간 추가"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 복용 시간 리스트를 카드 안에 깔끔하게 정렬
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _doseTimes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text(_doseTimes[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), 
                    onPressed: () => setState(() => _doseTimes.removeAt(index))),
                ),
              ),
            ),
            const SizedBox(height: 50),
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