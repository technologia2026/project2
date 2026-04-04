// lib/models/medication.dart
class Medication {
  String id;
  String name;
  String type;   // 💊 추가됨: 약 종류 (알약, 가루약 등)
  String dosage; // 💊 추가됨: 복용량 (1정, 1포 등)
  List<int> selectedDays; // [1, 2, 3] -> 월, 화, 수
  List<String> doseTimes; // ["08:30", "13:00"]
  Map<String, bool> completionStatus; // "2023-10-27_08:30": true

  Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.dosage,
    required this.selectedDays,
    required this.doseTimes,
    required this.completionStatus,
  });

  // JSON 변환 (저장용)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'dosage': dosage,
    'selectedDays': selectedDays,
    'doseTimes': doseTimes,
    'completionStatus': completionStatus,
  };

  // JSON에서 복구 (불러오기용)
  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'],
    name: json['name'],
    // 💡 기존에 저장된 데이터가 있을 경우 에러 방지를 위해 기본값('알약', '1정') 설정
    type: json['type'] ?? '알약', 
    dosage: json['dosage'] ?? '1정',
    selectedDays: List<int>.from(json['selectedDays']),
    doseTimes: List<String>.from(json['doseTimes']),
    completionStatus: Map<String, bool>.from(json['completionStatus']),
  );
}