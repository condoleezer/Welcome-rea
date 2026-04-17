class Patient {
  int id;
  String bedNumber;
  List<String> needs;

  Patient({
    required this.id,
    required this.bedNumber,
    required this.needs,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? 0, // Utilisez une valeur par défaut appropriée
      bedNumber: json['bedNumber'] ?? '',
      needs: List<String>.from(json['needs'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedNumber': bedNumber,
      'needs': needs,
    };
  }
}
