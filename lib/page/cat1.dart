import 'package:flutter/material.dart';
import 'package:api_reine/services/command_sender.dart';
import 'package:api_reine/page/consommation_page.dart';
import 'package:api_reine/models/device.dart';
import 'dart:async';

class CategoriesPage extends StatefulWidget {
  final bool isConnected;
  final CommandSender commandSender;

  const CategoriesPage({
    super.key,
    required this.isConnected,
    required this.commandSender,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedCategory;
  final List<String> _commandHistory = [];
  bool _isFeedbackVisible = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _clearTimer;

  final List<Device> _lightingDevices = [
    Device(
      id: '1',
      name: 'LED Salon',
      isActive: false,
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      commandOn: 'LED1_ON',
      commandOff: 'LED1_OFF',
      courant: 0.05,
    ),
    Device(
      id: '2',
      name: 'LED Cuisine',
      isActive: false,
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      commandOn: 'LED2_ON',
      commandOff: 'LED2_OFF',
      courant: 0.04,
    ),
    Device(
      id: '3',
      name: 'LED Chambre',
      isActive: false,
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      commandOn: 'LED3_ON',
      commandOff: 'LED3_OFF',
      courant: 0.06,
    ),
  ];

  final List<Device> _securityDevices = [
    Device(
      id: '4',
      name: 'Alarme',
      isActive: false,
      icon: Icons.security,
      color: Colors.red,
      commandOn: 'ALARM1_ON',
      commandOff: 'ALARM1_OFF',
      courant: 0.02,
    ),
    Device(
      id: '5',
      name: 'Capteur Mouvement',
      isActive: false,
      icon: Icons.directions_run,
      color: Colors.blue,
      commandOn: 'MOTION1_ON',
      commandOff: 'MOTION1_OFF',
      courant: 0.01,
    ),
  ];

  final List<Device> _applianceDevices = [
    Device(
      id: '6',
      name: 'Réfrigérateur',
      isActive: false,
      icon: Icons.kitchen,
      color: Colors.blue,
      commandOn: 'FRIDGE1_ON',
      commandOff: 'FRIDGE1_OFF',
      courant: 0.68,
    ),
    Device(
      id: '7',
      name: 'TV',
      isActive: false,
      icon: Icons.tv,
      color: Colors.blueGrey,
      commandOn: 'TV1_ON',
      commandOff: 'TV1_OFF',
      courant: 0.36,
    ),
  ];

  final Map<String, double> _consumptionData = {};
  StreamSubscription<String>? _messageSub;

  List<Device> get allDevices => [..._lightingDevices, ..._securityDevices, ..._applianceDevices];

  double get totalConsumption {
    return _consumptionData.values.fold(0, (sum, consumption) => sum + consumption);
  }

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
    _startClearTimer();
  }

  void _setupMessageListener() {
    final dynamic cs = widget.commandSender.connectionService;
    Stream<String>? stream;

    try {
      stream = (cs.onMessageReceived as Stream<String>?);
    } catch (_) {
      try {
        stream = (cs.messageStream as Stream<String>?);
      } catch (_) {
        stream = null;
      }
    }

    if (stream != null) {
      _messageSub = stream.listen((message) {
        if (!mounted) return;
        _addToHistory('📨 $message');
        _restartClearTimer();
      }, onError: (e) {
        debugPrint('Erreur stream message: $e');
      });
    }
  }

  void _addToHistory(String message) {
    setState(() {
      _commandHistory.add(message);
      if (_commandHistory.length > 50) {
        _commandHistory.removeAt(0);
      }
    });
    _scrollToBottom();
  }

  void _startClearTimer() {
    _clearTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_commandHistory.isNotEmpty) {
        _clearHistory();
      }
    });
  }

  void _restartClearTimer() {
    _clearTimer?.cancel();
    _startClearTimer();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _clearTimer?.cancel();
    super.dispose();
  }

  void _addNewDevice() {
    TextEditingController nameController = TextEditingController();
    TextEditingController onController = TextEditingController();
    TextEditingController offController = TextEditingController();
    TextEditingController courantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un nouveau dispositif'),
        content: SingleChildScrollView(
          child: Column(
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
              TextField(
                controller: courantController,
                decoration: const InputDecoration(labelText: 'Courant (A)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
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
                  offController.text.isNotEmpty &&
                  courantController.text.isNotEmpty) {
                setState(() {
                  final newDevice = Device(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    isActive: false,
                    icon: _getIconForCategory(),
                    color: _getColorForCategory(),
                    commandOn: onController.text,
                    commandOff: offController.text,
                    courant: double.tryParse(courantController.text) ?? 0.1,
                  );

                  _getCurrentDevices().add(newDevice);
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

  IconData _getIconForCategory() {
    switch (_selectedCategory) {
      case 'Eclairage': return Icons.lightbulb_outline;
      case 'Sécurité': return Icons.security;
      case 'Électroménager': return Icons.kitchen;
      default: return Icons.device_unknown;
    }
  }

  Color _getColorForCategory() {
    switch (_selectedCategory) {
      case 'Eclairage': return Colors.amber;
      case 'Sécurité': return Colors.red;
      case 'Électroménager': return Colors.blue;
      default: return Colors.grey;
    }
  }

  List<Device> _getCurrentDevices() {
    switch (_selectedCategory) {
      case 'Eclairage': return _lightingDevices;
      case 'Sécurité': return _securityDevices;
      case 'Électroménager': return _applianceDevices;
      default: return [];
    }
  }

  void _updateConsumption(Device device, bool isActive) {
    setState(() {
      if (isActive) {
        final baseConsumption = device.courant * 220;
        _consumptionData[device.id] = baseConsumption;
      } else {
        _consumptionData.remove(device.id);
      }
    });
  }

  void _editDevice(Device device, List<Device> devices) {
    TextEditingController nameController = TextEditingController(text: device.name);
    TextEditingController onController = TextEditingController(text: device.commandOn);
    TextEditingController offController = TextEditingController(text: device.commandOff);
    TextEditingController courantController = TextEditingController(text: device.courant.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le dispositif'),
        content: SingleChildScrollView(
          child: Column(
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
              TextField(
                controller: courantController,
                decoration: const InputDecoration(labelText: 'Courant (A)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
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
                device.courant = double.tryParse(courantController.text) ?? device.courant;
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
                _consumptionData.remove(device.id);
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
    final isConnected = widget.commandSender.connectionService.isConnected.value;
    if (!isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non connecté à un appareil')),
      );
      return;
    }

    setState(() {
      device.isActive = value;
    });

    _updateConsumption(device, value);

    final command = value ? device.commandOn : device.commandOff;
    
    _addToHistory('> $command');
    _restartClearTimer();

    final result = await widget.commandSender.sendCommand(command);

    if (!mounted) return;

    if (result.success) {
      _addToHistory('✅ ${result.message}');
    } else {
      setState(() {
        device.isActive = !value;
        _updateConsumption(device, !value);
      });
      _addToHistory('❌ ${result.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${result.message}')),
      );
    }
    _restartClearTimer();
  }

  void _toggleAllDevices(List<Device> devices, bool value) {
    final isConnected = widget.commandSender.connectionService.isConnected.value;
    if (!isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non connecté à un appareil')),
      );
      return;
    }

    for (var device in devices) {
      _toggleDevice(device, value);
    }
  }

  void _showDeviceStatus() {
    final allDevices = [..._lightingDevices, ..._securityDevices, ..._applianceDevices];
    final activeDevices = allDevices.where((device) => device.isActive).toList();
    final inactiveDevices = allDevices.where((device) => !device.isActive).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('État des Appareils', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection('🟢 Appareils Actifs (${activeDevices.length})', activeDevices, Colors.green),
              const SizedBox(height: 16),
              _buildStatusSection('🔴 Appareils Inactifs (${inactiveDevices.length})', inactiveDevices, Colors.red),
            ],
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

  Widget _buildStatusSection(String title, List<Device> devices, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (devices.isEmpty)
          const Text('Aucun appareil', style: TextStyle(color: Colors.grey)),
        ...devices.map((device) => ListTile(
          leading: Icon(device.icon, color: device.color),
          title: Text(device.name),
          subtitle: Text('ID: ${device.id}'),
          dense: true,
          visualDensity: VisualDensity.compact,
        )),
      ],
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'Eclairage':
        return _buildDeviceContent(_lightingDevices);
      case 'Sécurité':
        return _buildDeviceContent(_securityDevices);
      case 'Électroménager':
        return _buildDeviceContent(_applianceDevices);
      default:
        return _buildCategoriesGrid();
    }
  }

  Widget _buildDeviceContent(List<Device> devices) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _toggleAllDevices(devices, true),
                icon: const Icon(Icons.power),
                label: const Text('Tout activer'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(235, 239, 235, 1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _toggleAllDevices(devices, false),
                icon: const Icon(Icons.power_off),
                label: const Text('Tout désactiver'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(249, 246, 246, 1)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(device.icon, color: device.color),
                  title: Text(device.name),
                  subtitle: Text('${device.commandOn} / ${device.commandOff}'),
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
                            _editDevice(device, devices);
                          } else if (value == 'delete') {
                            _deleteDevice(device, devices);
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
        _buildFeedbackConsole(),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            CategoryCard(
              icon: Icons.lightbulb_outline,
              title: 'Eclairage',
              color: const Color.fromARGB(255, 83, 138, 242),
              backgroundColor: Color.fromARGB(30, 255, 193, 7),
              onTap: () => setState(() => _selectedCategory = 'Eclairage'),
            ),
            CategoryCard(
              icon: Icons.kitchen,
              title: 'Électroménager',
              color: const Color.fromARGB(255, 83, 138, 242),
              backgroundColor: Color.fromARGB(30, 33, 150, 243),
              onTap: () => setState(() => _selectedCategory = 'Électroménager'),
            ),
            CategoryCard(
              icon: Icons.security,
              title: 'capteurs',
              color: const Color.fromARGB(255, 83, 138, 242),
              backgroundColor: Color.fromARGB(30, 244, 67, 54),
              onTap: () => setState(() => _selectedCategory = 'Sécurité'),
            ),
            CategoryCard(
              icon: Icons.bolt,
              title: 'Consommation',
              color: const Color.fromARGB(255, 83, 138, 242),
              backgroundColor: Color.fromARGB(30, 76, 175, 80),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsommationPage(
                      devices: allDevices,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackConsole() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isFeedbackVisible = !_isFeedbackVisible;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _isFeedbackVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-effacement: 4s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isFeedbackVisible)
            Container(
              height: 150,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _commandHistory.length,
                itemBuilder: (context, index) {
                  final bool isCommand = _commandHistory[index].startsWith('> ');
                  final bool isError = _commandHistory[index].startsWith('❌');
                  final bool isSuccess = _commandHistory[index].startsWith('✅');
                  final bool isMessage = _commandHistory[index].startsWith('📨');
                  final bool isConnection = _commandHistory[index].contains('CONNEXION') || 
                                          _commandHistory[index].contains('DÉCONNEXION');
                  
                  return Container(
                    color: index.isEven ? Colors.transparent : Colors.black.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      _commandHistory[index],
                      style: TextStyle(
                        color: isCommand 
                            ? const Color.fromRGBO(238, 237, 242, 1)
                            : isError
                              ? const Color(0xFFFF5252)
                              : isSuccess
                                ? const Color.fromRGBO(76, 175, 80, 1)
                                : isMessage
                                  ? const Color.fromRGBO(241, 237, 237, 1)
                                  : isConnection
                                    ? Colors.cyan
                                    : const Color.fromARGB(186, 1, 132, 240),
                        fontFamily: 'RobotoMono',
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _clearHistory() {
    setState(() {
      _commandHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 252, 253),
        leading: _selectedCategory != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(21, 21, 21, 1)),
                    onPressed: () => setState(() => _selectedCategory = null),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFeedbackVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromRGBO(21, 21, 21, 1),
                    ),
                    onPressed: () {
                      setState(() {
                        _isFeedbackVisible = !_isFeedbackVisible;
                      });
                    },
                  ),
                ],
              )
            : null,
        title: Text(
          _selectedCategory ?? 'Catégories',
          style: const TextStyle(
            color: Color.fromARGB(255, 15, 15, 15),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.add, color: Color.fromARGB(255, 22, 22, 22)),
              onPressed: _addNewDevice,
            ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Color.fromRGBO(18, 18, 18, 1)),
            onPressed: _clearHistory,
            tooltip: 'Effacer l\'historique',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              color: widget.commandSender.connectionService.isConnected.value 
                  ? Colors.green 
                  : Colors.red,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    widget.commandSender.connectionService.isConnected.value ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.commandSender.connectionService.isConnected.value
                        ? 'Connecté à ${widget.commandSender.connectionService.connectedDevice.value}'
                        : 'Non connecté - Allez à l\'accueil pour vous connecter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _showDeviceStatus,
              icon: const Icon(Icons.device_hub),
              label: const Text('Voir l\'état des appareils'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 95, 177, 244),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }
}

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