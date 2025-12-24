// Abjad Engine - Calcul des valeurs numériques traditionnelles arabes
//
// Supporte deux méthodes:
// - Abjad: Valeurs traditionnelles (أ=1, ب=2, ي=10, ش=1000)
// - Séquentiel: Ordre alphabétique (أ=1, ب=2, ..., ي=28)

enum ArabicMethod { abjad, sequential }

/// Token représentant un caractère avec sa valeur numérique
class SoundToken {
  final double value;
  final String originalChar;
  final bool isAccented;

  SoundToken({
    required this.value,
    required this.originalChar,
    this.isAccented = false,
  });

  @override
  String toString() => 'Token($originalChar: $value, accent: $isAccented)';
}

class AbjadEngine {
  /// Mapping Abjad traditionnel (valeurs 1-1000)
  static const Map<String, double> abjadMap = {
    'أ': 1, 'ا': 1, 'إ': 1, 'آ': 1,
    'ب': 2, 'ج': 3, 'د': 4, 'ه': 5, 'و': 6, 'ز': 7, 'ح': 8, 'ط': 9,
    'ي': 10, 'ك': 20, 'ل': 30, 'م': 40, 'ن': 50, 'ص': 60, 'ع': 70,
    'ف': 80, 'ض': 90, 'ق': 100, 'ر': 200, 'س': 300, 'ت': 400,
    'ث': 500, 'خ': 600, 'ذ': 700, 'ظ': 800, 'غ': 900, 'ش': 1000,
    'ة': 400, // Taa Marbuta = T
  };

  /// Mapping Séquentiel (1-28)
  static final Map<String, double> sequentialMap = _buildSequentialMap();

  static Map<String, double> _buildSequentialMap() {
    const letters = "ابتثجحخدذرزسشصضطظعغفقكلمنهوي";
    Map<String, double> map = {};
    for (int i = 0; i < letters.length; i++) {
      map[letters[i]] = (i + 1).toDouble();
    }
    // Variantes d'Alif et Taa Marbuta
    map['أ'] = 1;
    map['إ'] = 1;
    map['آ'] = 1;
    map['ة'] = map['ت'] ?? 4;
    return map;
  }

  /// Parse l'entrée utilisateur et retourne une liste de tokens
  List<SoundToken> parseInput(String input, ArabicMethod method) {
    List<SoundToken> tokens = [];
    final currentArabicMap =
        (method == ArabicMethod.abjad) ? abjadMap : sequentialMap;

    final normalized = input.trim();
    if (normalized.isEmpty) return tokens;

    // Vérifier si c'est uniquement des nombres
    final numericRegExp = RegExp(r'^[0-9\s,.-]+$');
    if (numericRegExp.hasMatch(normalized) &&
        normalized.contains(RegExp(r'[0-9]'))) {
      final parts = normalized.split(RegExp(r'[\s,]+'));
      for (var part in parts) {
        final val = double.tryParse(part);
        if (val != null) {
          tokens.add(SoundToken(value: val, originalChar: part));
        }
      }
    } else {
      // Analyse caractère par caractère
      for (int i = 0; i < normalized.length; i++) {
        String char = normalized[i];

        // Lettres Latines Majuscules (accentuées)
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          tokens.add(SoundToken(
            value: (char.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1).toDouble(),
            originalChar: char,
            isAccented: true,
          ));
        }
        // Lettres Latines Minuscules
        else if (RegExp(r'[a-z]').hasMatch(char)) {
          tokens.add(SoundToken(
            value: (char.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1).toDouble(),
            originalChar: char,
            isAccented: false,
          ));
        }
        // Lettres Arabes
        else if (currentArabicMap.containsKey(char)) {
          tokens.add(SoundToken(
            value: currentArabicMap[char]!,
            originalChar: char,
          ));
        }
      }
    }
    return tokens;
  }

  /// Calcule la valeur Abjad totale d'un texte arabe
  double calculateTotalAbjad(String input) {
    double total = 0;
    for (int i = 0; i < input.length; i++) {
      total += abjadMap[input[i]] ?? 0;
    }
    return total;
  }

  /// Retourne le détail de chaque lettre avec sa valeur
  List<Map<String, dynamic>> getLetterBreakdown(String input) {
    List<Map<String, dynamic>> breakdown = [];
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final value = abjadMap[char];
      if (value != null) {
        breakdown.add({
          'letter': char,
          'value': value.toInt(),
        });
      }
    }
    return breakdown;
  }
}
