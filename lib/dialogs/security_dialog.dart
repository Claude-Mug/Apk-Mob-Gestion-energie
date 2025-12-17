import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityDialog extends StatefulWidget {
  @override
  _SecurityDialogState createState() => _SecurityDialogState();
}

class _SecurityDialogState extends State<SecurityDialog> {
  String _password = '';
  String _timeout = 'Immédiatement';
  final List<String> _timeoutOptions = [
    'Immédiatement',
    '1 minute',
    '30 minutes'
  ];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  _loadSecuritySettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _password = prefs.getString('password') ?? '';
      _timeout = prefs.getString('timeout') ?? 'Immédiatement';
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  _saveSecuritySettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _password);
    await prefs.setString('timeout', _timeout);
  }

  _saveDarkModeSetting(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  _changePassword() {
    String newPassword = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        content: TextField(
          maxLength: 4,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            newPassword = value;
          },
          decoration: InputDecoration(
            hintText: '4 chiffres',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _password = newPassword;
              });
              _saveSecuritySettings();
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sécurité'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Mot de passe'),
            subtitle: Text(_password.isEmpty ? 'Non défini' : '••••'),
            trailing: Icon(Icons.edit),
            onTap: _changePassword,
          ),
          Divider(),
          ListTile(
            title: Text('Verrouillage automatique'),
            trailing: DropdownButton<String>(
              value: _timeout,
              items: _timeoutOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _timeout = newValue!;
                  _saveSecuritySettings();
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Effacer le mot de passe', style: TextStyle(color: Colors.red)),
            onTap: () {
              setState(() {
                _password = '';
                _saveSecuritySettings();
              });
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text('Mode sombre'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
                _saveDarkModeSetting(value);
                // Vous devrez recharger le thème via un gestionnaire d'état comme Provider
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer'),
        ),
      ],
    );
  }
}