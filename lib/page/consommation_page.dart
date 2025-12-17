import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
// Assurez-vous que l'importation suivante correspond à l'emplacement de votre modèle Device
import 'package:api_reine/models/device.dart'; 

// --- DÉBUT : Définition de la classe EnergyDataService (pour la complétude) ---
class EnergyDataService {
  static const String historyKey = 'daily_consumption_history';

  Future<void> saveDailyData(double totalWh, double costFbu) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(historyKey) ?? '[]';
      final List<dynamic> history = json.decode(historyString);

      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final newEntry = {
        'date': date,
        'total_wh': totalWh,
        'cost_fbu': costFbu,
      };

      final existingIndex = history.indexWhere((item) => item['date'] == date);

      if (existingIndex != -1) {
        history[existingIndex] = newEntry;
      } else {
        history.add(newEntry);
      }

      await prefs.setString(historyKey, json.encode(history));
      print('Historique sauvegardé: $newEntry');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique: $e');
    }
  }
}
// --- FIN : Définition de la classe EnergyDataService ---

class ConsommationPage extends StatefulWidget {
  final List<Device> devices;

  const ConsommationPage({
    Key? key,
    required this.devices,
  }) : super(key: key);

  @override
  _ConsommationPageState createState() => _ConsommationPageState();
}

