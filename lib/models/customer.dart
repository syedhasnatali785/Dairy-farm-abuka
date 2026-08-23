class Customer {
  final int? id;
  final String? firebaseId;

  final String name;
  final String phone;
  final String address;
  final double dailyMilk;
  final double pricePerLiter;
  final String customerType;
  final bool isActive;

  Customer({
    this.id,
    this.firebaseId,

    required this.name,
    required this.phone,
    required this.address,
    required this.dailyMilk,
    required this.pricePerLiter,
    required this.customerType,
    this.isActive = true,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'dailyMilk': dailyMilk,
      'pricePerLiter': pricePerLiter,
      'customerType': customerType,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      dailyMilk: (map['dailyMilk'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      customerType: map['customerType'],
      isActive: map['isActive'] == 1,
    );
  }
  factory Customer.fromFirestore(String documentId, Map<String, dynamic> data) {
    return Customer(
      firebaseId: documentId,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String,
      address: data['address'] as String,
      dailyMilk: _toDouble(data['dailyMilk']),
      pricePerLiter: _toDouble(data['pricePerLiter']),
      customerType: data['customerType'] as String? ?? 'Daily',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'dailyMilk': dailyMilk,
      'pricePerLiter': pricePerLiter,
      'customerType': customerType,
      'isActive': isActive,
    };
  }

  Customer copyWith({
    int? id,
    String? firebaseId,
    String? name,
    String? phone,
    String? address,
    double? dailyMilk,
    double? pricePerLiter,
    String? customerType,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dailyMilk: dailyMilk ?? this.dailyMilk,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      customerType: customerType ?? this.customerType,
      isActive: isActive ?? this.isActive,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
