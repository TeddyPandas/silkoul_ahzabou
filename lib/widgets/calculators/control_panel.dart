import 'package:flutter/material.dart';
import '../../core/audio_engine.dart';

/// Panneau de contrôle pour le calculateur Abjad
class ControlPanel extends StatelessWidget {
  final String selectedMethod;
  final String selectedMode;
  final double noteDuration;
  final double pauseDuration;
  final double volume;
  final String selectedScale;
  final String selectedWaveType;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<double> onPauseChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<String> onScaleChanged;
  final ValueChanged<String> onWaveTypeChanged;

  const ControlPanel({
    super.key,
    required this.selectedMethod,
    required this.selectedMode,
    required this.noteDuration,
    required this.pauseDuration,
    required this.volume,
    required this.selectedScale,
    required this.selectedWaveType,
    required this.onMethodChanged,
    required this.onModeChanged,
    required this.onDurationChanged,
    required this.onPauseChanged,
    required this.onVolumeChanged,
    required this.onScaleChanged,
    required this.onWaveTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Méthode Arabe
          _buildSectionTitle('📋 Méthode Arabe'),
          const SizedBox(height: 8),
          _buildRadioRow(
            options: const ['abjad', 'sequential'],
            labels: const ['Abjad (1-1000)', 'Séquentiel (1-28)'],
            selected: selectedMethod,
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: 16),

          // Mode Sonore
          _buildSectionTitle('🎵 Mode Sonore'),
          const SizedBox(height: 8),
          _buildRadioRow(
            options: const ['notes', 'frequency'],
            labels: const ['Notes', 'Fréquence'],
            selected: selectedMode,
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 16),

          // Durée de la note
          _buildSliderRow(
            icon: '⏱',
            label: 'Durée note',
            value: noteDuration,
            min: 0.1,
            max: 2.0,
            suffix: 's',
            onChanged: onDurationChanged,
          ),
          const SizedBox(height: 12),

          // Pause entre notes
          _buildSliderRow(
            icon: '⏸',
            label: 'Pause',
            value: pauseDuration,
            min: 0,
            max: 500,
            suffix: 'ms',
            onChanged: onPauseChanged,
          ),
          const SizedBox(height: 12),

          // Volume
          _buildSliderRow(
            icon: '🔊',
            label: 'Volume',
            value: volume,
            min: 0.1,
            max: 1.0,
            suffix: '',
            onChanged: onVolumeChanged,
          ),
          const SizedBox(height: 16),

          // Gamme musicale
          Row(
            children: [
              const Text('🎹', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Gamme:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: selectedScale,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: AudioEngine.scales.keys.map((scale) {
                      return DropdownMenuItem(
                        value: scale,
                        child: Text(_getScaleLabel(scale)),
                      );
                    }).toList(),
                    onChanged: (value) => onScaleChanged(value ?? 'major'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type d'onde
          Row(
            children: [
              const Text('🎸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Onde:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: selectedWaveType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: AudioEngine.waveTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getWaveLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) => onWaveTypeChanged(value ?? 'sine'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRadioRow({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = selected == options[index];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[index]),
            child: Container(
              margin:
                  EdgeInsets.only(right: index < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0FA958) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0FA958)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSliderRow({
    required String icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    final displayValue =
        suffix == 'ms' ? value.toInt().toString() : value.toStringAsFixed(1);

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFF0FA958),
            inactiveColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$displayValue$suffix',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  String _getScaleLabel(String scale) {
    switch (scale) {
      case 'chromatic':
        return 'Chromatique';
      case 'major':
        return 'Majeure';
      case 'naturalMinor':
        return 'Mineure';
      case 'pentatonicMajor':
        return 'Pentatonique';
      default:
        return scale;
    }
  }

  String _getWaveLabel(String type) {
    switch (type) {
      case 'sine':
        return 'Sinusoïdale';
      case 'square':
        return 'Carrée';
      case 'sawtooth':
        return 'Dent de scie';
      case 'triangle':
        return 'Triangulaire';
      default:
        return type;
    }
  }
}