class _ConsommationPageState extends State<ConsommationPage> {
  Map<String, double> _energyData = {};
  Map<String, double> _activeTimeData = {};
  DateTime _lastGlobalUpdate = DateTime.now();
  Timer? _updateTimer;
  bool _isLoading = true;
  double _dailyGoal = 0.0;
  bool _goalReached = false;
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
    _loadDailyGoal();
    _startTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _goalController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateAllActiveDevices();
      }
    });
  }

  Future<void> _loadEnergyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final energyDataString = prefs.getString('energy_data');
      final timeDataString = prefs.getString('time_data');
      
      if (mounted) {
        setState(() {
          if (energyDataString != null) {
            _energyData = Map<String, double>.from(json.decode(energyDataString));
          }
          if (timeDataString != null) {
            _activeTimeData = Map<String, double>.from(json.decode(timeDataString));
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _dailyGoal = prefs.getDouble('daily_goal') ?? 0.0;
        });
      }
    } catch (e) {
      print('Erreur chargement objectif: $e');
    }
  }

  Future<void> _saveEnergyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('energy_data', json.encode(_energyData));
      await prefs.setString('time_data', json.encode(_activeTimeData));
      await prefs.setDouble('daily_goal', _dailyGoal);
      
      // La fonction suivante est gardée pour la compatibilité avec EnergyPage
      await _prepareDataForEnergyPage();
    } catch (e) {
      print('Erreur sauvegarde données: $e');
    }
  }

  Future<void> _prepareDataForEnergyPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      final deviceConsumption = [];
      for (final device in widget.devices) {
        if (_energyData.containsKey(device.id)) {
          deviceConsumption.add({
            'name': device.name,
            'consumption': _energyData[device.id]!,
            'category': _getDeviceCategory(device),
            'active_time': _activeTimeData[device.id] ?? 0.0,
          });
        }
      }
      
      final totalConsumption = {
        'total_wh': _getTotalEnergy(),
        'total_fbu': _getTotalEnergy() * 300,
        'daily_goal': _dailyGoal,
        'percentage': _dailyGoal > 0 ? (_getTotalEnergy() / _dailyGoal * 100) : 0,
        'goal_reached': _goalReached,
        'last_update': now.toIso8601String(),
      };
      
      await prefs.setString('device_consumption', json.encode(deviceConsumption));
      await prefs.setString('total_consumption', json.encode(totalConsumption));
    } catch (e) {
      print('Erreur préparation données EnergyPage: $e');
    }
  }

  String _getDeviceCategory(Device device) {
    if (device.courant < 0.1) return 'Éclairage';
    if (device.courant < 0.5) return 'Électronique';
    return 'Électroménager';
  }

  void _updateAllActiveDevices() {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_lastGlobalUpdate).inSeconds;
    
    if (elapsedSeconds == 0) return;
    
    if (!mounted) return;
    
    bool hasChanges = false;
    
    for (final device in widget.devices) {
      if (device.isActive) {
        final power = device.courant * 220; 
        final energyIncrement = (power * elapsedSeconds) / 3600;
        
        final currentEnergy = _energyData[device.id] ?? 0.0;
        _energyData[device.id] = currentEnergy + energyIncrement;
        
        final currentTime = _activeTimeData[device.id] ?? 0.0;
        _activeTimeData[device.id] = currentTime + elapsedSeconds;
        
        hasChanges = true;
      }
    }
    
    _lastGlobalUpdate = now;
    
    // Logique d'objectif d'arrêt automatique
    if (_dailyGoal > 0 && _getTotalEnergy() >= _dailyGoal && !_goalReached) {
      _turnOffAllDevices();
      _goalReached = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 Objectif atteint! Tous les appareils ont été éteints.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    
    if (hasChanges || _goalReached) {
      if (mounted) {
        setState(() {});
      }
      _saveEnergyData();
    }
  }

  void _turnOffAllDevices() {
    if (!mounted) return;
    
    setState(() {
      for (final device in widget.devices) {
        if (device.isActive) {
          device.isActive = false;
        }
      }
      _lastGlobalUpdate = DateTime.now();
    });
  }

  void _toggleDevice(String deviceId, bool value) {
    if (!mounted) return;
    
    if (value && _goalReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Objectif déjà atteint! Réinitialisez pour continuer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      final device = widget.devices.firstWhere((d) => d.id == deviceId);
      device.isActive = value;
      
      _lastGlobalUpdate = DateTime.now();
    });
  }

  double _getDeviceEnergy(String deviceId) {
    return _energyData[deviceId] ?? 0.0;
  }

  double _getTotalEnergy() {
    return _energyData.values.fold(0, (sum, value) => sum + value);
  }

  Color _getTotalEnergyColor() {
    if (_dailyGoal == 0) return Colors.blue;
    final percentage = _getTotalEnergy() / _dailyGoal;
    if (percentage < 0.5) return Colors.green;
    if (percentage < 0.85) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(double seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final secs = (seconds % 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  void _saveToHistory() {
    if (!mounted) return;
    
    final totalEnergy = _getTotalEnergy();
    final cost = totalEnergy * 300; // 300 FBu/Wh (Exemple de coût)
    
    EnergyDataService().saveDailyData(totalEnergy, cost);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Données enregistrées dans l\'historique (${totalEnergy.toStringAsFixed(3)} Wh)'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resetCounters() {
    if (!mounted) return;
    
    setState(() {
      _energyData.clear();
      _activeTimeData.clear();
      _lastGlobalUpdate = DateTime.now();
      _goalReached = false;
      
      // Éteindre tous les appareils
      for (final device in widget.devices) {
        device.isActive = false;
      }
    });
    
    _saveEnergyData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Compteurs remis à zéro'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // LOGIQUE CLÉ : Récupère et trie les 3 appareils ACTIFS par PUISSANCE INSTANTANÉE (Watts)
  List<Map<String, dynamic>> _getTopEnergyConsumers() {
    List<Map<String, dynamic>> consumers = [];
    
    for (final device in widget.devices) {
      // 1. Filtrer UNIQUEMENT les appareils actifs
      if (device.isActive) {
        // 2. Calculer la puissance instantanée (Watts)
        final power = device.courant * 220; 

        consumers.add({
          'device': device,
          'power': power, 
          // Consommation cumulative pour information
          'energy_cumulative': _getDeviceEnergy(device.id), 
        });
      }
    }
    
    // 3. Trier par puissance (Watts) décroissante et prendre les 3 premiers
    consumers.sort((a, b) => b['power'].compareTo(a['power']));
    return consumers.take(3).toList();
  }

  // DIALOGUE CLÉ : Affiche le Top 3 par PUISSANCE INSTANTANÉE
  void _showTopConsumersDialog() {
    final topConsumers = _getTopEnergyConsumers();

    if (topConsumers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun appareil actif pour les statistiques de puissance.'),
          backgroundColor: Colors.blueGrey,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.red),
            SizedBox(width: 10),
            Text('Top3 Actifs'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: topConsumers.asMap().entries.map((entry) {
              final index = entry.key;
              final consumer = entry.value;
              final device = consumer['device'] as Device;
              final power = consumer['power'] as double;
              final energy = consumer['energy_cumulative'] as double;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red[400],
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(device.name, style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  // Affichage dynamique basé sur la puissance instantanée
                  'Puissance: ${power.toStringAsFixed(0)} W • Cumulé: ${energy.toStringAsFixed(1)} Wh',
                ),
                trailing: Chip(
                  label: Text(
                    _getDeviceCategory(device),
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  void _showGoalDialog() {
    _goalController.text = _dailyGoal.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Objectif de consommation journalière'),
        content: TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Objectif (Wh/jour)',
            hintText: 'Ex: 1000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = double.tryParse(_goalController.text);
              if (goal != null && goal >= 0) {
                setState(() {
                  _dailyGoal = goal;
                  _goalReached = false;
                });
                _saveEnergyData();
              }
              Navigator.pop(context);
            },
            child: Text('Définir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compteur d\'Énergie'),
        backgroundColor: const Color.fromRGBO(63, 159, 238, 1),
        actions: [
          // Bouton pour afficher le Dialogue Top Consommateurs (dynamique par puissance)
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: _showTopConsumersDialog,
            tooltip: 'Top 3 Consommateurs Actifs (Puissance)',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToHistory, 
            tooltip: 'Enregistrer dans l\'historique',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounters,
            tooltip: 'Remise à zéro des compteurs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Carte de consommation principale
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Consommation Journalière',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.flag, size: 22, color: Colors.blue),
                              onPressed: _showGoalDialog,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '${_getTotalEnergy().toStringAsFixed(3)} Wh',
                          style: TextStyle(
                            fontSize: 28,
                            color: _getTotalEnergyColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${(_getTotalEnergy() * 300).toStringAsFixed(3)} FBu',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        if (_goalReached) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Objectif atteint! Appareils éteints',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        if (_dailyGoal > 0) ...[
                          SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _getTotalEnergy() / _dailyGoal > 1 ? 
                                1.0 : _getTotalEnergy() / _dailyGoal,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(_getTotalEnergyColor()),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${(_getTotalEnergy() / _dailyGoal * 100).toStringAsFixed(1)}% de l\'objectif (${_dailyGoal.toStringAsFixed(0)} Wh)',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getTotalEnergyColor(),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.update, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              'Mise à jour chaque seconde',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Légende
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.green, '<50%'),
                      _buildLegendItem(Colors.orange, '50-85%'),
                      _buildLegendItem(Colors.red, '>85%'),
                    ],
                  ),
                ),
                
                // En-tête appareils
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Appareils (${widget.devices.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${widget.devices.where((d) => d.isActive).length} actifs',
                        style: TextStyle(
                          fontSize: 14,
                          color: _goalReached ? Colors.orange : Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Liste des appareils
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.devices.length,
                    itemBuilder: (context, index) {
                      final device = widget.devices[index];
                      final energy = _getDeviceEnergy(device.id);
                      final activeTime = _activeTimeData[device.id] ?? 0.0;
                      final power = device.courant * 220;
                      
                      return _buildDeviceItem(device, energy, activeTime, power);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(Device device, double energy, double activeTime, double power) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: device.isActive ? 
                          Colors.green.withAlpha(38) : 
                          Colors.grey.withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: device.isActive ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        device.isActive ? 'ACTIF' : 'INACTIF',
                        style: TextStyle(
                          fontSize: 10,
                          color: device.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${_getDeviceCategory(device)} • ${power.toStringAsFixed(0)}W',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Énergie: ${energy.toStringAsFixed(3)} Wh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Temps: ${_formatTime(activeTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${device.courant}A × 220V',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Switch(
            value: device.isActive,
            onChanged: _goalReached ? null : (value) => _toggleDevice(device.id, value),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}