import 'dart:math';
import 'dart:typed_data';

/// Moteur Audio - Génération de buffers PCM avec enveloppe ADSR
class AudioEngine {
  static const int sampleRate = 44100;

  /// Types d'ondes disponibles
  static const List<String> waveTypes = [
    'sine',
    'square',
    'sawtooth',
    'triangle'
  ];

  /// Gammes musicales disponibles
  static const Map<String, List<int>> scales = {
    'chromatic': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    'major': [0, 2, 4, 5, 7, 9, 11],
    'naturalMinor': [0, 2, 3, 5, 7, 8, 10],
    'pentatonicMajor': [0, 2, 4, 7, 9],
  };

  /// Génère un buffer PCM (Int16) pour une fréquence avec ADSR
  Int16List generateWave({
    required double frequency,
    required double durationSeconds,
    required String waveType,
    required double volume,
    double attack = 0.1,
    double decay = 0.1,
    double sustain = 0.7,
    double release = 0.2,
  }) {
    final int numSamples = (durationSeconds * sampleRate).toInt();
    final Int16List buffer = Int16List(numSamples);

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
          sample =
              (2 * (t * frequency - (t * frequency + 0.5).floor())).abs() * 2 -
                  1;
          break;
        default: // sine
          sample = sin(2 * pi * frequency * t);
      }

      // 2. Application de l'enveloppe ADSR
      double envelope = 0;
      double progress = i / numSamples;

      if (progress < attack) {
        // Attack phase
        envelope = progress / attack;
      } else if (progress < attack + decay) {
        // Decay phase
        envelope = 1.0 - ((progress - attack) / decay) * (1.0 - sustain);
      } else if (progress < 1.0 - release) {
        // Sustain phase
        envelope = sustain;
      } else {
        // Release phase
        envelope = sustain * (1.0 - (progress - (1.0 - release)) / release);
      }

      // 3. Conversion en Int16 (Format PCM)
      buffer[i] =
          (sample * envelope * volume * 32767).toInt().clamp(-32768, 32767);
    }
    return buffer;
  }

  /// Calcule la fréquence d'une note selon la gamme
  double getNoteFrequency({
    required double noteValue,
    required String scaleName,
    required double baseFrequency,
  }) {
    const double absoluteMaxFreq = 18000;
    const double absoluteMinFreq = 30;
    const int maxOctaveShift = 5;

    final scaleIntervals = scales[scaleName] ?? scales['chromatic']!;
    final numNotesInScale = scaleIntervals.length;

    if (noteValue <= 0) return absoluteMinFreq;

    final noteIndexInScale = ((noteValue - 1) % numNotesInScale).toInt();
    int octaveCycleShift = ((noteValue - 1) / numNotesInScale).floor();

    // Limiter le décalage d'octave
    if (octaveCycleShift > maxOctaveShift) {
      octaveCycleShift = maxOctaveShift;
    }

    final semitonesFromBase =
        scaleIntervals[noteIndexInScale] + (octaveCycleShift * 12);
    double frequency = baseFrequency * pow(2, semitonesFromBase / 12);

    // Clamper la fréquence
    return frequency.clamp(absoluteMinFreq, absoluteMaxFreq);
  }

  /// Calcule la fréquence directe (mode fréquence)
  double getDirectFrequency({
    required double value,
    required double baseFrequency,
    required double multiplier,
  }) {
    double frequency = baseFrequency + (value * multiplier);
    return frequency.clamp(30.0, 18000.0);
  }

  /// Génère un fichier WAV complet à partir d'une séquence de fréquences
  Uint8List generateWavFile({
    required List<double> frequencies,
    required double noteDuration,
    required double pauseDuration,
    required String waveType,
    required double volume,
  }) {
    // Calculer la durée totale
    final totalSamples = frequencies.length *
        ((noteDuration + pauseDuration) * sampleRate).toInt();

    final samples = Int16List(totalSamples);
    int offset = 0;

    for (final freq in frequencies) {
      // Générer la note
      final noteBuffer = generateWave(
        frequency: freq,
        durationSeconds: noteDuration,
        waveType: waveType,
        volume: volume,
      );
      samples.setRange(offset, offset + noteBuffer.length, noteBuffer);
      offset += noteBuffer.length;

      // Ajouter la pause (silence)
      final pauseSamples = (pauseDuration * sampleRate).toInt();
      offset += pauseSamples;
    }

    return _createWavBuffer(samples);
  }

  /// Crée un buffer WAV à partir des échantillons
  Uint8List _createWavBuffer(Int16List samples) {
    final byteData = ByteData(44 + samples.length * 2);

    // RIFF header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // fmt chunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data chunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, samples.length * 2, Endian.little);

    // Write samples
    int offset = 44;
    for (final sample in samples) {
      byteData.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  void _writeString(ByteData data, int offset, String str) {
    for (int i = 0; i < str.length; i++) {
      data.setUint8(offset + i, str.codeUnitAt(i));
    }
  }
}
