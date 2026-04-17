import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordWidget extends StatefulWidget {
  const RecordWidget({super.key});

  @override
  State<RecordWidget> createState() => _RecordWidgetState();
}

class _RecordWidgetState extends State<RecordWidget> {
  //late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  String _translateText = '';
  bool speechEnabled = false;
  final translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  //List<stt.LocaleName> _localeNames = [];
  //final speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    //_speech = stt.SpeechToText();
    //print('initialized');
    //_initSpeech();
  }

  /*
  void _initSpeech() async {
    bool speechEnabled = await speech.initialize(onStatus: (status) => print('status $status'), onError: (errorNotification) => print('error $errorNotification'),);
    setState(() {});
  }

   */

  Future<void> _requestPermission() async {
    await Permission.microphone.request();
  }

  void _startListening() async {
    _isListening = true;
    _text = '';
    //await _requestPermission();
    //_localeNames = await _speech.locales();
    //print(_localeNames);
    setState(() {});
    try {
      bool speechEnabled = await _speech.initialize(
        onStatus: (status) => print('status $status'),
        onError: (errorNotification) => print('error $errorNotification'),
        //finalTimeout: Duration(seconds: 5),
        //options: [stt.SpeechToText.androidAlwaysUseStop]
      );
      if (speechEnabled) {
        print('speech enabled : $speechEnabled');
        print('Listening');
        _speech.listen(
          listenFor: const Duration(seconds: 15),
            onSoundLevelChange: (level) => print('Sound level: $level'),
            onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
          });
          print('You are saying ${result.recognizedWords}');
        });
      } else {
        print('speech enabled : $speechEnabled');
      }
    } catch (e) {
      print('error listening $e');
    }
  }

  void _stopListening() async {
    _isListening = false;
    await _speech.stop();
    setState(() {});
    print('You said $_text');
    try {
      // Traduire le texte en français
      final translation = await translator.translate(_text, to: 'fr');
      setState(() {
        _translateText = translation.text;
      });
    } catch (e) {
      print('erreur traduction $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      //appBar: AppBar(title: const Text('Reconnaissance Vocale')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text.isEmpty ? 'Dites quelque chose...' : _translateText,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Arrêter' : 'Parler'),
            ),
          ],
        ),
      ),
    );
  }
}
