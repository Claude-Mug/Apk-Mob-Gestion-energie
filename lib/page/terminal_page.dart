import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_reine/services/connection_service.dart';
import 'package:api_reine/services/command_sender.dart';

class TerminalPage extends StatefulWidget {
  final bool isConnected;
  final CommandSender commandSender;

  const TerminalPage({super.key, required this.isConnected, required this.commandSender});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _commandHistory = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _messageSubscription;

  // Accéder au ConnectionService via le CommandSender
  ConnectionService get _connectionService => widget.commandSender.connectionService;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    _messageSubscription = _connectionService.messageStream.listen((message) {
      setState(() {
        _commandHistory.add('📨 $message');
      });
      _scrollToBottom();
    });
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

  Future<void> _executeCommand(String command) async {
    if (command.isEmpty) return;

    setState(() {
      _commandHistory.add('> $command');
    });

    // Vérifier la connexion avant d'envoyer la commande
    if (!_connectionService.isConnected.value) {
      setState(() {
        _commandHistory.add('❌ Non connecté à un appareil');
        _commandHistory.add('💡 Connectez-vous depuis la page d\'accueil');
      });
      _scrollToBottom();
      _commandController.clear();
      return;
    }

    try {
      // Envoyer la commande via le commandSender passé en paramètre
      final result = await widget.commandSender.sendCommand(command);
      
      setState(() {
        if (result.success) {
          _commandHistory.add('✅ ${result.message}');
        } else {
          _commandHistory.add('❌ ${result.message}');
        }
      });
    } catch (e) {
      setState(() {
        _commandHistory.add('❌ Erreur: $e');
      });
    }

    _scrollToBottom();
    _commandController.clear();
  }

  void _clearHistory() {
    setState(() {
      _commandHistory.clear();
    });
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Informations de connexion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statut: ${_connectionService.isConnected.value ? 'Connecté' : 'Déconnecté'}'),
              if (_connectionService.isConnected.value) ...[
                const SizedBox(height: 8),
                Text('Appareil: ${_connectionService.connectedDevice.value}'),
                const SizedBox(height: 8),
                Text('Protocole: ${_connectionService.connectionType.value}'),
              ],
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(240, 240, 241, 1),
        title: const Text(
          'Terminal',
          style: TextStyle(
            color: Color.fromARGB(255, 14, 14, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _connectionService.isConnected.value ? Icons.wifi : Icons.wifi_off,
              color: _connectionService.isConnected.value ? Colors.green : Colors.red,
            ),
            onPressed: _showConnectionInfo,
            tooltip: 'Statut de connexion',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Color.fromARGB(255, 22, 22, 22)),
            onPressed: _clearHistory,
            tooltip: 'Effacer l\'historique',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 26, 26, 26)),
            onPressed: () {
              _executeCommand('help');
            },
            tooltip: 'Afficher l\'aide',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de connexion
          Container(
            color: _connectionService.isConnected.value ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  _connectionService.isConnected.value ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionService.isConnected.value
                      ? 'Connecté à ${_connectionService.connectedDevice.value}'
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
          
          // Historique des commandes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _commandHistory.length,
              itemBuilder: (context, index) {
                final bool isCommand = _commandHistory[index].startsWith('> ');
                final bool isError = _commandHistory[index].startsWith('❌');
                final bool isSuccess = _commandHistory[index].startsWith('✅');
                final bool isMessage = _commandHistory[index].startsWith('📨');
                
                return Container(
                  color: index.isEven ? Colors.transparent : Colors.black.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    _commandHistory[index],
                    style: TextStyle(
                      color: isCommand 
                          ? const Color.fromARGB(255, 13, 14, 13)
                          : isError
                            ? const Color(0xFFFF5252)
                            : isSuccess
                              ? const Color.fromARGB(186, 1, 132, 240)
                              : isMessage
                                ? const Color.fromARGB(255, 8, 8, 8)
                                : const Color.fromARGB(186, 1, 132, 240),
                      fontFamily: 'RobotoMono',
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Champ de saisie des commandes
          Container(
            color: const Color.fromARGB(139, 1, 132, 240),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text(
                  '>',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tapez une commande...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    onSubmitted: _executeCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _executeCommand(_commandController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}