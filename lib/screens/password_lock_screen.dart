import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordLockScreen extends StatefulWidget {
  final Widget child;

  const PasswordLockScreen({required this.child, super.key});

  @override
  _PasswordLockScreenState createState() => _PasswordLockScreenState();
}

class _PasswordLockScreenState extends State<PasswordLockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _savedPassword;
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  _loadPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPassword = prefs.getString('password');
      if (_savedPassword == null || _savedPassword!.isEmpty) {
        _isLocked = false;
      }
    });
  }

  _checkPassword() {
    if (_controller.text == _savedPassword) {
      setState(() {
        _isLocked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mot de passe incorrect',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background with an image or a solid color
          Container(
            color: const Color.fromARGB(255, 83, 150, 182), // A soft sky blue color
          ),
          // Centered text "Smart Home Control"
          const Center(
            child: Text(
              'Smart Home Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat', // A clean, modern font
              ),
            ),
          ),
          // The password input UI, positioned below the centered text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Veuillez entrer votre mot de passe',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: '4 chiffres',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      counterText: "", // Hide the character counter
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // White button background
                      foregroundColor: Colors.lightBlueAccent, // Sky blue text color
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Déverrouiller',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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