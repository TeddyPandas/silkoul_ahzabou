import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/campaign_subscriber.dart';
import '../../providers/campaign_provider.dart';
import '../../config/app_theme.dart';

class CampaignSubscribersScreen extends StatefulWidget {
  final String campaignId;
  final String campaignName;

  const CampaignSubscribersScreen({
    super.key,
    required this.campaignId,
    required this.campaignName,
  });

  @override
  State<CampaignSubscribersScreen> createState() => _CampaignSubscribersScreenState();
}

class _CampaignSubscribersScreenState extends State<CampaignSubscribersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  int _currentPage = 0;
  String? _currentQuery;

  @override
  void initState() {
    super.initState();
    // Initial fetch
    _fetchSubscribers(refresh: true);
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchSubscribers({bool refresh = false}) {
    if (refresh) {
      _currentPage = 0;
    } else {
      _currentPage++;
    }

    Provider.of<CampaignProvider>(context, listen: false).fetchSubscribers(
      widget.campaignId,
      page: _currentPage,
      searchQuery: _currentQuery,
      refresh: refresh,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<CampaignProvider>(context, listen: false);
      if (provider.hasMoreSubscribers && !provider.isLoadingSubscribers) {
        _fetchSubscribers();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        setState(() {
          _currentQuery = query.isEmpty ? null : query;
        });
        _fetchSubscribers(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: Text(
          "Abonnés - ${widget.campaignName}",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher un abonné...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          
          Expanded(
            child: Consumer<CampaignProvider>(
              builder: (context, provider, child) {
                final subscribers = provider.subscribers;
                
                if (subscribers.isEmpty && provider.isLoadingSubscribers) {
                   return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (subscribers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "Aucun abonné trouvé",
                          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: subscribers.length + (provider.hasMoreSubscribers ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == subscribers.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)));
                    }

                    final sub = subscribers[index];
                    return _buildSubscriberCard(sub, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriberCard(CampaignSubscriber sub, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar and name
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: sub.avatarUrl != null ? NetworkImage(sub.avatarUrl!) : null,
                backgroundColor: AppColors.primaryLight,
                child: sub.avatarUrl == null 
                    ? Text(
                        sub.displayName.isNotEmpty ? sub.displayName.substring(0, 1).toUpperCase() : "?",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rejoint le ${_formatDate(sub.joinedAt)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Subscribed tasks section
          if (sub.subscribedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sub.subscribedTasks.map((task) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 14,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${task.taskName} (x${task.subscribedQuantity})",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
