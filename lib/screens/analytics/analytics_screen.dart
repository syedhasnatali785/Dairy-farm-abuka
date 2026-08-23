import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;

  double _production = 0;
  double _sold = 0;
  double _remaining = 0;
  double _revenue = 0;

  int _boughtCustomers = 0;
  int _notBoughtCustomers = 0;
  int _daysRecorded = 0;
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(now);
      final productionResult = await db.rawQuery(
        '''
SELECT COALESCE(SUM(totalProduction),0) AS total FROM milk_entry WHERE date>= ? AND date<=?
''',
        [startDate, endDate],
      );
      final soldResult = await db.rawQuery(
        '''
SELECT COALESCE(SUM(d.deliveredMilk),0) AS total FROM milk_delivery d INNER JOIN milk_entry e ON e.id = d.milkEntryId WHERE e.date <=? AND e.date>=?  AND d.bought =1
''',
        [startDate, endDate],
      );
      final revenueResult = await db.rawQuery(
        '''
        SELECT
          COALESCE(
            SUM(d.deliveredMilk * d.pricePerLiter),
            0
          ) AS total
        FROM milk_delivery d
        INNER JOIN milk_entry e
          ON e.id = d.milkEntryId
        WHERE e.date >= ?
          AND e.date <= ?
          AND d.bought = 1
        ''',
        [startDate, endDate],
      );
      final boughtResult = await db.rawQuery(
        '''
 SELECT COUNT(*) AS total
        FROM milk_delivery d
        INNER JOIN milk_entry e
          ON e.id = d.milkEntryId
        WHERE e.date >= ?
          AND e.date <= ?
          AND d.bought = 1
        ''',
        [startDate, endDate],
      );
      final notBoughtResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM milk_delivery d
        INNER JOIN milk_entry e
          ON e.id = d.milkEntryId
        WHERE e.date >= ?
          AND e.date <= ?
          AND d.bought = 0
        ''',
        [startDate, endDate],
      );
      final daysResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM milk_entry
        WHERE date >= ? AND date <= ?
        ''',
        [startDate, endDate],
      );
      final production = (productionResult.first['total'] as num).toDouble();

      final sold = (soldResult.first['total'] as num).toDouble();

      final revenue = (revenueResult.first['total'] as num).toDouble();

      final bought = (boughtResult.first['total'] as num).toInt();

      final notBought = (notBoughtResult.first['total'] as num).toInt();

      final days = (daysResult.first['total'] as num).toInt();
      if (!mounted) return;
      setState(() {
        _production = production;
        _sold = sold;
        _remaining = production - sold;
        _revenue = revenue;
        _boughtCustomers = bought;
        _notBoughtCustomers = notBought;
        _daysRecorded = days;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
    }
  }

  String _liters(double value) {
    return '${value.toStringAsFixed(1)} L';
  }

  String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  double get _averageProduction {
    if (_daysRecorded == 0) return 0;

    return _production / _daysRecorded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _stat('Total Production', _liters(_production)),

                  _stat('Total Milk Sold', _liters(_sold)),

                  _stat('Remaining Milk', _liters(_remaining)),

                  _stat('Total Revenue', _money(_revenue)),

                  _stat(
                    'Average Daily Production',
                    _liters(_averageProduction),
                  ),

                  _stat('Days Recorded', '$_daysRecorded'),

                  const SizedBox(height: 20),

                  const Text(
                    'Customer Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  _stat('Milk Bought', '$_boughtCustomers deliveries'),

                  _stat('Milk Not Bought', '$_notBoughtCustomers deliveries'),
                ],
              ),
            ),
    );
  }
}

Widget _stat(String title, String value) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
