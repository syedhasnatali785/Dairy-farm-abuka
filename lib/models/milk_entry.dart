class MilkEntry {
  final int? id;
  final String date;
  final double totalProduction;

  MilkEntry({this.id, required this.date, required this.totalProduction});
  Map<String, dynamic> toMap() {
    return {'id': id, 'date': date, 'totalProduction': totalProduction};
  }

  factory MilkEntry.fromMap(Map<String, dynamic> map) {
    return MilkEntry(
      id: map['id'],
      date: map['date'],
      totalProduction: (map['totalProduction'] as num).toDouble(),
    );
  }
}
