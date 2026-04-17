import 'package:flutter/material.dart';
import 'package:welcomrea/Views/PatientView.dart';
import 'package:welcomrea/Views/SoignantView.dart';


/*import 'package:well_com_rea/views/enter_bed_number_page.dart';*/

class AccueilView extends StatelessWidget {
  const AccueilView({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const double tablet = 500;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('Page d\'Accueil'),
        ),
        backgroundColor: Colors.green.shade900,
      ),
      body: Center(
        child: SizedBox(
          width: size.width * 0.9,
          child: LayoutBuilder(builder: (context, cons) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              direction:
                  (size.width <= tablet) ? Axis.vertical : Axis.horizontal,
              children: <Widget>[
                SizedBox(
                  width: (size.width <= tablet) ? cons.maxWidth : 250,
                  height: 250,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientView()),
                      );
                    },
                    icon: const Icon(
                      Icons.person,
                      size: 40, // Ajustez la taille de l'icône ici
                    ), // Ajout de l'icône
                    label: const FittedBox(
                      child: Text(
                        'Espace Patient',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20), // Espace entre les boutons

                SizedBox(
                  width: (size.width <= tablet) ? cons.maxWidth : 250,
                  height: 250,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SoignantView()),
                      );
                    },
                    icon: const Icon(
                      Icons.medical_services,
                      size: 40,
                    ), // Ajout de l'icône
                    label: const FittedBox(
                      child: Text(
                        'Espace Soignant',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
