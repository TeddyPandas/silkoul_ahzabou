/// Model representing an Islamic (Hijri) date
class IslamicDate {
  final String date;
  final String format;
  final int day;
  final String weekdayAr;
  final String weekdayEn;
  final String monthAr;
  final String monthEn;
  final int monthNumber;
  final String year;
  final String designation;
  final List<String> holidays;

  IslamicDate({
    required this.date,
    required this.format,
    required this.day,
    required this.weekdayAr,
    required this.weekdayEn,
    required this.monthAr,
    required this.monthEn,
    required this.monthNumber,
    required this.year,
    required this.designation,
    this.holidays = const [],
  });

  factory IslamicDate.fromJson(Map<String, dynamic> json) {
    return IslamicDate(
      date: json['date'] ?? '',
      format: json['format'] ?? '',
      day: json['day'] ?? 0,
      weekdayAr: json['weekday']?['ar'] ?? '',
      weekdayEn: json['weekday']?['en'] ?? '',
      monthAr: json['month']?['ar'] ?? '',
      monthEn: json['month']?['en'] ?? '',
      monthNumber: json['month']?['number'] ?? 0,
      year: json['year'] ?? '',
      designation: json['designation']?['abbreviated'] ?? '',
      holidays: json['holidays'] != null 
          ? List<String>.from(json['holidays']) 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'format': format,
      'day': day,
      'weekday': {
        'ar': weekdayAr,
        'en': weekdayEn,
      },
      'month': {
        'ar': monthAr,
        'en': monthEn,
        'number': monthNumber,
      },
      'year': year,
      'designation': {
        'abbreviated': designation,
      },
      'holidays': holidays,
    };
  }

  /// Check if this date has any holidays
  bool get hasHoliday => holidays.isNotEmpty;

  /// Get formatted date string (DD Month YYYY)
  String get formattedDate => '$day $monthEn $year';

  /// Get Arabic formatted date
  String get formattedDateAr => '$day $monthAr $year $designation';

  @override
  String toString() {
    return 'IslamicDate(date: $date, day: $day, month: $monthEn, year: $year)';
  }
}
