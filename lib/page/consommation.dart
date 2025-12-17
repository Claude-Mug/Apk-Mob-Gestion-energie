import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class EnergyDataService {
  static final EnergyDataService _instance = EnergyDataService._internal();
  factory EnergyDataService() => _instance;
  EnergyDataService._internal();

  Future<void> saveDailyData(double energyWh, double cost) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = DateFormat('yyyy-MM-dd').format(now);
      
      // Sauvegarder les données du jour
      final dayData = {
        'energy': energyWh,
        'cost': cost,
        'date': todayKey,
        'formatted_date': DateFormat('EEE dd MMM', 'fr_FR').format(now),
        'full_date': DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(now),
      };
      
      // Ajouter aux 7 derniers jours
      final historyString = prefs.getString('energy_history') ?? '{}';
      Map<String, dynamic> historyData = json.decode(historyString);
      historyData[todayKey] = dayData;
      
      // Garder seulement 7 jours
      final entries = historyData.entries.toList();
      entries.sort((a, b) => b.key.compareTo(a.key));
      final recentData = Map.fromEntries(entries.take(7));
      await prefs.setString('energy_history', json.encode(recentData));
      
      // Mettre à jour les semaines
      await _updateWeeklyData(dayData, now);
      
    } catch (e) {
      print('Erreur sauvegarde: $e');
    }
  }

  Future<void> _updateWeeklyData(Map<String, dynamic> dayData, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekStart = _findFirstDayOfWeek(date);
      final weekKey = '${DateFormat('yyyy').format(weekStart)}-W${DateFormat('w').format(weekStart)}';
      
      final weeklyString = prefs.getString('weekly_data') ?? '{}';
      Map<String, dynamic> weeklyData = json.decode(weeklyString);
      
      if (weeklyData[weekKey] == null) {
        weeklyData[weekKey] = {
          'total_energy': 0.0,
          'total_cost': 0.0,
          'days': [],
          'week_label': 'Sem ${DateFormat('dd/MM').format(weekStart)}',
        };
      }
      
      weeklyData[weekKey]['total_energy'] = 
          (weeklyData[weekKey]['total_energy'] as num).toDouble() + (dayData['energy'] ?? 0.0);
      weeklyData[weekKey]['total_cost'] = 
          (weeklyData[weekKey]['total_cost'] as num).toDouble() + (dayData['cost'] ?? 0.0);
      weeklyData[weekKey]['days'].add(dayData);
      
      // Garder seulement 4 semaines
      final weekEntries = weeklyData.entries.toList();
      weekEntries.sort((a, b) => b.key.compareTo(a.key));
      final recentWeeks = Map.fromEntries(weekEntries.take(4));
      await prefs.setString('weekly_data', json.encode(recentWeeks));
      
    } catch (e) {
      print('Erreur mise à jour semaines: $e');
    }
  }

  DateTime _findFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<Map<String, dynamic>> getHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('energy_history') ?? '{}';
      return json.decode(historyString);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getWeeklyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weeklyString = prefs.getString('weekly_data') ?? '{}';
      return json.decode(weeklyString);
    } catch (e) {
      return {};
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('energy_history');
      await prefs.remove('weekly_data');
    } catch (e) {
      print('Erreur suppression: $e');
    }
  }

  Future<Map<String, dynamic>> getTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalString = prefs.getString('total_consumption') ?? '{}';
      return json.decode(totalString);
    } catch (e) {
      return {};
    }
  }
}

class EnergyPage extends StatefulWidget {
  const EnergyPage({Key? key}) : super(key: key);

  @override
  _EnergyPageState createState() => _EnergyPageState();
}

class _EnergyPageState extends State<EnergyPage> {
  Map<String, dynamic> _todayData = {};
  Map<String, dynamic> _historyData = {};
  Map<String, dynamic> _weeklyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
  }

  Future<void> _loadEnergyData() async {
    try {
      final todayData = await EnergyDataService().getTodayData();
      final historyData = await EnergyDataService().getHistoryData();
      final weeklyData = await EnergyDataService().getWeeklyData();

      setState(() {
        _todayData = todayData;
        _historyData = historyData;
        _weeklyData = weeklyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    await EnergyDataService().clearHistory();
    setState(() {
      _historyData = {};
      _weeklyData = {};
    });
  }

  Widget _buildTodaySection() {
    final totalEnergy = (_todayData['total_wh'] ?? 0.0).toDouble();
    final totalCost = (_todayData['total_fbu'] ?? 0.0).toDouble();
    final now = DateTime.now();
    final todayDate = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(now);

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'AUJOURD\'HUI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              todayDate,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Énergie', '${totalEnergy.toStringAsFixed(1)} Wh', Colors.blue),
                _buildStatItem('Coût', '${totalCost.toStringAsFixed(0)} FBu', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_historyData.isEmpty) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Aucun historique\nLes données apparaîtront après reset',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final entries = _historyData.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7 DERNIERS JOURS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: _clearHistory,
                  child: Text(
                    'SUPPRIMER',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...entries.map((entry) => _buildHistoryItem(entry)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MapEntry<String, dynamic> entry) {
    final energy = (entry.value['energy'] ?? 0.0).toDouble();
    final cost = (entry.value['cost'] ?? 0.0).toDouble();
    final date = entry.value['formatted_date'] ?? '';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Row(
            children: [
              Text(
                '${energy.toStringAsFixed(1)} Wh',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(width: 16),
              Text(
                '${cost.toStringAsFixed(0)} FBu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySection() {
    if (_weeklyData.isEmpty) {
      return SizedBox();
    }

    final entries = _weeklyData.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4 DERNIÈRES SEMAINES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ...entries.map((entry) => _buildWeekItem(entry)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekItem(MapEntry<String, dynamic> entry) {
    final energy = (entry.value['total_energy'] ?? 0.0).toDouble();
    final cost = (entry.value['total_cost'] ?? 0.0).toDouble();
    final weekLabel = entry.value['week_label'] ?? '';
    final days = (entry.value['days'] as List?)?.length ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weekLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              Text(
                '$days jour${days > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${energy.toStringAsFixed(0)} Wh',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '${cost.toStringAsFixed(0)} FBu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique Énergétique'),
        backgroundColor: Color.fromARGB(255, 95, 177, 244),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEnergyData,
              child: ListView(
                children: [
                  _buildTodaySection(),
                  SizedBox(height: 16),
                  _buildHistorySection(),
                  SizedBox(height: 16),
                  _buildWeeklySection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}