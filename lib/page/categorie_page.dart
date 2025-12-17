import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:api_reine/services/command_sender.dart';
import 'package:api_reine/page/consommation_page.dart';
import 'package:api_reine/models/device.dart';
import 'package:api_reine/models/devices.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _selectedRoom;
  final List<String> _commandHistory = [];
  bool _isFeedbackVisible = false;
  final ScrollController _scrollController = ScrollController();

  // Pièces par défaut avec 7 appareils chacune
  final List<Room> _defaultRooms = [
    Room(
      id: '1',
      name: 'Salon',
      icon: '🛋️',
      isDefault: true,
      devices: [
        Device2(
          id: 'salon_tv',
          name: 'Télévision',
          isActive: false,
          icon: Icons.tv,
          color: Colors.blue,
          commandOn: 'TV_SALON_ON',
          commandOff: 'TV_SALON_OFF',
          courant: 0.15,
        ),
        Device2(
          id: 'salon_clim',
          name: 'Climatiseur',
          isActive: false,
          icon: Icons.ac_unit,
          color: Colors.blue,
          commandOn: 'CLIM_SALON_ON',
          commandOff: 'CLIM_SALON_OFF',
          courant: 1.5,
        ),
        Device2(
          id: 'salon_ventilateur',
          name: 'Ventilateur',
          isActive: false,
          icon: Icons.air,
          color: Colors.blueGrey,
          commandOn: 'VENTILATEUR_SALON_ON',
          commandOff: 'VENTILATEUR_SALON_OFF',
          courant: 0.08,
        ),
        Device2(
          id: 'salon_ampoule1',
          name: 'Ampoule Principale',
          isActive: false,
          icon: Icons.lightbulb_outline,
          color: Colors.amber,
          commandOn: 'LED_SALON_PRINCIPALE_ON',
          commandOff: 'LED_SALON_PRINCIPALE_OFF',
          courant: 0.05,
        ),
        Device2(
          id: 'salon_ampoule2',
          name: 'Ampoule Ambiance',
          isActive: false,
          icon: Icons.lightbulb,
          color: Colors.amber,
          commandOn: 'LED_SALON_AMBIANCE_ON',
          commandOff: 'LED_SALON_AMBIANCE_OFF',
          courant: 0.03,
        ),
        Device2(
          id: 'salon_pir',
          name: 'Capteur Mouv. PIR',
          isActive: false,
          icon: Icons.motion_photos_auto,
          color: Colors.green,
          commandOn: 'PIR_SALON_ON',
          commandOff: 'PIR_SALON_OFF',
          courant: 0.01,
        ),
        Device2(
          id: 'salon_ldr',
          name: 'Capteur Luminosité',
          isActive: false,
          icon: Icons.light_mode,
          color: Colors.yellow,
          commandOn: 'LDR_SALON_ON',
          commandOff: 'LDR_SALON_OFF',
          courant: 0.01,
        ),
      ],
    ),
    Room(
      id: '2',
      name: 'Chambre Parents',
      icon: '🛌',
      isDefault: true,
      devices: [
        Device2(
          id: 'chambre_clim',
          name: 'Climatiseur',
          isActive: false,
          icon: Icons.ac_unit,
          color: Colors.blue,
          commandOn: 'CLIM_CHAMBRE_ON',
          commandOff: 'CLIM_CHAMBRE_OFF',
          courant: 1.2,
        ),
        Device2(
          id: 'chambre_chauffage',
          name: 'Chauffage',
          isActive: false,
          icon: Icons.thermostat,
          color: Colors.red,
          commandOn: 'CHAUFFAGE_CHAMBRE_ON',
          commandOff: 'CHAUFFAGE_CHAMBRE_OFF',
          courant: 1.8,
        ),
        Device2(
          id: 'chambre_humidificateur',
          name: 'Humidificateur',
          isActive: false,
          icon: Icons.water_drop,
          color: Colors.cyan,
          commandOn: 'HUMIDIFICATEUR_CHAMBRE_ON',
          commandOff: 'HUMIDIFICATEUR_CHAMBRE_OFF',
          courant: 0.15,
        ),
        Device2(
          id: 'chambre_ampoule1',
          name: 'Ampoule Chevet',
          isActive: false,
          icon: Icons.lightbulb_outline,
          color: Colors.amber,
          commandOn: 'LED_CHEVET_ON',
          commandOff: 'LED_CHEVET_OFF',
          courant: 0.04,
        ),
        Device2(
          id: 'chambre_ampoule2',
          name: 'Ampoule Placard',
          isActive: false,
          icon: Icons.lightbulb,
          color: Colors.amber,
          commandOn: 'LED_PLACARD_ON',
          commandOff: 'LED_PLACARD_OFF',
          courant: 0.03,
        ),
        Device2(
          id: 'chambre_pir',
          name: 'Capteur Mouv. PIR',
          isActive: false,
          icon: Icons.motion_photos_auto,
          color: Colors.green,
          commandOn: 'PIR_CHAMBRE_ON',
          commandOff: 'PIR_CHAMBRE_OFF',
          courant: 0.01,
        ),
        Device2(
          id: 'chambre_ultrasonic',
          name: 'Capteur Ultrason',
          isActive: false,
          icon: Icons.sensors,
          color: Colors.orange,
          commandOn: 'ULTRASONIC_CHAMBRE_ON',
          commandOff: 'ULTRASONIC_CHAMBRE_OFF',
          courant: 0.02,
        ),
      ],
    ),
    Room(
      id: '3',
      name: 'Cuisine',
      icon: '🍳',
      isDefault: true,
      devices: [
        Device2(
          id: 'cuisine_frigo',
          name: 'Réfrigérateur',
          isActive: false,
          icon: Icons.kitchen,
          color: Colors.blue,
          commandOn: 'FRIGO_CUISINE_ON',
          commandOff: 'FRIGO_CUISINE_OFF',
          courant: 0.8,
        ),
        Device2(
          id: 'cuisine_four',
          name: 'Four',
          isActive: false,
          icon: Icons.restaurant_menu,
          color: Colors.red,
          commandOn: 'FOUR_CUISINE_ON',
          commandOff: 'FOUR_CUISINE_OFF',
          courant: 2.5,
        ),
        Device2(
          id: 'cuisine_lave_vaisselle',
          name: 'Lave-vaisselle',
          isActive: false,
          icon: Icons.kitchen,
          color: Colors.blue,
          commandOn: 'LAVE_VAISSELLE_ON',
          commandOff: 'LAVE_VAISSELLE_OFF',
          courant: 1.2,
        ),
        Device2(
          id: 'cuisine_ampoule1',
          name: 'Ampoule Plafond',
          isActive: false,
          icon: Icons.lightbulb_outline,
          color: Colors.amber,
          commandOn: 'LED_CUISINE_ON',
          commandOff: 'LED_CUISINE_OFF',
          courant: 0.06,
        ),
        Device2(
          id: 'cuisine_ampoule2',
          name: 'Ampoule Plan de travail',
          isActive: false,
          icon: Icons.lightbulb,
          color: Colors.amber,
          commandOn: 'LED_PLAN_ON',
          commandOff: 'LED_PLAN_OFF',
          courant: 0.04,
        ),
        Device2(
          id: 'cuisine_fumee',
          name: 'Capteur Fumée',
          isActive: false,
          icon: Icons.smoke_free,
          color: Colors.red,
          commandOn: 'SMOKE_CUISINE_ON',
          commandOff: 'SMOKE_CUISINE_OFF',
          courant: 0.01,
        ),
        Device2(
          id: 'cuisine_gaz',
          name: 'Capteur Gaz',
          isActive: false,
          icon: Icons.gas_meter,
          color: Colors.orange,
          commandOn: 'GAS_CUISINE_ON',
          commandOff: 'GAS_CUISINE_OFF',
          courant: 0.01,
        ),
      ],
    ),
    Room(
      id: '4',
      name: 'Salle de Bain',
      icon: '🚿',
      isDefault: true,
      devices: [
        Device2(
          id: 'sdb_chauffage',
          name: 'Chauffage Sèche-serviette',
          isActive: false,
          icon: Icons.thermostat,
          color: Colors.red,
          commandOn: 'CHAUFFAGE_SDB_ON',
          commandOff: 'CHAUFFAGE_SDB_OFF',
          courant: 1.5,
        ),
        Device2(
          id: 'sdb_ventilation',
          name: 'Ventilation',
          isActive: false,
          icon: Icons.air,
          color: Colors.blueGrey,
          commandOn: 'VENTILATION_SDB_ON',
          commandOff: 'VENTILATION_SDB_OFF',
          courant: 0.1,
        ),
        Device2(
          id: 'sdb_prise',
          name: 'Prise Rasoir',
          isActive: false,
          icon: Icons.power,
          color: Colors.green,
          commandOn: 'PRISE_SDB_ON',
          commandOff: 'PRISE_SDB_OFF',
          courant: 0.02,
        ),
        Device2(
          id: 'sdb_ampoule1',
          name: 'Ampoule Principale',
          isActive: false,
          icon: Icons.lightbulb_outline,
          color: Colors.amber,
          commandOn: 'LED_SDB_ON',
          commandOff: 'LED_SDB_OFF',
          courant: 0.06,
        ),
        Device2(
          id: 'sdb_ampoule2',
          name: 'Ampoule Miroir',
          isActive: false,
          icon: Icons.lightbulb,
          color: Colors.amber,
          commandOn: 'LED_MIROIR_ON',
          commandOff: 'LED_MIROIR_OFF',
          courant: 0.03,
        ),
        Device2(
          id: 'sdb_humidite',
          name: 'Capteur Humidité',
          isActive: false,
          icon: Icons.water,
          color: Colors.blue,
          commandOn: 'HUMIDITY_SDB_ON',
          commandOff: 'HUMIDITY_SDB_OFF',
          courant: 0.01,
        ),
        Device2(
          id: 'sdb_mouvement',
          name: 'Capteur Mouvement',
          isActive: false,
          icon: Icons.directions_run,
          color: Colors.green,
          commandOn: 'MOUVEMENT_SDB_ON',
          commandOff: 'MOUVEMENT_SDB_OFF',
          courant: 0.02,
        ),
      ],
    ),
  ];

  // Pièces personnalisables
  List<Room> _customRooms = [];

  // Icônes disponibles
  final List<String> _roomIcons = ['🏠', '🚪', '🪟', '🛏️', '🚿', '📚', '🍴', '🎮', '🛋️', '🧸', '🍳', '🛌', '🚽', '📺', '💻', '🎵'];

  StreamSubscription<String>? _messageSub;

  // Conversion des Device2 en Device pour la page consommation
  List<Device> get allDevicesForConsommation {
    List<Device> all = [];
    for (var room in _defaultRooms) {
      all.addAll(room.devices.map((device2) => Device(
        id: device2.id,
        name: device2.name,
        isActive: device2.isActive,
        icon: device2.icon,
        color: device2.color,
        commandOn: device2.commandOn,
        commandOff: device2.commandOff,
        courant: device2.courant,
      )));
    }
    for (var room in _customRooms) {
      all.addAll(room.devices.map((device2) => Device(
        id: device2.id,
        name: device2.name,
        isActive: device2.isActive,
        icon: device2.icon,
        color: device2.color,
        commandOn: device2.commandOn,
        commandOff: device2.commandOff,
        courant: device2.courant,
      )));
    }
    return all;
  }

  List<Room> get allRooms => [..._defaultRooms, ..._customRooms];

  Room? get selectedRoom {
    if (_selectedRoom == null) return null;
    try {
      return allRooms.firstWhere((room) => room.id == _selectedRoom);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
    _loadCustomRooms();
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
      });
    }
  }

  void _addToHistory(String message) {
    setState(() {
      _commandHistory.add(message);
      if (_commandHistory.length > 5) {
        _commandHistory.removeAt(0);
      }
    });
  }

  // Sauvegarde des pièces personnalisées
  Future<void> _saveCustomRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> roomsJson = _customRooms.map((room) => room.toJson()).toList();
      await prefs.setStringList('custom_rooms', roomsJson);
    } catch (e) {
      debugPrint('Erreur sauvegarde: $e');
    }
  }

  // Chargement des pièces personnalisées
  Future<void> _loadCustomRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? roomsJson = prefs.getStringList('custom_rooms');
      if (roomsJson != null) {
        setState(() {
          _customRooms = roomsJson.map((json) => Room.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  // Ajouter une nouvelle pièce
  void _addNewRoom() {
    if (_customRooms.length >= 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 16 pièces personnalisables atteint')),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();
    String selectedIcon = '🏠';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle Pièce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la pièce',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 16),
                const Text('Choisir une icône:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _roomIcons.map((icon) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedIcon == icon ? Colors.blue : Colors.grey,
                          width: selectedIcon == icon ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    final newRoom = Room(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      icon: selectedIcon,
                      isDefault: false,
                      devices: [],
                    );
                    _customRooms.add(newRoom);
                    _saveCustomRooms();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  // Modifier une pièce
  void _editRoom(Room room) {
    TextEditingController nameController = TextEditingController(text: room.name);
    String selectedIcon = room.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier la Pièce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la pièce',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 16),
                const Text('Choisir une icône:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _roomIcons.map((icon) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedIcon == icon ? Colors.blue : Colors.grey,
                          width: selectedIcon == icon ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    room.name = nameController.text;
                    room.icon = selectedIcon;
                    if (!room.isDefault) {
                      _saveCustomRooms();
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // Supprimer une pièce
  void _deleteRoom(Room room) {
    if (room.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les pièces par défaut ne peuvent pas être supprimées')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la Pièce'),
        content: Text('Supprimer "${room.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customRooms.remove(room);
                _saveCustomRooms();
                if (_selectedRoom == room.id) {
                  _selectedRoom = null;
                }
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

  // Ajouter un nouvel appareil
  void _addNewDevice() {
    if (selectedRoom == null) return;

    TextEditingController nameController = TextEditingController();
    TextEditingController onController = TextEditingController();
    TextEditingController offController = TextEditingController();
    TextEditingController courantController = TextEditingController(text: '0.1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel Appareil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'appareil',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: onController,
                decoration: const InputDecoration(
                  labelText: 'Commande ON',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: offController,
                decoration: const InputDecoration(
                  labelText: 'Commande OFF',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courantController,
                decoration: const InputDecoration(
                  labelText: 'Courant (A)',
                  border: OutlineInputBorder(),
                ),
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
                  final newDevice = Device2(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    isActive: false,
                    icon: Icons.device_unknown,
                    color: Colors.grey,
                    commandOn: onController.text,
                    commandOff: offController.text,
                    courant: double.tryParse(courantController.text) ?? 0.1,
                  );
                  selectedRoom!.devices.add(newDevice);
                  if (!selectedRoom!.isDefault) {
                    _saveCustomRooms();
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

  // Modifier un appareil
  void _editDevice(Device2 device) {
    if (selectedRoom == null) return;

    TextEditingController nameController = TextEditingController(text: device.name);
    TextEditingController onController = TextEditingController(text: device.commandOn);
    TextEditingController offController = TextEditingController(text: device.commandOff);
    TextEditingController courantController = TextEditingController(text: device.courant.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier Appareil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'appareil',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: onController,
                decoration: const InputDecoration(
                  labelText: 'Commande ON',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: offController,
                decoration: const InputDecoration(
                  labelText: 'Commande OFF',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courantController,
                decoration: const InputDecoration(
                  labelText: 'Courant (A)',
                  border: OutlineInputBorder(),
                ),
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
                if (!selectedRoom!.isDefault) {
                  _saveCustomRooms();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Supprimer un appareil
  void _deleteDevice(Device2 device) {
    if (selectedRoom == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer Appareil'),
        content: Text('Supprimer "${device.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedRoom!.devices.remove(device);
                if (!selectedRoom!.isDefault) {
                  _saveCustomRooms();
                }
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

  // Basculer l'état d'un appareil
  Future<void> _toggleDevice(Device2 device, bool value) async {
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

    final command = value ? device.commandOn : device.commandOff;
    _addToHistory('> $command');

    final result = await widget.commandSender.sendCommand(command);

    if (!mounted) return;

    if (result.success) {
      _addToHistory('✅ ${result.message}');
    } else {
      setState(() {
        device.isActive = !value;
      });
      _addToHistory('❌ ${result.message}');
    }
  }

  // Tout activer/désactiver
  void _toggleAllDevices(bool value) {
    if (selectedRoom == null) return;
    
    final isConnected = widget.commandSender.connectionService.isConnected.value;
    if (!isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non connecté à un appareil')),
      );
      return;
    }

    final command = value ? 'toutactiver' : 'toutdesactiver';
    _sendGlobalCommand(command, value);
  }

  Future<void> _sendGlobalCommand(String command, bool value) async {
    _addToHistory('> $command');

    final result = await widget.commandSender.sendCommand(command);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        for (var device in selectedRoom!.devices) {
          device.isActive = value;
        }
      });
      _addToHistory('✅ ${result.message}');
    } else {
      _addToHistory('❌ ${result.message}');
    }
  }

  // Navigation vers la page consommation
  void _navigateToConsommation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsommationPage(devices: allDevicesForConsommation),
      ),
    );
  }

  // Contenu principal adaptatif
  Widget _buildRoomContent() {
    if (selectedRoom != null) {
      return _buildDeviceContent();
    } else {
      return _buildRoomsGrid();
    }
  }

  // Contenu des appareils d'une pièce - VERSION CORRIGÉE
  Widget _buildDeviceContent() {
    final room = selectedRoom!;
    final devices = room.devices;

    return Column(
      children: [
        // CORRECTION : Boutons tout activer/désactiver adaptatifs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 300;
              
              return isCompact 
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleAllDevices(true),
                          icon: const Icon(Icons.power, size: 16),
                          label: const Text('TOUT ON', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[100],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleAllDevices(false),
                          icon: const Icon(Icons.power_off, size: 16),
                          label: const Text('TOUT OFF', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleAllDevices(true),
                            icon: const Icon(Icons.power, size: 18),
                            label: const Text('Tout activer', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleAllDevices(false),
                            icon: const Icon(Icons.power_off, size: 18),
                            label: const Text('Tout désactiver', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
            },
          ),
        ),
        
        // Liste des appareils - CORRECTION : Utilisation d'Expanded
        Expanded(
          child: devices.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.devices, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun appareil',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoutez votre premier appareil à cette pièce',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addNewDevice,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un appareil'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: Icon(device.icon, color: device.color, size: 28),
                      title: Text(
                        device.name,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ON: ${device.commandOn}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'OFF: ${device.commandOff}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Courant: ${device.courant}A',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: device.isActive,
                            onChanged: (value) => _toggleDevice(device, value),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editDevice(device);
                              } else if (value == 'delete') {
                                _deleteDevice(device);
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
        
        // Feedback (seulement si visible)
        if (_isFeedbackVisible) 
          Container(
            height: 120,
            margin: const EdgeInsets.only(top: 8),
            child: _buildFeedbackConsole(),
          ),
      ],
    );
  }

  // Grille des pièces - VERSION CORRIGÉE
  Widget _buildRoomsGrid() {
    return Column(
      children: [
        // En-tête avec bouton d'ajout - CORRIGÉ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pièces de la Maison (${allRooms.length})',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 24, color: Colors.blue),
                  onPressed: _addNewRoom,
                  tooltip: 'Ajouter une pièce',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
        
        // CORRECTION : Grille adaptative avec LayoutBuilder
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              final int crossAxisCount = availableWidth > 600 ? 4 : 
                                       availableWidth > 400 ? 3 : 2;
              final double childAspectRatio = availableWidth > 400 ? 0.9 : 0.85;
              
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: allRooms.length,
                itemBuilder: (context, index) {
                  final room = allRooms[index];
                  return _buildRoomCard(room);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Carte d'une pièce - VERSION CORRIGÉE
  Widget _buildRoomCard(Room room) {
    final activeDevices = room.devices.where((device) => device.isActive).length;
    final totalDevices = room.devices.length;

    return Card(
      color: const Color.fromARGB(255, 247, 210, 232),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _selectedRoom = room.id),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Contenu principal - CORRIGÉ
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône adaptative
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        room.icon, 
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Nom de la pièce - CORRECTION : Texte adaptatif
                  Flexible(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Nombre d'appareils actifs
                  Flexible(
                    child: Text(
                      '$activeDevices/$totalDevices actifs',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu trois points en haut à droite - CORRECTION : Taille réduite
            Positioned(
              top: 2,
              right: 2,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[700]),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editRoom(room);
                  } else if (value == 'delete' && !room.isDefault) {
                    _deleteRoom(room);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Renommer')),
                  if (!room.isDefault)
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Console de feedback
  Widget _buildFeedbackConsole() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête du feedback
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Feedback', style: TextStyle(color: Colors.white)),
                Icon(Icons.message, color: Colors.white, size: 16),
              ],
            ),
          ),
          // Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _commandHistory.length,
              itemBuilder: (context, index) {
                final bool isCommand = _commandHistory[index].startsWith('> ');
                final bool isError = _commandHistory[index].startsWith('❌');
                final bool isSuccess = _commandHistory[index].startsWith('✅');
                
                return Container(
                  color: index.isEven ? Colors.transparent : Colors.black.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    _commandHistory[index],
                    style: TextStyle(
                      color: isCommand 
                          ? const Color.fromRGBO(238, 237, 242, 1)
                          : isError
                            ? const Color(0xFFFF5252)
                            : isSuccess
                              ? const Color.fromRGBO(76, 175, 80, 1)
                              : const Color.fromRGBO(241, 237, 237, 1),
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
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

  // BUILD PRINCIPAL - VERSION CORRIGÉE
  @override
  Widget build(BuildContext context) {
    final isConnected = widget.commandSender.connectionService.isConnected.value;
    final connectedDevice = widget.commandSender.connectionService.connectedDevice.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: _selectedRoom != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => setState(() => _selectedRoom = null),
              )
            : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            // CORRECTION : Titre adaptatif dans l'AppBar
            Expanded(
              child: Text(
                selectedRoom?.name ?? 'Ma maison',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          // CORRECTION : Actions avec contraintes de taille
          if (_selectedRoom != null) ...[
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              onPressed: _addNewDevice,
              tooltip: 'Ajouter un appareil',
              padding: const EdgeInsets.all(4),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.bolt, size: 22),
            onPressed: _navigateToConsommation,
            tooltip: 'Consommation énergétique',
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.device_hub, size: 22),
            onPressed: _showDeviceStatus,
            tooltip: 'État des appareils',
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: Icon(
              _isFeedbackVisible ? Icons.visibility : Icons.visibility_off, 
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isFeedbackVisible = !_isFeedbackVisible;
              });
            },
            tooltip: _isFeedbackVisible ? 'Masquer le feedback' : 'Afficher le feedback',
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de connexion - CORRECTION : Padding réduit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isConnected
                      ? 'Connecté à $connectedDevice'
                      : 'Non connecté - Connectez-vous depuis l\'accueil',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // CORRECTION : Contenu principal avec Expanded
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildRoomContent(),
            ),
          ),
          
          // Feedback en bas si visible
          if (_isFeedbackVisible && _selectedRoom == null)
            Container(
              height: 120,
              margin: const EdgeInsets.all(8),
              child: _buildFeedbackConsole(),
            ),
        ],
      ),
    );
  }

  // Afficher l'état des appareils
  void _showDeviceStatus() {
    final activeDevices = allDevicesForConsommation.where((device) => device.isActive).toList();
    final inactiveDevices = allDevicesForConsommation.where((device) => !device.isActive).toList();

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
          subtitle: Text('${device.commandOn} / ${device.commandOff}'),
          dense: true,
          visualDensity: VisualDensity.compact,
        )),
      ],
    );
  }
}

class Room {
  String id;
  String name;
  String icon;
  bool isDefault;
  List<Device2> devices;

  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.isDefault,
    required this.devices,
  });

  // Conversion en JSON pour la sauvegarde
  String toJson() {
    return json.encode({
      'id': id,
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
      'devices': devices.map((d) => d.toJson()).toList(),
    });
  }

  // Création depuis JSON
  factory Room.fromJson(String jsonString) {
    final data = json.decode(jsonString);
    return Room(
      id: data['id'],
      name: data['name'],
      icon: data['icon'],
      isDefault: data['isDefault'],
      devices: List<Device2>.from(data['devices'].map((d) => Device2.fromJson(d))),
    );
  }
}