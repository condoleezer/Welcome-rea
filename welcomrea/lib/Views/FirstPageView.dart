import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:welcomrea/models/HospitalData.dart';
import 'package:welcomrea/views/AccueilView.dart';

class FirstPageView extends StatelessWidget {
  final HospitalData data;

  const FirstPageView({super.key, required this.data});

  // Fonction pour formater la date
  String formatDate(DateTime date) {
    // Liste des jours de la semaine en français
    const List<String> joursSemaine = [
      'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'
    ];

    // Liste des mois de l'année en français
    const List<String> moisAnnee = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    String jourSemaine = joursSemaine[date.weekday % 7];
    String mois = moisAnnee[date.month - 1];
    String formattedDate = '$jourSemaine le ${date.day} $mois ${date.year}';

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const tablet = 500;
    DateTime now = DateTime.now().toLocal();

    return Scaffold(
      appBar: AppBar(
        toolbarTextStyle: const TextStyle(
          color: Colors.white,
        ),
        foregroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Bienvenue au CHSF',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.green.shade900,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccueilView()),
              );
            },
          ),
          // Ajouter le bouton avec la liste déroulante
          _buildLanguageDropdownButton(),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: size.width,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Heure : ${DateFormat('HH:mm').format(now)}',
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      6<=int.parse(DateFormat('HH').format(now)) && int.parse(DateFormat('HH').format(now)) <16 ? Icons.sunny : Icons.shield_moon,
                      color: 6<=int.parse(DateFormat('HH').format(now)) && int.parse(DateFormat('HH').format(now)) <16 ? Colors.yellow : Colors.blueAccent,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  data.welcomeMessage,
                  style: TextStyle(
                      fontSize: (size.width <= tablet) ? size.width * 0.06 : 30,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Image.asset(
                data.imagePath,
                height: 200,
                width: 400,
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 10),
                height: size.height * 0.002,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Text(
                      'Date : ${formatDate(now)}',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w400),
                    ),
                  ),
                  /*
                  FittedBox(
                    child: Text(
                      'Pays : ${data.country}',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w400),
                    ),
                  ),*/
                ],
              ),
              SizedBox(height: size.height * 0.08),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    height: 40,
                    width: size.width * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccueilView(),
                          ),
                        );
                      },
                      child: const Text(
                        'Accueil',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour construire le bouton avec la liste déroulante
  Widget _buildLanguageDropdownButton() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        // Logique pour changer la langue en fonction de la sélection
        // Exemple : context.setLocale(Locale(value));
      },
      itemBuilder: (BuildContext context) {
        // Liste des langues disponibles
        return ['fr', 'en', 'es'].map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(_getLanguageName(choice)),
          );
        }).toList();
      },
    );
  }

  // Fonction pour obtenir le nom de la langue
  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français 🇫🇷';
      case 'en':
        return 'English 🇬🇧';
      case 'es':
        return 'Español 🇪🇸';
      default:
        return '';
    }
  }
}
