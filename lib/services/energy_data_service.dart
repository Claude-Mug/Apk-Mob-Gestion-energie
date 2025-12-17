// lib/services/energy_data_service.dart
class EnergyDataService {
  // Méthode pour récupérer l'historique des consommations
  static Future<List<Map<String, dynamic>>> getHistoriqueConsommation() async {
    // Simulation de données - à remplacer par votre API réelle
    final maintenant = DateTime.now();
    final historique = <Map<String, dynamic>>[];
    
    for (int i = 30; i >= 0; i--) {
      final date = maintenant.subtract(Duration(days: i));
      final random = DateTime.now().millisecond % 20;
      final consommation = 15.0 + random.toDouble();
      
      historique.add({
        'date': date,
        'consommation': consommation,
        'cout': (consommation * 0.18).toStringAsFixed(2),
      });
    }
    
    return historique;
  }

  // Méthode pour enregistrer les données du jour
  static Future<void> enregistrerConsommationDuJour(double consommation) async {
    // Ici vous enregistrerez dans votre base de données
    print('Enregistrement consommation du jour: $consommation kWh');
    // Exemple: await votreBaseDeDonnees.insert(consommation);
  }

  // Méthode pour calculer les statistiques
  static Map<String, double> calculerStatistiques(List<Map<String, dynamic>> historique) {
    if (historique.isEmpty) return {'moyenne': 0.0, 'max': 0.0, 'min': 0.0, 'total': 0.0};
    
    double total = 0.0;
    double max = 0.0;
    double min = double.infinity;
    
    for (var jour in historique) {
      final conso = jour['consommation'];
      total += conso;
      if (conso > max) max = conso;
      if (conso < min) min = conso;
    }
    
    return {
      'moyenne': total / historique.length,
      'max': max,
      'min': min,
      'total': total,
    };
  }
}