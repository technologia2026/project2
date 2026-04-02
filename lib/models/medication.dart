  // lib/models/medication.dart
  class Medication {
    String id;
    String name;
    List<int> selectedDays; // [1, 2, 3] -> 월, 화, 수
    List<String> doseTimes; // ["08:30", "13:00"]
    Map<String, bool> completionStatus; // "2023-10-27_08:30": true

    Medication({
      required this.id,
      required this.name,
      required this.selectedDays,
      required this.doseTimes,
      required this.completionStatus,
    });

    // JSON 변환 (저장용)
    Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'selectedDays': selectedDays,
      'doseTimes': doseTimes,
      'completionStatus': completionStatus,
    };

    // JSON에서 복구 (불러오기용)
    factory Medication.fromJson(Map<String, dynamic> json) => Medication(
      id: json['id'],
      name: json['name'],
      selectedDays: List<int>.from(json['selectedDays']),
      doseTimes: List<String>.from(json['doseTimes']),
      completionStatus: Map<String, bool>.from(json['completionStatus']),
    );
  }