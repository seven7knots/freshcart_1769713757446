import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/ads_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class AdAnalyticsWidget extends StatefulWidget {
  const AdAnalyticsWidget({super.key});

  @override
  State<AdAnalyticsWidget> createState() => _AdAnalyticsWidgetState();
}

class _AdAnalyticsWidgetState extends State<AdAnalyticsWidget> {
  final AdsService _adsService = AdsService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _analytics = [];
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await _adsService.getAnalyticsSummary(
        days: _selectedDays,
      );
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ad Analytics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _selectedDays,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 Days')),
                      DropdownMenuItem(value: 30, child: Text('30 Days')),
                      DropdownMenuItem(value: 90, child: Text('90 Days')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedDays = value!);
                      _loadAnalytics();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _analytics.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'analytics',
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No analytics data yet',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _analytics.length,
                          itemBuilder: (context, index) {
                            final data = _analytics[index];
                            return _buildAnalyticsCard(data);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final impressions = data['total_impressions'] ?? 0;
    final clicks = data['total_clicks'] ?? 0;
    final ctr = data['ctr'] ?? 0.0;
    final uniqueUsers = data['unique_users'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['ad_title'] ?? 'Unknown Ad',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  'Impressions',
                  impressions.toString(),
                ),
              ),
              Expanded(child: _buildMetricColumn('Clicks', clicks.toString())),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn('CTR', '${ctr.toStringAsFixed(2)}%'),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Unique Users',
                  uniqueUsers.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
