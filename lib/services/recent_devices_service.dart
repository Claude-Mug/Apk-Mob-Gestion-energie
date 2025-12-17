import 'package:shared_preferences/shared_preferences.dart';

class RecentDevicesService {
  static const String _recentDevicesKey = 'recent_devices';

  Future<void> saveDevice(String ip, int port, String protocol) async {
    final prefs = await SharedPreferences.getInstance();
    final String device = '$ip:$port:$protocol';
    List<String> devices = prefs.getStringList(_recentDevicesKey) ?? [];
    
    // Éviter les doublons
    devices.remove(device);
    devices.insert(0, device);
    
    // Garder seulement les 10 derniers
    if (devices.length > 10) {
      devices = devices.sublist(0, 10);
    }
    
    await prefs.setStringList(_recentDevicesKey, devices);
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> devices = prefs.getStringList(_recentDevicesKey) ?? [];
    
    return devices.map((device) {
      final parts = device.split(':');
      return {
        'ip': parts[0],
        'port': int.tryParse(parts[1]) ?? 0,
        'protocol': parts[2],
      };
    }).toList();
  }
}