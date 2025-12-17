import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ConsumptionDay {
  final String label;
  final double kwh;

  ConsumptionDay({required this.label, required this.kwh});
}

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int selectedTab = 0;
  final List<String> tabs = [
    'Jour',
    'Semaine',
    'Mois',
  ];

  final List<ConsumptionDay> history = [
    ConsumptionDay(label: "samedi 31 mai", kwh: 45.2),
    ConsumptionDay(label: "vendredi 30 mai", kwh: 62.8),
    ConsumptionDay(label: "jeudi 29 mai", kwh: 82.5),
    // Ajoutez d'autres jours ici
  ];

  final List<double> evolutionData = [80, 75, 70, 68, 65, 62, 60, 58, 55, 54, 53, 52];

  @override
  Widget build(BuildContext context) {
    double avgDay = history.isNotEmpty
        ? history.map((e) => e.kwh).reduce((a, b) => a + b) / history.length
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFA1763),
        elevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            // Ligne du haut : cercle + mini-cartes
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleProgressStat(
                  label: 'Moyenne/Jour',
                  value: avgDay,
                  maxValue: 100,
                  size: 90,
                  valueFontSize: 18,
                  labelFontSize: 12,
                ),
                const SizedBox(width: 12),
                // Mini-cartes sur deux lignes
                Column(
                  children: [
                    Row(
                      children: [
                        MiniCardMobile(
                          icon: Icons.flash_on,
                          label: 'Consommation',
                          selected: selectedTab == 0,
                        ),
                        const SizedBox(width: 8),
                        MiniCardMobile(
                          icon: Icons.show_chart,
                          label: 'Évolution',
                          selected: selectedTab == 1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        MiniCardMobile(
                          icon: Icons.bar_chart,
                          label: 'Diagramme',
                          selected: selectedTab == 2,
                        ),
                        const SizedBox(width: 8),
                        MiniCardMobile(
                          icon: Icons.star,
                          label: 'Top Appareils',
                          selected: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bouton arrondi
            SizedBox(
              width: 210,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA1763),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                ),
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text(
                  "Ajouter un objectif",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Barre d'onglets horizontale
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tabs.length, (index) {
                  final isSelected = index == selectedTab;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFA1763) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFA1763),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFFA1763),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
            // Contenu dynamique selon l'onglet sélectionné
            if (selectedTab == 0)
              CardContainer(
                title: 'Historique',
                content: EnergyHistoryCard(data: history),
              ),
            if (selectedTab == 1)
              CardContainer(
                title: 'Évolution de la consommation',
                content: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['J1', 'J2', 'J3', 'J4', 'J5', 'J6', 'J7', 'J8', 'J9', 'J10', 'J11', 'J12'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt() % days.length],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            evolutionData.length,
                            (i) => FlSpot(i.toDouble(), evolutionData[i]),
                          ),
                          isCurved: true,
                          color: const Color(0xFFFA1763),
                          barWidth: 4,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFFFB6C1).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (selectedTab == 2)
              CardContainer(
                title: 'Diagramme',
                content: ConsumptionDiagram(weeklyData: history.map((e) => e.kwh).toList()),
              ),
            if (selectedTab == 3)
              CardContainer(
                title: 'Top Appareils',
                content: const Text('1. Chauffage: 7.5 kWh\n2. Frigo: 4.2 kWh\n3. Four: 3.9 kWh'),
              ),
          ],
        ),
      ),
    );
  }
}

// Mini carte adaptée mobile
class MiniCardMobile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const MiniCardMobile({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 60,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFB6C1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFA1763), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFFFA1763), size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFFA1763),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Cercle de progression customisé
class CircleProgressStat extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final double size;
  final double valueFontSize;
  final double labelFontSize;

  const CircleProgressStat({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.size = 90,
    this.valueFontSize = 13,
    this.labelFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFA1763)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.toStringAsFixed(1)} kWh',
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFA1763),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Les widgets CardContainer, EnergyHistoryCard, ConsumptionDiagram restent inchangés
class CardContainer extends StatelessWidget {
  final String title;
  final Widget content;

  const CardContainer({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFFA1763),
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

class EnergyHistoryCard extends StatelessWidget {
  final List<ConsumptionDay> data;

  const EnergyHistoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...data.map((day) {
          Color barColor;
          if (day.kwh < 50) {
            barColor = const Color(0xFFB7E200); // vert
          } else if (day.kwh < 75) {
            barColor = const Color(0xFF87CEEB); // bleu
          } else {
            barColor = const Color(0xFFB00020); // rouge
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    day.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (day.kwh / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: barColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${day.kwh.toStringAsFixed(1)} kWh',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class ConsumptionDiagram extends StatelessWidget {
  final List<double> weeklyData;

  const ConsumptionDiagram({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(weeklyData.length, (index) {
            double value = weeklyData[index];
            Color barColor;
            if (value < 50) {
              barColor = const Color(0xFFB7E200); // vert citron
            } else if (value < 75) {
              barColor = const Color(0xFF87CEEB); // bleu ciel
            } else {
              barColor = const Color(0xFFB00020); // rouge sang
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: value, color: barColor, width: 14),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt() % days.length],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}