import 'package:flutter/material.dart';
import '../../teachings/models/transcript_segment.dart';
import '../../../../utils/app_theme.dart';

class TranscriptEditorWidget extends StatefulWidget {
  final List<TranscriptSegment> initialSegments;
  final Function(List<TranscriptSegment>) onChanged;
  final int totalDuration; // Duration in seconds

  const TranscriptEditorWidget({
    super.key,
    required this.initialSegments,
    required this.onChanged,
    this.totalDuration = 0,
  });

  @override
  State<TranscriptEditorWidget> createState() => _TranscriptEditorWidgetState();
}

class _TranscriptEditorWidgetState extends State<TranscriptEditorWidget> {
  late List<TranscriptSegment> _segments;

  @override
  void initState() {
    super.initState();
    _segments = List.from(widget.initialSegments);
  }

  void _generateSegments() {
    showDialog(
      context: context,
      builder: (context) {
        int segmentLength = 30;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Générer les segments", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Cela remplacera tous les segments existants.", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Durée par segment (sec): ", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: segmentLength,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      items: [15, 30, 60, 120].map((e) => DropdownMenuItem(value: e, child: Text("$e s"))).toList(),
                      onChanged: (val) => setState(() => segmentLength = val!),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
                onPressed: () {
                  if (widget.totalDuration <= 0) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Durée audio invalide (0s).")));
                     return;
                  }
                  
                  final List<TranscriptSegment> newSegments = [];
                  int current = 0;
                  final totalMs = widget.totalDuration * 1000;
                  final stepMs = segmentLength * 1000;

                  while (current < totalMs) {
                    final end = (current + stepMs > totalMs) ? totalMs : current + stepMs;
                    newSegments.add(TranscriptSegment(
                      startTime: current,
                      endTime: end,
                      arabic: '',
                      transliteration: '',
                      translation: '',
                    ));
                    current = end;
                  }
                  
                  setState(() {
                    _segments = newSegments;
                  });
                  widget.onChanged(_segments);
                  Navigator.pop(context);
                },
                child: const Text("Générer", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addSegment() {
    setState(() {
      int newStart = 0;
      if (_segments.isNotEmpty) {
        newStart = _segments.last.endTime;
      }
      _segments.add(TranscriptSegment(
        startTime: newStart,
        endTime: newStart + 5000, // Default 5s
        arabic: '',
        transliteration: '',
        translation: '',
      ));
    });
    widget.onChanged(_segments);
  }

  void _removeSegment(int index) {
    setState(() {
      _segments.removeAt(index);
    });
    widget.onChanged(_segments);
  }

  void _updateSegment(int index, TranscriptSegment newSegment) {
    setState(() {
      _segments[index] = newSegment;
    });
    widget.onChanged(_segments);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
               ElevatedButton.icon(
                onPressed: _generateSegments,
                icon: const Icon(Icons.flash_on, color: Colors.yellowAccent),
                label: const Text("Générer Auto", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addSegment,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Ajouter un segment", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _segments.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final segment = _segments[index];
              return _SegmentTile(
                index: index,
                segment: segment,
                onChanged: (s) => _updateSegment(index, s),
                onDelete: () => _removeSegment(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final int index;
  final TranscriptSegment segment;
  final Function(TranscriptSegment) onChanged;
  final VoidCallback onDelete;

  const _SegmentTile({
    required this.index,
    required this.segment,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Segment #${index + 1}",
                  style: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
                tooltip: "Supprimer",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TimeInput(
                label: "Début (ms)",
                value: segment.startTime,
                onChanged: (val) => onChanged(segment.copyWith(startTime: val)),
              ),
              const SizedBox(width: 16),
              _TimeInput(
                label: "Fin (ms)",
                value: segment.endTime,
                onChanged: (val) => onChanged(segment.copyWith(endTime: val)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TextInput(
            label: "Arabe",
            value: segment.arabic,
            textAlign: TextAlign.right,
            isArabic: true,
            onChanged: (val) => onChanged(segment.copyWith(arabic: val)),
          ),
          const SizedBox(height: 12),
          _TextInput(
            label: "Translittération",
            value: segment.transliteration,
            onChanged: (val) => onChanged(segment.copyWith(transliteration: val)),
          ),
          const SizedBox(height: 12),
          _TextInput(
            label: "Traduction",
            value: segment.translation,
            onChanged: (val) => onChanged(segment.copyWith(translation: val)),
          ),
        ],
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _TimeInput({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D7A6E))),
            ),
            onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final TextAlign textAlign;
  final bool isArabic;

  const _TextInput({
    required this.label, 
    required this.value, 
    required this.onChanged, 
    this.textAlign = TextAlign.left,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          textAlign: textAlign,
          style: TextStyle(
            color: Colors.white, 
            fontFamily: isArabic ? 'Amiri' : 'Poppins',
            fontSize: isArabic ? 16 : 14,
            height: 1.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D7A6E))),
          ),
          maxLines: null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
