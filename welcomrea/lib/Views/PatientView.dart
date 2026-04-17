import 'package:flutter/material.dart';
import 'package:welcomrea/Views/DiscomfortView.dart';
import 'package:welcomrea/Views/FeedView.dart';
import 'package:welcomrea/Views/HealthView.dart';
import 'package:welcomrea/Views/CareView.dart';
import 'package:welcomrea/Views/RemovalView.dart';
import 'package:welcomrea/Views/PainView.dart';
import 'package:welcomrea/Views/InstalView.dart';

class PatientView extends StatelessWidget {
  const PatientView({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const tablet = 500;
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Center(
            child: Text('Espace Patient', style: TextStyle(fontSize: 30)),
          ),
          backgroundColor: Colors.green.shade900,
        ),
        body: Center(
            child: SizedBox(
          width: size.width * 0.9,
          child: LayoutBuilder(builder: (context, cons) {
            List<Map<String, dynamic>> menuItems = [
              {
                'title': 'Douleur',
                'icon': const Icon(Icons.sick),
                'destination': const PainView(),
              },
              {
                'title': 'Ressenti',
                'icon': const Icon(Icons.sentiment_satisfied),
                'destination': const DiscomfortView(),
              },
              {
                'title': 'Hygiène',
                'icon': const Icon(Icons.cleaning_services),
                'destination': const HealthView(),
              },
              {
                'title': 'Installation\nMobilisation',
                'icon': const Icon(Icons.maps_ugc),
                'destination': const InstalView(),
              },
              {
                'title': 'Alimentation',
                'icon': const Icon(Icons.food_bank),
                'destination': const FeedView(),
              },
              {
                'title': 'Elimination',
                'icon': const Icon(Icons.medical_information),
                'destination': const RemovalView(),
              },
              {
                'title': 'Bien-être',
                'icon': const Icon(Icons.medical_services),
                'destination': const CareView(),
              },
            ];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                  itemCount: menuItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 6 / 4,
                    crossAxisCount: (size.width >= 824)
                        ? 3
                        : (size.width <= tablet)
                            ? 1
                            : 2,
                  ),
                  itemBuilder: (context, index) {
                    return _Menu(
                      title: menuItems[index]['title'],
                      icon: menuItems[index]['icon'],
                      destination: menuItems[index]['destination'],
                    );
                  }),
            );
          }),
        )));
  }
}

class _Menu extends StatelessWidget {
  final String title;
  final Icon icon;
  final Widget destination;
  const _Menu({
    required this.title,
    required this.icon,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        margin: const EdgeInsets.all(8),
        child: ElevatedButton.icon(
          onPressed: () {
            // Action lorsque le bouton "Douleur" est pressé
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          icon: Icon(icon.icon, size: 40), // Ajout de l'icône
          label: Text(
            title,
            style: const TextStyle(fontSize: 30),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            //   minimumSize: Size(, 200),
          ),
        )

        // Wrap(
        //   spacing: 5,
        //   direction: Axis.horizontal,
        //   children: <Widget>[
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Douleur" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => PainView()),
        //         );
        //       },
        //       icon: Icon(Icons.sick), // Ajout de l'icône
        //       label: Text(
        //         'Douleur',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade300,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Ressenti Patient" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => DiscomfortView()),
        //         );
        //       },
        //       icon: Icon(Icons.sentiment_satisfied), // Ajout de l'icône
        //       label: Text(
        //         'Ressenti',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade700,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Bien-être" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => CareView()),
        //         );
        //       },
        //       icon: Icon(Icons.medical_services), // Ajout de l'icône
        //       label: Text(
        //         'Bien-être',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade400,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Hygiène" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => HealthView()),
        //         );
        //       },
        //       icon: Icon(Icons.cleaning_services), // Ajout de l'icône
        //       label: Text(
        //         'Hygiène',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade800,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Installation" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => InstalView()),
        //         );
        //       },
        //       icon: Icon(Icons.maps_ugc), // Ajout de l'icône
        //       label: Text(
        //         'Installation\nMobilisation',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade300,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => FeedView()),
        //         );
        //       },
        //       icon: Icon(Icons.food_bank), // Ajout de l'icône
        //       label: Text(
        //         'Alimentation',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade900,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //     ElevatedButton.icon(
        //       onPressed: () {
        //         // Action lorsque le bouton "Elimination" est pressé
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (context) => RemovalView()),
        //         );
        //       },
        //       icon: Icon(Icons.wc), // Ajout de l'icône
        //       label: Text(
        //         'Elimination',
        //         style: TextStyle(fontSize: 25),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         foregroundColor: Colors.white,
        //         backgroundColor: Colors.green.shade600,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         minimumSize: Size(cons.maxWidth * 0.45, 200),
        //       ),
        //     ),
        //   ],
        // ),
        );
  }
}
