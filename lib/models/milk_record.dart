class MilkRecord {
  final int? id;
  final String date;
  final int customerId;
  final double deliveredMilk;
  final double totalProduction;
  final double pricePerLiter;
  final bool bought;

  MilkRecord({
    this.id,
    required this.date,
    required this.customerId,
    required this.deliveredMilk,
    required this.totalProduction,
    required this.pricePerLiter,
    required this.bought,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customerId': customerId,
      'deliveredMilk': deliveredMilk,
      'totalProduction': totalProduction,
      'pricePerLiter': pricePerLiter,
      'bought': bought ? 1 : 0,
    };
  }

  factory MilkRecord.fromMap(Map<String, dynamic> map) {
    return MilkRecord(
      id: map['id'],
      date: map['date'],
      customerId: map['customerId'],
      deliveredMilk: (map['deliveredMilk'] as num).toDouble(),
      totalProduction: (map['totalProduction'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      bought: map['bought'] == 1,
    );
  }
}
