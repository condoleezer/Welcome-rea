/// Configuration du serveur eye-tracking.
/// Modifie [serverIp] selon ton réseau actuel.
class AppConfig {
  /// Adresse IP de la machine qui fait tourner main.py
  static const String serverIp = '10.77.248.6';

  static const int serverPort = 5000;

  static String get serverUrl => 'http://$serverIp:$serverPort';
}
