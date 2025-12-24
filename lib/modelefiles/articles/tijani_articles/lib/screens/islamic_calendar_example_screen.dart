import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/islamic_calendar_provider.dart';
import '../widgets/islamic_date_card.dart';
import '../widgets/upcoming_events_widget.dart';
import '../models/islamic_event.dart';

/// Example screen demonstrating the Islamic Calendar feature
class IslamicCalendarExampleScreen extends StatefulWidget {
  const IslamicCalendarExampleScreen({Key? key}) : super(key: key);

  @override
  State<IslamicCalendarExampleScreen> createState() =>
      _IslamicCalendarExampleScreenState();
}

class _IslamicCalendarExampleScreenState
    extends State<IslamicCalendarExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize calendar data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IslamicCalendarProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Calendrier Islamique',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF0FA958),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<IslamicCalendarProvider>().refresh();
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<IslamicCalendarProvider>().refresh();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Islamic Date Card
              IslamicDateCard(
                showGregorian: true,
                showArabic: true,
                onTap: () {
                  _showDateDetails(context);
                },
              ),

              // Quick Stats
              _buildQuickStats(context),

              // Ramadan Progress (if in Ramadan)
              Consumer<IslamicCalendarProvider>(
                builder: (context, provider, child) {
                  if (provider.isRamadan) {
                    return _buildRamadanProgress(context, provider);
                  }
                  return SizedBox.shrink();
                },
              ),

              // Upcoming Events
              UpcomingEventsWidget(
                maxEvents: 10,
                showAllEvents: false,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllEventsScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer<IslamicCalendarProvider>(
      builder: (context, provider, child) {
        if (provider.currentHijriDate == null) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.event,
                      label: 'Cette semaine',
                      value: '${provider.weeklyEventsCount}',
                      color: Color(0xFF0FA958),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.calendar_month,
                      label: 'Ce mois',
                      value: '${provider.monthlyEventsCount}',
                      color: Color(0xFF9B7EBD),
                    ),
                  ),
                ],
              ),
              if (provider.hasEventToday) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFD4AF37).withOpacity(0.15),
                        Color(0xFFD4AF37).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Événement aujourd\'hui !',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              provider.todaysEvents.first.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRamadanProgress(
    BuildContext context,
    IslamicCalendarProvider provider,
  ) {
    final progress = provider.ramadanProgress ?? 0.0;
    final day = provider.currentHijriDate?.day ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9B7EBD),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9B7EBD).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌙 Ramadan Kareem',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jour $day / 30',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateDetails(BuildContext context) {
    final provider = context.read<IslamicCalendarProvider>();
    final hijriDate = provider.currentHijriDate;

    if (hijriDate == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Détails de la date',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildDetailRow('Jour', hijriDate.weekdayEn),
            _buildDetailRow('Date Hijri', hijriDate.formattedDate),
            Directionality(
              textDirection: TextDirection.rtl,
              child: _buildDetailRow('التاريخ الهجري', hijriDate.formattedDateAr),
            ),
            _buildDetailRow('Mois', '${hijriDate.monthEn} (${hijriDate.monthNumber})'),
            _buildDetailRow('Année', hijriDate.year),
            if (hijriDate.hasHoliday) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hijriDate.holidays.join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0FA958),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen showing all events
class AllEventsScreen extends StatelessWidget {
  const AllEventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Tous les événements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF0FA958),
      ),
      body: Consumer<IslamicCalendarProvider>(
        builder: (context, provider, child) {
          if (provider.upcomingEvents.isEmpty && !provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun événement à venir',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Filter by type
                _buildTypeFilter(context, provider),

                // Events list
                UpcomingEventsWidget(
                  showAllEvents: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilter(
    BuildContext context,
    IslamicCalendarProvider provider,
  ) {
    final types = EventType.values;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: types.map((type) {
            final count = provider.getEventsByType(type).length;
            if (count == 0) return SizedBox.shrink();

            return Container(
              margin: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.icon),
                    SizedBox(width: 6),
                    Text(
                      '${type.value} ($count)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                selected: false,
                onSelected: (selected) {
                  // Implement filtering logic
                },
                backgroundColor: Colors.white,
                selectedColor: Color(0xFF0FA958).withOpacity(0.2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
