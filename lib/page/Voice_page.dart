import 'package:flutter/material.dart';
import 'package:api_reine/services/connection_service.dart';
import 'package:api_reine/services/command_sender.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoicePage extends StatefulWidget {
  final bool isConnected;
  final CommandSender commandSender;
  
  const VoicePage({super.key, required this.isConnected, required this.commandSender});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _spokenText = "Appuyez sur le micro pour parler";
  bool _isListening = false;
  bool _speechAvailable = false;
  String _selectedLanguage = 'fr-FR';
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _permissionGranted = false;
  bool _enablePreprocessing = true;
  bool _convertToUppercase = true;
  bool _replaceSpaces = true;
  bool _removeSpaces = false;
  bool _removeAccents = true;
  String _replacementChar = '_';
  
  // Fonction de suppression des accents
  String _removeAccentsFromText(String text) {
    if (!_removeAccents) {
      return text;
    }
    
    final withDiactitics = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    final withoutDiactitics = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    
    String result = text;
    for (int i = 0; i < withDiactitics.length; i++) {
      result = result.replaceAll(withDiactitics[i], withoutDiactitics[i]);
    }
    return result;
  }

  // Fonction de prétraitement améliorée avec gestion des accents et espaces
  String _preprocessCommand(String command) {
    if (!_enablePreprocessing) {
      return command;
    }
    
    String processed = command;
    
    // Étape 1: Suppression des accents (si activée)
    if (_removeAccents) {
      processed = _removeAccentsFromText(processed);
    }
    
    // Étape 2: Conversion en majuscules/minuscules
    if (_convertToUppercase) {
      processed = processed.toUpperCase();
    } else {
      processed = processed.toLowerCase();
    }
    
    // Étape 3: Gestion des espaces
    if (_removeSpaces) {
      processed = processed.replaceAll(' ', '');
    } else if (_replaceSpaces) {
      processed = processed.replaceAll(' ', _replacementChar);
    }
    
    return processed;
  }

  // Accéder au ConnectionService via le CommandSender
  ConnectionService get _connectionService => widget.commandSender.connectionService;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // Initialisation de la reconnaissance vocale avec gestion des permissions
  void _initSpeech() async {
    // Vérifier d'abord la permission microphone
    final status = await Permission.microphone.status;
    
    if (status.isDenied) {
      // Demander la permission
      final result = await Permission.microphone.request();
      setState(() {
        _permissionGranted = result.isGranted;
      });
      
      if (!_permissionGranted) {
        _addMessage("Permission microphone refusée. Veuillez l'accorder dans les paramètres.", false);
        return;
      }
    } else if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
      });
    }

    // Initialiser la reconnaissance vocale seulement si la permission est accordée
    if (_permissionGranted) {
      try {
        _speechAvailable = await _speech.initialize(
          onStatus: (status) {
            setState(() {
              if (status == 'done' && _isListening) {
                _stopListening();
              }
            });
          },
          onError: (error) {
            setState(() {
              _isListening = false;
              _addMessage("Erreur: $error", false);
            });
          },
        );
        
        if (!_speechAvailable) {
          _addMessage("Reconnaissance vocale non disponible sur cet appareil", false);
        }
      } catch (e) {
        _addMessage("Erreur d'initialisation: $e", false);
      }
    }
    
    setState(() {});
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.insert(0, Message(text: text, isUser: isUser, timestamp: DateTime.now()));
      _scrollToTop();
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startListening() async {
    // Vérifier à nouveau la permission au cas où elle aurait été révoquée
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      _addMessage("Permission microphone non accordée", false);
      return;
    }

    if (!_speechAvailable) {
      _addMessage("Reconnaissance vocale non disponible", false);
      return;
    }

    if (!_connectionService.isConnected.value) {
      _addMessage("Non connecté à un appareil. Connectez-vous d'abord.", false);
      return;
    }

    setState(() {
      _isListening = true;
    });
    _addMessage("Je vous écoute...", false);

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
        },
        localeId: _selectedLanguage,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {
          // Optionnel: pour une visualisation du niveau sonore
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      _addMessage("Erreur lors de l'écoute: $e", false);
    }
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
    });
    
    try {
      await _speech.stop();

      // Envoyer la commande reconnue
      if (_spokenText.isNotEmpty && _spokenText != "Je vous écoute...") {
        _addMessage(_spokenText, true);
        _sendCommand(_spokenText);
      }
    } catch (e) {
      _addMessage("Erreur lors de l'arrêt: $e", false);
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Envoi de commande avec prétraitement
  Future<void> _sendCommand(String command) async {
    if (!_connectionService.isConnected.value) {
      _addMessage("Non connecté à un appareil", false);
      return;
    }

    try {
      final processedCommand = _preprocessCommand(command);
      final result = await widget.commandSender.sendCommand(processedCommand);
      
      _addMessage(
        result.success 
          ? "Commande envoyée: $processedCommand\nRéponse: ${result.message}"
          : "Erreur: ${result.message}",
        false
      );
    } catch (e) {
      _addMessage("Erreur d'envoi: $e", false);
    }
  }

  // Dialog des paramètres avec options d'accent et d'espacement
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Variables temporaires pour la dialog
        bool tempEnablePreprocessing = _enablePreprocessing;
        bool tempConvertToUppercase = _convertToUppercase;
        bool tempReplaceSpaces = _replaceSpaces;
        bool tempRemoveSpaces = _removeSpaces;
        bool tempRemoveAccents = _removeAccents;
        String tempReplacementChar = _replacementChar;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Paramètres Vocaux', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   
                    const SizedBox(height: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: _connectionService.isConnected,
                      builder: (context, isConnected, child) {
                        return Text(
                          'Statut: ${isConnected ? 'Connecté' : 'Déconnecté'}',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permission microphone: ${_permissionGranted ? 'Accordée' : 'Refusée'}',
                      style: TextStyle(
                        color: _permissionGranted ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reconnaissance vocale: ${_speechAvailable ? 'Disponible' : 'Indisponible'}',
                      style: TextStyle(
                        color: _speechAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    
                    // Options de prétraitement
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Prétraitement des commandes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    SwitchListTile(
                      title: const Text('Activer le prétraitement'),
                      value: tempEnablePreprocessing,
                      onChanged: (value) {
                        setStateDialog(() {
                          tempEnablePreprocessing = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Convertir en majuscules'),
                      value: tempConvertToUppercase,
                      onChanged: tempEnablePreprocessing ? (value) {
                        setStateDialog(() {
                          tempConvertToUppercase = value;
                        });
                      } : null,
                    ),

                    // Option pour supprimer les accents
                    SwitchListTile(
                      title: const Text('Supprimer les accents'),
                      subtitle: const Text('Convertir les caractères accentués en non-accentués'),
                      value: tempRemoveAccents,
                      onChanged: tempEnablePreprocessing ? (value) {
                        setStateDialog(() {
                          tempRemoveAccents = value;
                        });
                      } : null,
                    ),
                    
                    // Nouvelle section pour la gestion des espaces
                    const SizedBox(height: 8),
                    const Text(
                      'Gestion des espaces:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Option 1: Garder les espaces
                    RadioListTile<bool>(
                      title: const Text('Garder les espaces'),
                      value: false,
                      groupValue: tempRemoveSpaces,
                      onChanged: tempEnablePreprocessing ? (value) {
                        setStateDialog(() {
                          tempRemoveSpaces = false;
                          tempReplaceSpaces = false;
                        });
                      } : null,
                    ),
                    
                    // Option 2: Remplacer les espaces
                    RadioListTile<bool>(
                      title: const Text('Remplacer les espaces'),
                      value: false,
                      groupValue: tempRemoveSpaces,
                      onChanged: tempEnablePreprocessing ? (value) {
                        setStateDialog(() {
                          tempRemoveSpaces = false;
                          tempReplaceSpaces = true;
                        });
                      } : null,
                    ),
                    
                    // Option 3: Supprimer les espaces
                    RadioListTile<bool>(
                      title: const Text('Supprimer les espaces (coller les mots)'),
                      value: true,
                      groupValue: tempRemoveSpaces,
                      onChanged: tempEnablePreprocessing ? (value) {
                        setStateDialog(() {
                          tempRemoveSpaces = true;
                          tempReplaceSpaces = false;
                        });
                      } : null,
                    ),
                    
                    // Champ pour le caractère de remplacement (seulement si l'option est activée)
                    if (tempEnablePreprocessing && tempReplaceSpaces && !tempRemoveSpaces)
                      ListTile(
                        title: const Text('Caractère de remplacement'),
                        trailing: SizedBox(
                          width: 50,
                          child: TextFormField(
                            initialValue: tempReplacementChar,
                            maxLength: 1,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setStateDialog(() {
                                  tempReplacementChar = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!_permissionGranted)
                  TextButton(
                    onPressed: () async {
                      await openAppSettings();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Ouvrir les paramètres'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _enablePreprocessing = tempEnablePreprocessing;
                      _convertToUppercase = tempConvertToUppercase;
                      _replaceSpaces = tempReplaceSpaces;
                      _removeSpaces = tempRemoveSpaces;
                      _replacementChar = tempReplacementChar;
                      _removeAccents = tempRemoveAccents;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Interface utilisateur principale avec indicateurs d'état
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Commande Vocale',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _connectionService.isConnected,
            builder: (context, isConnected, child) {
              return IconButton(
                icon: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                onPressed: _showSettingsDialog,
                tooltip: 'Statut de connexion',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de connexion
          ValueListenableBuilder<bool>(
            valueListenable: _connectionService.isConnected,
            builder: (context, isConnected, child) {
              return Container(
                color: isConnected 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConnected 
                          ? 'Connecté à ${_connectionService.connectedDevice.value}'
                          : 'Non connecté - Allez à l\'accueil pour vous connecter',
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Historique des messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      "Aucun message encore\nParlez pour envoyer une commande",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        message: message,
                      );
                    },
                  ),
          ),
          
          // Zone du microphone
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  _isListening ? "Écoute en cours..." : "Appuyez pour parler",
                  style: TextStyle(
                    color: _isListening ? Colors.blue : const Color.fromARGB(255, 155, 133, 133),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _speechAvailable && _permissionGranted ? _toggleListening : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening 
                        ? Colors.blue 
                        : (_speechAvailable && _permissionGranted ? Colors.grey[200] : Colors.grey[100]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _isListening 
                          ? Colors.blue.shade300 
                          : (_speechAvailable && _permissionGranted ? Colors.grey.shade400 : Colors.grey.shade300),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 40,
                      color: _isListening 
                        ? Colors.white 
                        : (_speechAvailable && _permissionGranted ? Colors.grey[700] : Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (!_permissionGranted)
                  Column(
                    children: [
                      const Text(
                        'Permission microphone refusée',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        child: const Text('Ouvrir les paramètres'),
                      ),
                    ],
                  ),
                if (_permissionGranted && !_speechAvailable)
                  const Text(
                    'Reconnaissance vocale non disponible',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                  ? Colors.blue[100] 
                  : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
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

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}