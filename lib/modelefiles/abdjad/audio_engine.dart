import 'dart:math';
import 'dart:typed_data';

class AudioEngine {
  final int sampleRate = 44100;
  
  /// Génère un buffer PCM pour une fréquence donnée avec ADSR
  Int16List generateWave({
    required double frequency,
    required double durationSeconds,
    required String waveType,
    required double volume,
  }) {
    final int numSamples = (durationSeconds * sampleRate).toInt();
    final Int16List buffer = Int16List(numSamples);

    // Paramètres ADSR (en pourcentage de la durée totale)
    double attack = 0.1;
    double decay = 0.1;
    double sustain = 0.7; // Niveau de volume
    double release = 0.2;

    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double sample = 0;

      // 1. Génération de l'onde de base
      switch (waveType) {
        case 'square':
          sample = sin(2 * pi * frequency * t) >= 0 ? 1.0 : -1.0;
          break;
        case 'sawtooth':
          sample = 2 * (t * frequency - (t * frequency + 0.5).floor());
          break;
        case 'triangle':
          sample = (2 * (t * frequency - (t * frequency + 0.5).floor())).abs() * 2 - 1;
          break;
        default: // sine
          sample = sin(2 * pi * frequency * t);
      }

      // 2. Application de l'enveloppe ADSR
      double envelope = 0;
      double progress = i / numSamples;

      if (progress < attack) {
        envelope = progress / attack;
      } else if (progress < attack + decay) {
        envelope = 1.0 - ((progress - attack) / decay) * (1.0 - sustain);
      } else if (progress < 1.0 - release) {
        envelope = sustain;
      } else {
        envelope = sustain * (1.0 - (progress - (1.0 - release)) / release);
      }

      // 3. Conversion en Int16 (Format PCM standard)
      // Max Int16 = 32767
      buffer[i] = (sample * envelope * volume * 32767).toInt();
    }
    return buffer;
  }

  /// Calcule la fréquence d'une note selon une gamme
  double getFrequency(double value, double baseFreq) {
    // Loi de la physique acoustique : f = f0 * 2^(n/12)
    // On plafonne pour éviter les fréquences inaudibles
    if (value > 1000) value = 1000; 
    return baseFreq * pow(2, (value - 1) / 12);
  }
}
