// lib/models/devices.dart
import 'package:flutter/material.dart';

class Device2 {
  String id;
  String name;
  bool isActive;
  IconData icon;
  Color color;
  String commandOn;
  String commandOff;
  double courant;

  Device2({
    required this.id,
    required this.name,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.commandOn,
    required this.commandOff,
    required this.courant,
  });

  // Conversion en JSON pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'icon': icon.codePoint,
      'color': color.value,
      'commandOn': commandOn,
      'commandOff': commandOff,
      'courant': courant,
    };
  }

  // Création depuis JSON
  factory Device2.fromJson(Map<String, dynamic> json) {
    return Device2(
      id: json['id'],
      name: json['name'],
      isActive: json['isActive'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      commandOn: json['commandOn'],
      commandOff: json['commandOff'],
      courant: json['courant'],
    );
  }
}