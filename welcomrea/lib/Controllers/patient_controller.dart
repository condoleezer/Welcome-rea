import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:welcomrea/Models/patient_model.dart';

class PatientController {
  static Future<Map<String, dynamic>> createPatient(String bedNumber) async {
    final url = Uri.parse('http://10.77.2.226:3000/api/patients');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bedNumber': bedNumber}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Failed to create patient. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to create patient. Status code: ${response.statusCode}');
    }
  }

  static Future<Patient?> getPatientByBedNumber(String bedNumber) async {
    try {
      final url = Uri.parse(
          'http://10.77.2.226:3000/api/patients/bedNumber/$bedNumber');
      print('Getting patient with bed number: $bedNumber');
      print('URL: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Patient patient = Patient.fromJson(responseData['patient']);
        return patient;
      } else if (response.statusCode == 404) {
        // Le patient n'a pas été trouvé avec le numéro de lit donné
        return null;
      } else {
        throw Exception(
            'Failed to get patient by bed number. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error getting patient by bed number: $error');
      throw Exception('Failed to get patient by bed number. Error: $error');
    }
  }

  static Future<void> addNeedsToPatient(
      String bedNumber, List<String> needs) async {
    try {
      // Récupérer le patient en fonction du numéro de lit
      final patient = await getPatientByBedNumber(bedNumber);

      // Vérifier si le patient existe
      if (patient != null) {
        final url =
            Uri.parse('http://10.77.2.226:3000/api/patients/$bedNumber/needs');
        print('URL: $url');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'need': needs}),
        );

        if (response.statusCode != 200) {
          print(
              'Échec de la mise à jour des besoins du patient. Code d\'état : ${response.statusCode}');
          print('Corps de la réponse : ${response.body}');
          throw Exception(
              'Échec de la mise à jour des besoins du patient. Code d\'état : ${response.statusCode}');
        }
      } else {
        throw Exception('Patient not found with bed number: $bedNumber');
      }
    } catch (error) {
      print('Error updating needs for patient: $error');
    }
  }
}
