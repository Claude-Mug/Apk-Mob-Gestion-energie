import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsDialog extends StatefulWidget {
  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _password = '';
  String _timeout = 'Immédiatement';
  
  final List<String> _timeoutOptions = [
    'Immédiatement',
    '1 minute',
    '30 minutes'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _password = prefs.getString('password') ?? '';
      _timeout = prefs.getString('timeout') ?? 'Immédiatement';
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _password);
    await prefs.setString('timeout', _timeout);
  }

  _changePassword() {
    TextEditingController passwordController = TextEditingController(text: _password);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        content: TextField(
          controller: passwordController,
          maxLength: 4,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '4 chiffres',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _password = passwordController.text;
              });
              _saveSettings();
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le mot de passe'),
        content: Text('Êtes-vous sûr de vouloir supprimer le mot de passe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _password = '';
              });
              _saveSettings();
              Navigator.pop(context); // Fermer la boîte de confirmation
              Navigator.pop(context); // Fermer la boîte de paramètres
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Paramètres de sécurité'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mot de passe
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Mot de passe'),
              subtitle: Text(_password.isEmpty ? 'Non défini' : 'Activé'),
              trailing: Icon(Icons.edit),
              onTap: _changePassword,
            ),
            Divider(),
            
            // Verrouillage automatique
            ListTile(
              leading: Icon(Icons.timer),
            
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
                    _saveSettings();
                  });
                },
              ),
            ),
            
            // Supprimer le mot de passe
            if (_password.isNotEmpty) ...[
              Divider(),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Supprimer le mot de passe',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _showDeleteConfirmation,
              ),
            ],
          ],
        ),
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