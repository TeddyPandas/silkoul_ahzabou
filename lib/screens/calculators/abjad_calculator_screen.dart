import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/abjad_engine.dart';
import '../../core/audio_engine.dart';
import '../../widgets/calculators/particle_visualizer.dart';
import '../../widgets/calculators/control_panel.dart';
import '../../utils/app_theme.dart';

class AbjadCalculatorScreen extends StatefulWidget {
  const AbjadCalculatorScreen({super.key});

  @override
  State<AbjadCalculatorScreen> createState() => _AbjadCalculatorScreenState();
}

class _AbjadCalculatorScreenState extends State<AbjadCalculatorScreen> {
  final AbjadEngine _abjadEngine = AbjadEngine();
  final AudioEngine _audioEngine = AudioEngine();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // État du calculateur
  double _abjadValue = 0;
  List<Map<String, dynamic>> _letterBreakdown = [];
  bool _isPlaying = false;
  bool _isGenerating = false;
  double _audioIntensity = 0.0;
  int _currentTokenIndex = -1;
  List<SoundToken> _tokens = [];

  // Paramètres
  String _selectedMethod = 'abjad';
  String _selectedMode = 'notes';
  double _noteDuration = 0.4;
  double _pauseDuration = 50;
  double _volume = 0.8;
  String _selectedScale = 'major';
  String _selectedWaveType = 'sine';

  Timer? _playbackTimer;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _audioPlayer.dispose();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _calculateAbjad() {
    final text = _inputController.text;
    if (text.isEmpty) {
      setState(() {
        _abjadValue = 0;
        _letterBreakdown = [];
        _tokens = [];
      });
      return;
    }

    final method = _selectedMethod == 'abjad'
        ? ArabicMethod.abjad
        : ArabicMethod.sequential;

    setState(() {
      _abjadValue = _abjadEngine.calculateTotalAbjad(text);
      _letterBreakdown = _abjadEngine.getLetterBreakdown(text);
      _tokens = _abjadEngine.parseInput(text, method);
    });
  }

  Future<void> _playSequence() async {
    if (_tokens.isEmpty || _isPlaying) return;

    setState(() {
      _isPlaying = true;
      _currentTokenIndex = 0;
    });

    try {
      for (int i = 0; i < _tokens.length; i++) {
        if (!_isPlaying) break;

        setState(() {
          _currentTokenIndex = i;
          _audioIntensity = 1.0;
        });

        final token = _tokens[i];
        final frequency = _selectedMode == 'notes'
            ? _audioEngine.getNoteFrequency(
                noteValue: token.value,
                scaleName: _selectedScale,
                baseFrequency: 261.63, // C4
              )
            : _audioEngine.getDirectFrequency(
                value: token.value,
                baseFrequency: 100,
                multiplier: 20,
              );

        // Générer et jouer le son
        final buffer = _audioEngine.generateWave(
          frequency: frequency,
          durationSeconds: _noteDuration,
          waveType: _selectedWaveType,
          volume: _volume,
        );

        await _playBuffer(buffer);

        // Réduire l'intensité après le son
        setState(() => _audioIntensity = 0.3);

        // Pause entre les notes
        await Future.delayed(Duration(milliseconds: _pauseDuration.toInt()));
      }
    } finally {
      setState(() {
        _isPlaying = false;
        _currentTokenIndex = -1;
        _audioIntensity = 0.0;
      });
    }
  }

  Future<void> _playBuffer(Int16List buffer) async {
    try {
      // Créer un fichier WAV temporaire
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_note.wav');

      final wavData = _createWavFromBuffer(buffer);
      await tempFile.writeAsBytes(wavData);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      // Attendre la fin de la lecture
      await Future.delayed(
          Duration(milliseconds: (buffer.length / 44100 * 1000).toInt()));
    } catch (e) {
      debugPrint('Erreur lecture audio: $e');
    }
  }

  Uint8List _createWavFromBuffer(Int16List samples) {
    final byteData = ByteData(44 + samples.length * 2);

    // Header RIFF
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    _writeString(byteData, 8, 'WAVE');
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, 44100, Endian.little);
    byteData.setUint32(28, 44100 * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, samples.length * 2, Endian.little);

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

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
      _currentTokenIndex = -1;
      _audioIntensity = 0.0;
    });
    _audioPlayer.stop();
  }

  Future<void> _exportWav() async {
    if (_tokens.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final frequencies = _tokens.map((token) {
        return _selectedMode == 'notes'
            ? _audioEngine.getNoteFrequency(
                noteValue: token.value,
                scaleName: _selectedScale,
                baseFrequency: 261.63,
              )
            : _audioEngine.getDirectFrequency(
                value: token.value,
                baseFrequency: 100,
                multiplier: 20,
              );
      }).toList();

      final wavData = _audioEngine.generateWavFile(
        frequencies: frequencies,
        noteDuration: _noteDuration,
        pauseDuration: _pauseDuration / 1000,
        waveType: _selectedWaveType,
        volume: _volume,
      );

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'abjad_${DateTime.now().millisecondsSinceEpoch}.wav';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(wavData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sauvegardé: $fileName'),
            backgroundColor: AppColors.tealPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'حاسبة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.tealPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Abjad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visualisation 3D
            SizedBox(
              height: 200,
              child: ParticleVisualizer(
                particleCount: (_abjadValue.clamp(100, 3000)).toInt(),
                audioIntensity: _audioIntensity,
              ),
            ),
            const SizedBox(height: 16),

            // Champ de saisie
            TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Arial',
              ),
              decoration: InputDecoration(
                hintText: 'أدخل النص هنا...',
                hintTextDirection: TextDirection.rtl,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.tealPrimary, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _inputController.clear();
                    _calculateAbjad();
                  },
                ),
              ),
              onChanged: (_) => _calculateAbjad(),
            ),
            const SizedBox(height: 16),

            // Résultat Abjad
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealPrimary, AppColors.tealAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tealPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Valeur Abjad',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _abjadValue.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_letterBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: _letterBreakdown.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item['letter']}=${item['value']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Token Display (si en lecture)
            if (_tokens.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: List.generate(_tokens.length, (index) {
                    final token = _tokens[index];
                    final isPlaying = index == _currentTokenIndex;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? AppColors.tealPrimary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${token.originalChar} (${token.value.toInt()})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isPlaying ? FontWeight.bold : FontWeight.normal,
                          color: isPlaying ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Boutons de contrôle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _tokens.isEmpty
                        ? null
                        : (_isPlaying ? _stopPlayback : _playSequence),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Arrêter' : 'Jouer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isPlaying ? Colors.red : AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      _tokens.isEmpty || _isGenerating ? null : _exportWav,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: const Text('WAV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Panneau de contrôle
            ControlPanel(
              selectedMethod: _selectedMethod,
              selectedMode: _selectedMode,
              noteDuration: _noteDuration,
              pauseDuration: _pauseDuration,
              volume: _volume,
              selectedScale: _selectedScale,
              selectedWaveType: _selectedWaveType,
              onMethodChanged: (value) => setState(() {
                _selectedMethod = value;
                _calculateAbjad();
              }),
              onModeChanged: (value) => setState(() => _selectedMode = value),
              onDurationChanged: (value) =>
                  setState(() => _noteDuration = value),
              onPauseChanged: (value) => setState(() => _pauseDuration = value),
              onVolumeChanged: (value) => setState(() => _volume = value),
              onScaleChanged: (value) => setState(() => _selectedScale = value),
              onWaveTypeChanged: (value) =>
                  setState(() => _selectedWaveType = value),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
