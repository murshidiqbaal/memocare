class MedicineNameParser {
  /// Extracts medicine name, dosage, and form from raw OCR text.
  static Map<String, String> parse(String text) {
    final lines = text.split('\n');
    String name = '';
    String dosage = '';

    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      // Rule 1: Look for dosage (e.g., 500mg, 10ml)
      final dosageRegex = RegExp(r'\d+\s*(mg|ml|g|mcg|TABLET|CAPSULE)', caseSensitive: false);
      if (dosageRegex.hasMatch(cleanLine) && dosage.isEmpty) {
        dosage = dosageRegex.stringMatch(cleanLine) ?? '';
        
        // If the name is still empty, the part before the dosage might be the name
        if (name.isEmpty) {
          name = cleanLine.split(dosageRegex).first.trim();
        }
      }

      // Rule 2: If we found something that looks like a name but name is empty
      if (name.isEmpty && !cleanLine.contains(RegExp(r'\d'))) {
         // Avoid pure generic keywords
         if (!['tablet', 'capsule', 'medicine', 'bottle'].contains(cleanLine.toLowerCase())) {
           name = cleanLine;
         }
      }
      
      if (name.isNotEmpty && dosage.isNotEmpty) break;
    }

    return {
      'name': name.isEmpty ? 'Unknown Medicine' : name,
      'dosage': dosage.isEmpty ? 'Not detected' : dosage,
    };
  }
}
