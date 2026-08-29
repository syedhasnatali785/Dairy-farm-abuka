class Owner {
  final int? id;
  final String name;
  final String farmName;
  final String phone;
  final String address;
  final double prediction;
  final bool onboardingCompleted;

  Owner({
    this.id,
    required this.name,
    required this.farmName,
    required this.phone,
    required this.address,
    required this.prediction,
    this.onboardingCompleted = true,
  });

  Owner copyWith({
    int? id,
    String? name,
    String? farmName,
    String? phone,
    String? address,
    double? prediction,
    bool? onboardingCompleted,
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      farmName: farmName ?? this.farmName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      prediction: prediction ?? this.prediction,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'farmName': farmName,
      'phone': phone,
      'address': address,
      'prediction': prediction,
      'onboardingCompleted': onboardingCompleted ? 1 : 0,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    final completedValue = map['onboardingCompleted'];
    final bool completed;

    if (completedValue is bool) {
      completed = completedValue;
    } else if (completedValue is int) {
      completed = completedValue == 1;
    } else if (completedValue is String) {
      completed = completedValue.toLowerCase() == 'true';
    } else {
      completed = true;
    }

    return Owner(
      id: map['id'],
      name: map['name'] ?? '',
      farmName: map['farmName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      prediction: (map['prediction'] as num?)?.toDouble() ?? 0.0,
      onboardingCompleted: completed,
    );
  }
}
