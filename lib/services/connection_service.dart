import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:api_reine/services/http.dart' as http_service;
import 'package:api_reine/services/websocket.dart' as ws_service;
import 'package:api_reine/services/recent_devices_service.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  // États de connexion
  final ValueNotifier<bool> _isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> _connectedDevice = ValueNotifier<String>('');
  final ValueNotifier<String> _connectionType = ValueNotifier<String>('HTTP');
  final ValueNotifier<String> _currentIp = ValueNotifier<String>('');
  final ValueNotifier<int> _currentPort = ValueNotifier<int>(0);

  // Services
  final http_service.HttpService _httpService = http_service.HttpService();
  final ws_service.WebSocketService _webSocketService = ws_service.WebSocketService();
  final RecentDevicesService _recentDevicesService = RecentDevicesService();

  // Streams pour les messages et événements
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<ConnectionEvent> _eventController = StreamController<ConnectionEvent>.broadcast();

  // Getters pour l'état de connexion
  ValueNotifier<bool> get isConnected => _isConnected;
  ValueNotifier<String> get connectedDevice => _connectedDevice;
  ValueNotifier<String> get connectionType => _connectionType;
  ValueNotifier<String> get currentIp => _currentIp;
  ValueNotifier<int> get currentPort => _currentPort;

  // Getters pour les services
  http_service.HttpService get httpService => _httpService;
  ws_service.WebSocketService get webSocketService => _webSocketService;

  // Getters pour les streams
  Stream<String> get messageStream => _messageController.stream;
  Stream<ConnectionEvent> get eventStream => _eventController.stream;

  // Méthodes utilitaires
  bool get isHttp => _connectionType.value == 'HTTP';
  bool get isWebSocket => _connectionType.value == 'WebSocket';

  Future<bool> connect(String ip, int port, String protocol) async {
    try {
      _messageController.add('Tentative de connexion à $ip:$port via $protocol...');
      _eventController.add(ConnectionEvent.connecting);

      bool success = false;
      String message = '';

      if (protocol == 'HTTP') {
        var result = await _httpService.testConnection(ip: ip, port: port);
        success = result.success;
        message = result.message;
      } else {
        _webSocketService.setWebSocketPort(port);
        success = await _webSocketService.connect(ip);
        message = success ? 'Connecté' : 'Échec de la connexion WebSocket';
        
        // Écouter les messages WebSocket
        if (success) {
          _webSocketService.messages.listen((msg) {
            _messageController.add('Reçu: $msg');
          });
        }
      }

      if (success) {
        _isConnected.value = true;
        _connectedDevice.value = '$ip:$port';
        _connectionType.value = protocol;
        _currentIp.value = ip;
        _currentPort.value = port;
        
        await _recentDevicesService.saveDevice(ip, port, protocol);
        _messageController.add('Connexion réussie: $message');
        _eventController.add(ConnectionEvent.connected);
        
        return true;
      } else {
        throw Exception(message);
      }
    } catch (e) {
      _messageController.add('Échec de la connexion: $e');
      _eventController.add(ConnectionEvent.disconnected);
      disconnect();
      rethrow;
    }
  }

  void addMessage(String message) {
  _messageController.add(message);
}

  void disconnect() {
    if (isWebSocket) {
      _webSocketService.disconnect();
    }
    
    _isConnected.value = false;
    _connectedDevice.value = '';
    _messageController.add('Déconnecté');
    _eventController.add(ConnectionEvent.disconnected);
  }

  Future<List<Map<String, dynamic>>> getRecentDevices() async {
    return await _recentDevicesService.getDevices();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _eventController.close();
    _httpService.dispose();
    _webSocketService.dispose();
  }
}

// Types d'événements de connexion
enum ConnectionEvent {
  connecting,
  connected,
  disconnected,
  error
}