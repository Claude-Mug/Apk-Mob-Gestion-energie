import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
// L'erreur se trouve ici. Assurez-vous que le package 'provider' est installé.
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'page/home_page.dart';
import 'providers/theme_provider.dart';
import 'screens/password_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisation du formatage de date pour le français
  await initializeDateFormatting('fr_FR', null); 

  // Définition des orientations d'écran préférées (Portrait seulement)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de l'apparence de la barre de statut et de navigation système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Barre de statut transparente
      statusBarIconBrightness: Brightness.dark, // Icônes sombres
      systemNavigationBarColor: Colors.white, // Barre de navigation blanche
      systemNavigationBarIconBrightness: Brightness.dark, // Icônes sombres
    ),
  );

  runApp(
    // Fournit le ThemeProvider à l'ensemble de l'application
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère l'instance de ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Mon Application',
      debugShowCheckedModeBanner: false,
      // Bascule entre le thème sombre et clair en fonction du provider
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      
      // Détermine l'écran d'accueil à afficher (Verrouillage ou Accueil)
      home: FutureBuilder<bool>(
        future: _hasPassword(),
        builder: (context, snapshot) {
          // Affichage d'un indicateur de chargement pendant la vérification
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } 
          // Si un mot de passe existe, affiche l'écran de verrouillage
          else if (snapshot.hasData && snapshot.data == true) {
            // L'écran de verrouillage enveloppe la HomePage
            return PasswordLockScreen(child: const HomePage()); 
          } 
          // Sinon, affiche directement la page d'accueil
          else {
            return const HomePage();
          }
        },
      ),
    );
  }

  // Fonction statique pour vérifier l'existence d'un mot de passe dans SharedPreferences
  static Future<bool> _hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString('password');
    return password != null && password.isNotEmpty;
  }
}