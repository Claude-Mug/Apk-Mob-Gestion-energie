// lib/models/device.dart
import 'package:flutter/material.dart';

class Device {
  String id;
  String name;
  bool isActive;
  IconData icon;
  Color color;
  String commandOn;
  String commandOff;
  double powerConsumption;
  double courant; // Nouveau champ pour le courant en ampères

  Device({
    required this.id,
    required this.name,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.commandOn,
    required this.commandOff,
    this.powerConsumption = 0.0,
    required this.courant, // Champ obligatoire maintenant
  });

  // Méthode pour créer un Device à partir d'un JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      icon: _getIconData(json['icon'] ?? 'lightbulb'),
      color: _getColorFromString(json['color'] ?? 'blue'),
      commandOn: json['commandOn'] ?? '',
      commandOff: json['commandOff'] ?? '',
      powerConsumption: (json['powerConsumption'] ?? 0.0).toDouble(),
      courant: (json['courant'] ?? 0.1).toDouble(), // Valeur par défaut 0.1A
    );
  }

  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'icon': _getIconString(icon),
      'color': _getColorString(color),
      'commandOn': commandOn,
      'commandOff': commandOff,
      'powerConsumption': powerConsumption,
      'courant': courant,
    };
  }

  // Méthode pour cloner un Device
  Device copyWith({
    String? id,
    String? name,
    bool? isActive,
    IconData? icon,
    Color? color,
    String? commandOn,
    String? commandOff,
    double? powerConsumption,
    double? courant,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      commandOn: commandOn ?? this.commandOn,
      commandOff: commandOff ?? this.commandOff,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      courant: courant ?? this.courant,
    );
  }

  // Calculer la puissance en watts
  double get puissanceWatts {
    return courant * 220;
  }

  // Calculer la consommation énergétique pour une durée en heures
  double calculerConsommation(double heures) {
    return puissanceWatts * heures / 1000; // Retourne en kWh
  }

  @override
  String toString() {
    return 'Device{id: $id, name: $name, isActive: $isActive, courant: ${courant}A, puissance: ${puissanceWatts}W}';
  }

  // Helper methods pour la conversion des icônes et couleurs
  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'lightbulb':
        return Icons.lightbulb;
      case 'security':
        return Icons.security;
      case 'tv':
        return Icons.tv;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'computer':
        return Icons.computer;
      case 'washing_machine':
        return Icons.local_laundry_service;
      case 'router':
        return Icons.router;
      case 'camera':
        return Icons.camera_alt;
      case 'sensor':
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  static String _getIconString(IconData icon) {
    if (icon == Icons.lightbulb) return 'lightbulb';
    if (icon == Icons.security) return 'security';
    if (icon == Icons.tv) return 'tv';
    if (icon == Icons.ac_unit) return 'ac_unit';
    if (icon == Icons.kitchen) return 'kitchen';
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.local_laundry_service) return 'washing_machine';
    if (icon == Icons.router) return 'router';
    if (icon == Icons.camera_alt) return 'camera';
    if (icon == Icons.sensors) return 'sensor';
    return 'device_unknown';
  }

  static Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'amber':
        return Colors.amber;
      case 'cyan':
        return Colors.cyan;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  static String _getColorString(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.amber) return 'amber';
    if (color == Colors.cyan) return 'cyan';
    if (color == Colors.indigo) return 'indigo';
    return 'blue';
  }
}