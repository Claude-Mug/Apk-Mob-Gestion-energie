import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:api_reine/page/categorie_page.dart';
import 'package:api_reine/page/voice_page.dart';
import 'package:api_reine/page/terminal_page.dart';
import 'package:api_reine/services/connection_service.dart';
import 'package:api_reine/services/command_sender.dart';
import 'package:api_reine/page/energy_page.dart';
import 'package:api_reine/dialogs/settings_dialog.dart';
 // Ajustez le chemin selon votre structure


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/energy': (context) => const EnergyPage(),
        '/categories': (context) => CategoriesPage(isConnected: false, commandSender: CommandSender(ConnectionService())),
        '/terminal': (context) => TerminalPage(isConnected: false, commandSender: CommandSender(ConnectionService())),
        '/voice': (context) => VoicePage(isConnected: false, commandSender: CommandSender(ConnectionService())),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  TextEditingController ipController = TextEditingController();
  TextEditingController portController = TextEditingController();
  String selectedConnectionType = 'HTTP';
  bool _isConnecting = false;
  List<Map<String, dynamic>> _recentDevices = [];

  final ConnectionService _connectionService = ConnectionService();
  late CommandSender _commandSender;

  @override
  void initState() {
    super.initState();
    _commandSender = CommandSender(_connectionService);
    _loadRecentDevices();
    _connectionService.connectedDevice.addListener(_onConnectedDeviceChanged);
  }

  @override
  void dispose() {
    _connectionService.connectedDevice.removeListener(_onConnectedDeviceChanged);
    super.dispose();
  }

  void _onConnectedDeviceChanged() {
    setState(() {});
  }

  void _loadRecentDevices() async {
    final devices = await _connectionService.getRecentDevices();
    setState(() {
      _recentDevices = devices;
    });
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE d.MM', 'fr_FR');
    return formatter.format(now);
  }
void _showSettingsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SettingsDialog(); // Votre nouveau dialogue de paramètres
    },
  );
}

  void _showRecentDevices() async {
    final devices = await _connectionService.getRecentDevices();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appareils récents'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text('${device['ip']}:${device['port']}'),
                  subtitle: Text('Protocole: ${device['protocol']}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ipController.text = device['ip'];
                    portController.text = device['port'].toString();
                    setState(() {
                      selectedConnectionType = device['protocol'];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
    });

    String ip = ipController.text;
    int port = int.tryParse(portController.text) ?? 0;

    if (ip.isEmpty || port == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une IP et un port valides')),
      );
      setState(() {
        _isConnecting = false;
      });
      return;
    }

    try {
      bool success = await _connectionService.connect(ip, port, selectedConnectionType);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecentDevices();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(186, 1, 132, 240),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Smart Home Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_recentDevices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.devices, color: Colors.white),
              onPressed: _showRecentDevices,
              tooltip: 'Appareils récents',
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _connectionService.isConnected,
        builder: (context, isConnected, child) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              HomeContent(
                isConnected: isConnected,
                onConnect: _connect,
                isConnecting: _isConnecting,
                ipController: ipController,
                portController: portController,
                connectionType: selectedConnectionType,
                onConnectionTypeChanged: (value) {
                  setState(() {
                    selectedConnectionType = value;
                  });
                },
                connectedDeviceAddress: _connectionService.connectedDevice.value,
              ),
              EnergyPage(),
              // Dans HomePage, modifiez la construction de CategoriesPage
              CategoriesPage(isConnected: isConnected, commandSender: _commandSender),
              TerminalPage(isConnected: isConnected, commandSender: _commandSender),
              VoicePage(isConnected: isConnected, commandSender: _commandSender),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(186, 1, 132, 240),
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 8),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 28),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Énergie'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Catégories'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Terminal'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Vocal'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onConnect;
  final bool isConnecting;
  final TextEditingController ipController;
  final TextEditingController portController;
  final String connectionType;
  final ValueChanged<String> onConnectionTypeChanged;
  final String? connectedDeviceAddress;

  const HomeContent({
    super.key,
    required this.isConnected,
    required this.onConnect,
    required this.isConnecting,
    required this.ipController,
    required this.portController,
    required this.connectionType,
    required this.onConnectionTypeChanged,
    this.connectedDeviceAddress,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: const DecorationImage(
                image: AssetImage('assets/images/1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (isConnected && connectedDeviceAddress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Connecté à $connectedDeviceAddress',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connexion WiFi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(186, 1, 132, 240),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ipController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse IP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const Text('Type de connexion:'),
                  Row(
                    children: [
                      Radio(
                        value: 'HTTP',
                        groupValue: connectionType,
                        onChanged: (value) {
                          onConnectionTypeChanged(value!);
                        },
                      ),
                      const Text('HTTP'),
                      Radio(
                        value: 'WebSocket',
                        groupValue: connectionType,
                        onChanged: (value) {
                          onConnectionTypeChanged(value!);
                        },
                      ),
                      const Text('WebSocket'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: isConnecting ? null : onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(186, 1, 132, 240),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: isConnecting 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

