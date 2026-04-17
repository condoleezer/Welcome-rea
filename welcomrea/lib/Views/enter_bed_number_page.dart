/*import 'package:flutter/material.dart';
import 'package:well_com_rea/Controllers/patient_controller.dart';
import 'package:well_com_rea/Models/patient_model.dart';
import 'package:well_com_rea/Views/PatientView.dart';
import 'package:well_com_rea/Views/FeedView.dart';



class EnterBedNumberPage extends StatefulWidget {
  @override
  _EnterBedNumberPageState createState() => _EnterBedNumberPageState();
}

class _EnterBedNumberPageState extends State<EnterBedNumberPage> {
  final _controller = TextEditingController();
  late Future<Map<String, dynamic>> _patientFuture;

  @override
  void initState() {
    super.initState();
    _patientFuture = Future<Map<String, dynamic>>.value({});
  }*/

/* @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const  Center(
        child : Text('Enter Bed Number'),),
        backgroundColor: Colors.green.shade900, // définir la couleur de la barre en vert.
      ),

      backgroundColor: Colors.green.shade200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text field to enter bed number
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Bed Number'),
            ),

            // Button to submit bed number and redirect to NeedsPage
            ElevatedButton(
              onPressed: () async {
                // Vérifier si le champ du numéro de lit est vide
                if (_controller.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez entrer un numéro de lit.'),
                    ),
                  );
                  return;
                }
                Map<String, dynamic> patient = {};  // Initialisez avec une valeur par défaut

                try {
                  patient = await PatientController.createPatient(_controller.text);

                  // Assuming the backend returns a success property indicating the operation was successful
                  if (patient['success'] == true) {
                    // Navigate to NeedsPage with patient data
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PatientView(bedNumber: _controller.text)),
                    );
                  } else {
                    // Handle other cases (e.g., unexpected response structure)
                    print('Unexpected response structure: $patient');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create patient. Unexpected response structure.'),
                      ),
                    );
                  }
                } catch (error) {
                  // Gérer les autres erreurs
                  print('Erreur lors de la création du patient : $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Échec de la création du patient. Veuillez réessayer.'),
                    ),
                  );
                  print('Réponse du serveur avant la vérification : $patient');
                  if (patient.isNotEmpty && patient.containsKey('patient')) {
                    print('Données du patient : ${patient['patient']}');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PatientView(bedNumber: _controller.text)),
                    );
                  } else {
                    print('La réponse du serveur ne contient pas de patient valide.');
                    // Ajoutez une logique supplémentaire si nécessaire
                  }

                  print('Response from server: $patient');

                }


              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
