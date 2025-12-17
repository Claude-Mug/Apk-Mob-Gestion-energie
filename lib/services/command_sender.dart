import 'package:api_reine/services/connection_service.dart';

class CommandSender {
  final ConnectionService _connectionService;
  ConnectionService get connectionService => _connectionService;

  CommandSender(this._connectionService);

  Future<CommandResult> sendCommand(String command, [dynamic value]) async {
    if (!_connectionService.isConnected.value) {
      return CommandResult(success: false, message: "Non connecté à un appareil");
    }

    try {
      String fullCommand = value != null ? '$command:$value' : command;
      _connectionService.addMessage('Envoi: $fullCommand');

      if (_connectionService.isHttp) {
        var result = await _connectionService.httpService.sendCommand(
          ip: _connectionService.currentIp.value,
          port: _connectionService.currentPort.value,
          command: fullCommand,
        );

        return CommandResult(
          success: result.success,
          message: result.message,
        );
      } else {
        _connectionService.webSocketService.sendMessage(fullCommand);
        // Pour WebSocket, nous supposons que la commande a été envoyée avec succès
        // Dans une implémentation réelle, vous devriez attendre une confirmation
        return CommandResult(
          success: true,
          message: "Commande envoyée via WebSocket",
        );
      }
    } catch (e) {
      _connectionService.addMessage('Erreur lors de l\'envoi: $e');
      return CommandResult(
        success: false,
        message: "Erreur: ${e.toString()}",
      );
    }
  }
}

// Classe pour les résultats de commande
class CommandResult {
  final bool success;
  final String message;
  
  CommandResult({required this.success, required this.message});
}