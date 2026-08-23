class Owner {
  final int? id;
  final String name;
  final String farmName;
  final String phone;
  final String address;
  final double prediction;

  Owner({
    this.id,
    required this.name,
    required this.farmName,
    required this.phone,
    required this.address,
    required this.prediction,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'farmName': farmName,
      'phone': phone,
      'address': address,
      'prediction': prediction,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    return Owner(
      id: map['id'],
      name: map['name'],
      farmName: map['farmName'],
      phone: map['phone'],
      address: map['address'],
      prediction: map['prediction'],
    );
  }
}
