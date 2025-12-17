import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class EnergyPage extends StatefulWidget {
  const EnergyPage({Key? key}) : super(key: key);

  @override
  State<EnergyPage> createState() => _EnergyPageState();
}

class _EnergyPageState extends State<EnergyPage> {
  String _selectedPeriod = '7 jours';
  late List<Map<String, dynamic>> _deviceData;
  late List<Map<String, dynamic>> _totalData;

  @override
  void initState() {
    super.initState();
    _simulateData();
  }

  void _simulateData() {
    final random = Random();
    final now = DateTime.now();
    int days = _selectedPeriod == '7 jours'
        ? 7
        : _selectedPeriod == '15 jours'
            ? 15
            : 30;

    List<String> devices = ['Frigo', 'Climatiseur', 'Lumières', 'TV', 'Pompe'];

    _deviceData = devices.map((device) {
      List<Map<String, dynamic>> history = [];
      double totalKwh = 0;
      double totalCost = 0;

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final kwh = random.nextDouble() * 5 + 1;
        final cost = kwh * 270;
        totalKwh += kwh;
        totalCost += cost;
        history.add({
          'date': DateFormat('dd/MM').format(date),
          'kwh': kwh,
          'cost': cost,
        });
      }

      return {
        'device': device,
        'history': history.reversed.toList(),
        'totalKwh': totalKwh,
        'totalCost': totalCost,
      };
    }).toList();

    _totalData = List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      double totalKwh = 0;
      double totalCost = 0;
      for (var device in _deviceData) {
        totalKwh += device['history'][i]['kwh'];
        totalCost += device['history'][i]['cost'];
      }
      return {
        'date': DateFormat('dd/MM').format(date),
        'kwh': totalKwh,
        'cost': totalCost,
      };
    }).reversed.toList();
  }

  Color _getBarColor(double kwh) {
    if (kwh < 2) return Colors.green;
    if (kwh < 4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildFilterButtons() {
    final filters = ['7 jours', '15 jours', '30 jours'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((f) {
          final selected = _selectedPeriod == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(f, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedPeriod = f;
                  _simulateData();
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeviceChart(Map<String, dynamic> deviceData) {
    final device = deviceData['device'];
    final data = deviceData['history'];
    final totalKwh = deviceData['totalKwh'];
    final totalCost = deviceData['totalCost'];

    // CORRECTION : Conversion explicite en List<BarChartGroupData>
    List<BarChartGroupData> barGroups = data.asMap().entries.map(
      (entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value['kwh'],
              color: _getBarColor(entry.value['kwh']),
              width: 10,
              borderRadius: BorderRadius.circular(2),
            )
          ],
        );
      },
    ).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(device,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blueAccent)),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: BarTouchData(enabled: false),
                // CORRECTION : Utilisation de la liste typée
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            data[value.toInt()]['date'],
                            style: const TextStyle(
                                color: Colors.black, fontSize: 8),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 8),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Total: ${totalKwh.toStringAsFixed(1)} kWh | ${totalCost.toInt()} FBu",
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalChart() {
    // CORRECTION : Conversion explicite pour LineChart
    List<FlSpot> spots = _totalData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['kwh'].toDouble());
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Consommation Totale",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.indigo),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    // CORRECTION : Utilisation de la liste typée
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 2,
                        color: Colors.blue,
                        strokeWidth: 1,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= _totalData.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _totalData[value.toInt()]['date'],
                            style: const TextStyle(fontSize: 8),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 8),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Total: ${_totalData.last['kwh'].toStringAsFixed(1)} kWh | ${_totalData.last['cost'].toInt()} FBu",
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _LegendItem(color: Colors.green, label: 'Faible'),
          SizedBox(width: 8),
          _LegendItem(color: Colors.orange, label: 'Moyenne'),
          SizedBox(width: 8),
          _LegendItem(color: Colors.red, label: 'Élevée'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de Consommation',
            style: TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 225, 227, 230),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          _buildFilterButtons(),
          _buildLegend(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTotalChart(),
                  ..._deviceData.map((device) => _buildDeviceChart(device))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}