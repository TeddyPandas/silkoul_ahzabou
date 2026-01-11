class TranscriptSegment {
  final int startTime; // milliseconds
  final int endTime; // milliseconds
  final String arabic;
  final String transliteration;
  final String translation;

  TranscriptSegment({
    required this.startTime,
    required this.endTime,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
      arabic: json['arabic'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
    };
  }

  TranscriptSegment copyWith({
    int? startTime,
    int? endTime,
    String? arabic,
    String? transliteration,
    String? translation,
  }) {
    return TranscriptSegment(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
    );
  }

  // Helpers for formatting time
  String get startFormatted => _formatDuration(Duration(milliseconds: startTime));
  String get endFormatted => _formatDuration(Duration(milliseconds: endTime));

  static String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
