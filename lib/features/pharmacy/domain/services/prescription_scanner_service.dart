import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PrescriptionScannerService {
  // Solo inicializamos el recognizer si NO estamos en web
  final TextRecognizer? _textRecognizer = kIsWeb
      ? null
      : TextRecognizer(script: TextRecognitionScript.latin);

  /// Toma una imagen, extrae el texto y devuelve una lista de posibles nombres de medicamentos limpios.
  Future<List<String>> processPrescription(File imageFile) async {
    // Manejo especial para Web (donde ML Kit no funciona nativamente)
    if (kIsWeb) {
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulación de procesamiento
      return ['Amoxicilina', 'Ibuprofeno']; // Datos demo para pruebas en Chrome
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText? recognizedText = await _textRecognizer
          ?.processImage(inputImage);

      if (recognizedText == null || recognizedText.text.trim().isEmpty) {
        throw Exception(
          'No se detectó texto en la imagen. Por favor, asegúrese de que la foto sea clara.',
        );
      }

      return _extractMedicationNames(recognizedText.text);
    } catch (e) {
      throw Exception('Error al procesar la receta: ${e.toString()}');
    }
  }

  /// Lógica de limpieza mediante RegEx para extraer nombres de medicamentos.
  List<String> _extractMedicationNames(String rawText) {
    final lines = rawText.split('\n');
    final List<String> medicationNames = [];
    final dosePattern = RegExp(
      r'\d+\s*(mg|g|ml|mcg|UI|capsulas|tabletas|pastillas|comp)',
      caseSensitive: false,
    );
    final noiseWords = [
      'cada',
      'horas',
      'dias',
      'tomar',
      'durante',
      'vía',
      'oral',
      'receta',
      'médico',
    ];

    for (var line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.isEmpty || cleanLine.length < 3) continue;
      cleanLine = cleanLine.split(dosePattern).first.trim();
      for (var word in noiseWords) {
        cleanLine = cleanLine
            .replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '')
            .trim();
      }
      if (cleanLine.length > 3 && !medicationNames.contains(cleanLine)) {
        final words = cleanLine.split(' ');
        if (words.isNotEmpty) {
          final simpleName = words.take(2).join(' ');
          medicationNames.add(simpleName);
        }
      }
    }
    return medicationNames;
  }

  /// Liberar recursos
  void dispose() {
    _textRecognizer?.close();
  }
}
