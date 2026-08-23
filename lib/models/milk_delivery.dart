class MilkDelivery {
  final int? id;
  final int milkEntryId;
  final int customerId;
  final double deliveredMilk;
  final double pricePerLiter;
  final bool bought;

  MilkDelivery({
    this.id,
    required this.milkEntryId,
    required this.customerId,
    required this.deliveredMilk,
    required this.pricePerLiter,
    required this.bought,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'milkEntryId': milkEntryId,
      'customerId': customerId,
      'deliveredMilk': deliveredMilk,
      'pricePerLiter': pricePerLiter,
      'bought': bought ? 1 : 0,
    };
  }

  factory MilkDelivery.fromMap(Map<String, dynamic> map) {
    return MilkDelivery(
      id: map['id'],
      milkEntryId: map['milkEntryId'],
      customerId: map['customerId'],
      deliveredMilk: (map['deliveredMilk'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      bought: map['bought'] == 1,
    );
  }
}
