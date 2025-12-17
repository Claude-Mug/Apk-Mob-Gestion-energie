import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:convert';
import 'package:api_reine/services/command_sender.dart';

// Modèle de données pour un dispositif avec commandes séparées ON/OFF
class Device {
  String id;
  String name;
  bool isActive;
  IconData icon;
  Color color;
  String commandOn;   // Commande pour activer
  String commandOff;  // Commande pour désactiver

  Device({
    required this.id,
    required this.name,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.commandOn,
    required this.commandOff,
  });
}

// Page principale des catégories avec contenu intégré
class CategoriesPage extends StatefulWidget {
  final bool isConnected;
  final CommandSender commandSender;

  const CategoriesPage({super.key, required this.isConnected, required this.commandSender});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedCategory;
  final List<Device> _lightingDevices = [
    Device(id: '1', name: 'LED Salon', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED1', commandOff: 'LED0'),
    Device(id: '2', name: 'LED Cuisine', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED2', commandOff: 'LED0'),
    Device(id: '3', name: 'LED Chambre', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED3', commandOff: 'LED0'),
    Device(id: '4', name: 'LED Bureau', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED4', commandOff: 'LED0'),
    Device(id: '5', name: 'LED Extérieur', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED5', commandOff: 'LED0'),
    Device(id: '6', name: 'LED Garage', isActive: false, icon: Icons.lightbulb_outline, color: Colors.amber, commandOn: 'LED6', commandOff: 'LED0'),
  ];
  
  final List<Device> _securityDevices = [
    Device(id: '1', name: 'Alarme', isActive: false, icon: Icons.security, color: Colors.red, commandOn: 'ALARM1', commandOff: 'ALARM0'),
    Device(id: '2', name: 'Capteur Mouvement', isActive: false, icon: Icons.directions_run, color: Colors.blue, commandOn: 'MOTION1', commandOff: 'MOTION0'),
    Device(id: '3', name: 'Capteur Porte', isActive: false, icon: Icons.door_back_door, color: Colors.green, commandOn: 'DOOR1', commandOff: 'DOOR0'),
    Device(id: '4', name: 'Capteur Fenêtre', isActive: false, icon: Icons.window, color: Colors.orange, commandOn: 'WINDOW1', commandOff: 'WINDOW0'),
    Device(id: '5', name: 'Caméra', isActive: false, icon: Icons.videocam, color: Colors.purple, commandOn: 'CAMERA1', commandOff: 'CAMERA0'),
    Device(id: '6', name: 'Détecteur Fumée', isActive: false, icon: Icons.smoke_free, color: Colors.brown, commandOn: 'SMOKE1', commandOff: 'SMOKE0'),
  ];

  final List<Device> _applianceDevices = [
  Device(id: '1', name: 'Réfrigérateur', isActive: false, icon: Icons.kitchen, color: Colors.blue, commandOn: 'FRIDGE1', commandOff: 'FRIDGE0'),
  Device(id: '2', name: 'Lave-linge', isActive: false, icon: Icons.local_laundry_service, color: Colors.purple, commandOn: 'WASHER1', commandOff: 'WASHER0'),
  Device(id: '3', name: 'Lave-vaisselle', isActive: false, icon: Icons.kitchen, color: Colors.teal, commandOn: 'DISHWASHER1', commandOff: 'DISHWASHER0'),
  Device(id: '4', name: 'Four', isActive: false, icon: Icons.cookie, color: Colors.orange, commandOn: 'OVEN1', commandOff: 'OVEN0'),
  Device(id: '5', name: 'Plaque de cuisson', isActive: false, icon: Icons.storm, color: Colors.red, commandOn: 'STOVE1', commandOff: 'STOVE0'),
  Device(id: '6', name: 'Micro-ondes', isActive: false, icon: Icons.microwave, color: Colors.brown, commandOn: 'MICROWAVE1', commandOff: 'MICROWAVE0'),
  Device(id: '7', name: 'Cafetière', isActive: false, icon: Icons.coffee, color: Colors.brown, commandOn: 'COFFEE1', commandOff: 'COFFEE0'),
  Device(id: '8', name: 'Aspirateur', isActive: false, icon: Icons.cleaning_services, color: Colors.grey, commandOn: 'VACUUM1', commandOff: 'VACUUM0'),
  Device(id: '9', name: 'TV', isActive: false, icon: Icons.tv, color: Colors.blueGrey, commandOn: 'TV1', commandOff: 'TV0'),
  Device(id: '10', name: 'Ordinateur', isActive: false, icon: Icons.computer, color: Colors.indigo, commandOn: 'COMPUTER1', commandOff: 'COMPUTER0'),
];

  bool _tempAuto = true;
  double _currentTemp = 23.0;
  Map<String, double> _consumptionData = {};

  void _addNewDevice() {
    TextEditingController nameController = TextEditingController();
    TextEditingController onController = TextEditingController();
    TextEditingController offController = TextEditingController();


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un nouveau dispositif'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du dispositif'),
            ),
            TextField(
              controller: onController,
              decoration: const InputDecoration(labelText: 'Commande ON'),
            ),
            TextField(
              controller: offController,
              decoration: const InputDecoration(labelText: 'Commande OFF'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  onController.text.isNotEmpty && 
                  offController.text.isNotEmpty) {
                
                setState(() {
                  final newDevice = Device(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    isActive: false,
                    icon: _selectedCategory == 'Eclairage' 
                          ? Icons.lightbulb_outline 
                          : Icons.security,
                    color: _selectedCategory == 'Eclairage' 
                          ? Colors.amber 
                          : Colors.red,
                    commandOn: onController.text,
                    commandOff: offController.text,
                  );

                  if (_selectedCategory == 'Eclairage') {
                    _lightingDevices.add(newDevice);
                  } else if (_selectedCategory == 'Sécurité') {
                    _securityDevices.add(newDevice);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _updateConsumption(String deviceId, bool isActive) {
  setState(() {
    if (isActive) {
      // Simuler une consommation aléatoire entre 0.5 et 5.0 kWh
      _consumptionData[deviceId] = 0.5 + Random().nextDouble() * 4.5;
    } else {
      _consumptionData.remove(deviceId);
    }
  });
}

  void _editDevice(Device device, List<Device> devices) {
    TextEditingController nameController = TextEditingController(text: device.name);
    TextEditingController onController = TextEditingController(text: device.commandOn);
    TextEditingController offController = TextEditingController(text: device.commandOff);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le dispositif'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du dispositif'),
            ),
            TextField(
              controller: onController,
              decoration: const InputDecoration(labelText: 'Commande ON'),
            ),
            TextField(
              controller: offController,
              decoration: const InputDecoration(labelText: 'Commande OFF'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                device.name = nameController.text;
                device.commandOn = onController.text;
                device.commandOff = offController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(Device device, List<Device> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dispositif'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${device.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                devices.remove(device);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDevice(Device device, bool value) async {
  if (!widget.commandSender.connectionService.isConnected.value) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Non connecté à un appareil')),
    );
    return;
  }

  setState(() {
    device.isActive = value;
  });

  // Mettre à jour la consommation
  _updateConsumption(device.id, value);

  try {
    // Envoi de la commande spécifique
    final command = value ? device.commandOn : device.commandOff;
    final result = await widget.commandSender.sendCommand(command);

    if (!result.success) {
      setState(() {
        device.isActive = !value;
        _updateConsumption(device.id, !value);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${result.message}')),
      );
    }
  } catch (e) {
    setState(() {
      device.isActive = !value;
      _updateConsumption(device.id, !value);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}

  void _toggleAllDevices(List<Device> devices, bool value) {
    if (!widget.commandSender.connectionService.isConnected.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non connecté à un appareil')),
      );
      return;
    }

    for (var device in devices) {
      _toggleDevice(device, value);
    }
  }

  Widget _buildCategoryContent() {
  switch (_selectedCategory) {
    case 'Eclairage':
      return _buildLightingContent();
    case 'Sécurité':
      return _buildSecurityContent();
    case 'Électroménager':  // Remplacer Température par Électroménager
      return _buildApplianceContent();
    case 'Consommation':
      return _buildConsumptionContent();
    default:
      return _buildCategoriesGrid();
  }
}

// Nouvelle méthode pour le contenu des appareils électroménagers
Widget _buildApplianceContent() {
  return Column(
    children: [
      // Switch pour activer/désactiver tous les appareils
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _toggleAllDevices(_applianceDevices, true),
              child: const Text('Tout activer'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _toggleAllDevices(_applianceDevices, false),
              child: const Text('Tout désactiver'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView.builder(
          itemCount: _applianceDevices.length,
          itemBuilder: (context, index) {
            final device = _applianceDevices[index];
            return Dismissible(
              key: Key(device.id),
              background: Container(color: Colors.red),
              onDismissed: (direction) => _deleteDevice(device, _applianceDevices),
              child: ListTile(
                leading: Icon(device.icon, color: device.color),
                title: Text(device.name),
                subtitle: Text('ON: ${device.commandOn}, OFF: ${device.commandOff}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: device.isActive,
                      onChanged: (value) => _toggleDevice(device, value),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editDevice(device, _applianceDevices);
                        } else if (value == 'delete') {
                          _deleteDevice(device, _applianceDevices);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildLightingContent() {
    return Column(
      children: [
        // Switch pour activer/désactiver tous les appareils
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _toggleAllDevices(_lightingDevices, true),
                child: const Text('Tout activer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _toggleAllDevices(_lightingDevices, false),
                child: const Text('Tout désactiver'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _lightingDevices.length,
            itemBuilder: (context, index) {
              final device = _lightingDevices[index];
              return Dismissible(
                key: Key(device.id),
                background: Container(color: Colors.red),
                onDismissed: (direction) => _deleteDevice(device, _lightingDevices),
                child: ListTile(
                  leading: Icon(device.icon, color: device.color),
                  title: Text(device.name),
                  subtitle: Text('ON: ${device.commandOn}, OFF: ${device.commandOff}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: device.isActive,
                        onChanged: (value) => _toggleDevice(device, value),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Modifier'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editDevice(device, _lightingDevices);
                          } else if (value == 'delete') {
                            _deleteDevice(device, _lightingDevices);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityContent() {
    return Column(
      children: [
        // Switch pour activer/désactiver tous les appareils
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _toggleAllDevices(_securityDevices, true),
                child: const Text('Tout activer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _toggleAllDevices(_securityDevices, false),
                child: const Text('Tout désactiver'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _securityDevices.length,
            itemBuilder: (context, index) {
              final device = _securityDevices[index];
              return Dismissible(
                key: Key(device.id),
                background: Container(color: Colors.red),
                onDismissed: (direction) => _deleteDevice(device, _securityDevices),
                child: ListTile(
                  leading: Icon(device.icon, color: device.color),
                  title: Text(device.name),
                  subtitle: Text('ON: ${device.commandOn}, OFF: ${device.commandOff}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: device.isActive,
                        onChanged: (value) => _toggleDevice(device, value),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Modifier'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editDevice(device, _securityDevices);
                          } else if (value == 'delete') {
                            _deleteDevice(device, _securityDevices);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureContent() {
    return Column(
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Placeholder(), // Remplacer par un graphique de température
        ),
        SwitchListTile(
          title: const Text('Contrôle automatique'),
          value: _tempAuto,
          onChanged: (value) {
            setState(() {
              _tempAuto = value;
            });
            if (widget.commandSender.connectionService.isConnected.value) {
              widget.commandSender.sendCommand('TEMP_AUTO ${value ? 'ON' : 'OFF'}');
            }
          },
        ),
        ListTile(
          title: const Text('Température actuelle'),
          trailing: Text('${_currentTemp.toStringAsFixed(1)}°C'),
        ),
      ],
    );
  }

  Widget _buildConsumptionContent() {
  // Combinez tous les appareils pour le graphique
  List<Device> allDevices = [..._lightingDevices, ..._securityDevices, ..._applianceDevices];
  double totalConsumption = _consumptionData.values.fold(0, (sum, value) => sum + value);
  
  // Filtrer seulement les appareils avec consommation
  List<Map<String, dynamic>> consumptionList = [];
  _consumptionData.forEach((deviceId, consumption) {
    final device = allDevices.firstWhere((d) => d.id == deviceId, orElse: () => Device(
      id: '', name: 'Inconnu', isActive: false, icon: Icons.device_unknown, 
      color: Colors.grey, commandOn: '', commandOff: ''
    ));
    
    if (consumption > 0) {
      consumptionList.add({
        'appareil': device.name,
        'consommation': consumption,
        'icon': device.icon,
        'color': device.color
      });
    }
  });
  
  // Trier par consommation décroissante
  consumptionList.sort((a, b) => b['consommation'].compareTo(a['consommation']));

  return Column(
    children: [
      // En-tête avec consommation totale
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consommation totale',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tous appareils confondus',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Text(
              '${totalConsumption.toStringAsFixed(2)} kWh',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 16),
      
      // Graphique à barres horizontales
      if (consumptionList.isNotEmpty)
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: _buildHorizontalBarChart(consumptionList, totalConsumption),
        )
      else
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_bolt, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune consommation enregistrée',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  'Activez des appareils pour voir les données',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      
      const SizedBox(height: 16),
      
      // Liste détaillée des appareils
      if (consumptionList.isNotEmpty)
        Expanded(
          child: ListView.builder(
            itemCount: consumptionList.length,
            itemBuilder: (context, index) {
              final item = consumptionList[index];
              final consumption = item['consommation'];
              final percentage = (consumption / totalConsumption) * 100;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Icon(item['icon'], color: item['color']),
                  title: Text(item['appareil']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_getConsumptionColor(percentage)),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consumption.toStringAsFixed(2)} kWh (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${consumption.toStringAsFixed(2)} kWh',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        )
      else
        Expanded(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Eclairage';
                });
              },
              child: const Text('Activer des appareils'),
            ),
          ),
        ),
    ],
  );
}

Widget _buildHorizontalBarChart(List<Map<String, dynamic>> consumptionList, double totalConsumption) {
  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: consumptionList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final percentage = (item['consommation'] / totalConsumption) * 100;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item['consommation'],
              color: _getConsumptionColor(percentage),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < consumptionList.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    consumptionList[index]['appareil'],
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()} kWh');
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
    ),
  );
}

// Méthode pour déterminer la couleur en fonction de la consommation
Color _getConsumptionColor(double percentage) {
  if (percentage > 30) return Colors.red;
  if (percentage > 15) return Colors.orange;
  if (percentage > 5) return Colors.yellow;
  return Colors.green;
}

// Ajoutez cette méthode pour construire le graphique à barres
Widget _buildConsumptionBarChart(List<Device> allDevices) {
  // Filtrer seulement les appareils actifs
  List<Device> activeDevices = allDevices.where((device) => device.isActive).toList();
  
  if (activeDevices.isEmpty) {
    return const Center(
      child: Text(
        'Aucune consommation\nActivez des appareils',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // Calculer la consommation totale
  double totalConsumption = _consumptionData.values.fold(0, (sum, value) => sum + value);

  // Préparer les données pour le graphique
  List<PieChartSectionData> sections = [];
  List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
  ];

  int colorIndex = 0;
  _consumptionData.forEach((deviceId, consumption) {
    final device = _applianceDevices.firstWhere((d) => d.id == deviceId, orElse: () => Device(
      id: '', name: '', isActive: false, icon: Icons.device_unknown, color: Colors.grey, 
      commandOn: '', commandOff: ''
    ));
    
    final percentage = (consumption / totalConsumption) * 100;
    
    sections.add(
      PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: consumption,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 20,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    
    colorIndex++;
  });

  return PieChart(
    PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
    ),
  );
}

  Widget _buildCategoriesGrid() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey[300]!, width: 2),
    ),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          CategoryCard(
            icon: Icons.lightbulb_outline,
            title: 'Eclairage',
            color: const Color.fromARGB(255, 0, 60, 255),
            backgroundColor: const Color(0x33FFA000),
            onTap: () => setState(() => _selectedCategory = 'Eclairage'),
          ),
          CategoryCard(
            icon: Icons.kitchen,  // Icône pour électroménager
            title: 'Électroménager',  // Remplacer Température par Électroménager
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0x33FFA000),
            onTap: () => setState(() => _selectedCategory = 'Électroménager'),
          ),
          CategoryCard(
            icon: Icons.security,
            title: 'Sécurité',
            color: const Color.fromARGB(255, 54, 114, 244),
            backgroundColor: const Color(0x33FFA000),
            onTap: () => setState(() => _selectedCategory = 'Sécurité'),
          ),
          CategoryCard(
            icon: Icons.bolt,
            title: 'Consommation',
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0x33FFA000),
            onTap: () => setState(() => _selectedCategory = 'Consommation'),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color(0xFF2C3E50),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: _selectedCategory != null
       ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() => _selectedCategory = null),
        )
      : Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
     title: Text(
    _selectedCategory ?? 'Catégories',
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  centerTitle: true,
  elevation: 0,
        actions: [
          if (_selectedCategory == 'Eclairage' || _selectedCategory == 'Sécurité')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _addNewDevice,
            ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.commandSender.connectionService.isConnected,
            builder: (context, isConnected, child) {
              return IconButton(
                icon: Icon(isConnected ? Icons.wifi : Icons.wifi_off, color: Colors.white),
                onPressed: () {
                  if (isConnected) {
                    widget.commandSender.connectionService.disconnect();
                  } else {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ValueListenableBuilder<String>(
              valueListenable: widget.commandSender.connectionService.connectedDevice,
              builder: (context, device, child) {
                if (device.isNotEmpty) {
                  return ListTile(
                    leading: const Icon(Icons.device_hub, color: Colors.green),
                    title: const Text('Appareil connecté'),
                    subtitle: Text(device),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => widget.commandSender.connectionService.disconnect(),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            Expanded(
              child: _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les cartes de catégorie
class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

