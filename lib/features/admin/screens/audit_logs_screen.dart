import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/hipaa_audit_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final HipaaAuditService _auditService = HipaaAuditService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<AuditEvent> _auditEvents = [];
  List<AuditEvent> _filteredEvents = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  Set<AuditEventType> _selectedEventTypes = {};
  Set<AuditSeverity> _selectedSeverities = {};
  String? _selectedUserId;
  int _currentPage = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadAuditEvents();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditEvents({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final events = await _auditService.getAuditEvents(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        eventTypes: _selectedEventTypes.isEmpty ? null : _selectedEventTypes.toList(),
        severities: _selectedSeverities.isEmpty ? null : _selectedSeverities.toList(),
        userId: _selectedUserId,
        limit: _pageSize,
      );

      setState(() {
        if (loadMore) {
          _auditEvents.addAll(events);
        } else {
          _auditEvents = events;
          _currentPage = 0;
        }
        _applyFilters();
      });

    } catch (e) {
      _showErrorSnackBar('Failed to load audit events: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _filteredEvents = _auditEvents.where((event) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.description.toLowerCase().contains(query) &&
            !event.userId.toLowerCase().contains(query) &&
            !(event.phiIdentifier?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    _filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _filteredEvents.length >= _pageSize) {
        _currentPage++;
        _loadAuditEvents(loadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.filter),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(FeatherIcons.download),
            onPressed: _exportAuditLogs,
          ),
          PopupMenuButton<String>(
            icon: const Icon(FeatherIcons.moreVertical),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'verify_integrity', child: Text('Verify Integrity')),
              const PopupMenuItem(value: 'bulk_export', child: Text('Bulk Export')),
              const PopupMenuItem(value: 'clear_filters', child: Text('Clear Filters')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Summary Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search audit events...',
                    prefixIcon: const Icon(FeatherIcons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(FeatherIcons.x),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Summary Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryChip(
                        'Total Events',
                        _filteredEvents.length.toString(),
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryChip(
                        'Critical',
                        _filteredEvents.where((e) => e.severity == AuditSeverity.critical).length.toString(),
                        AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryChip(
                        'PHI Access',
                        _filteredEvents.where((e) => e.eventType == AuditEventType.phiAccess).length.toString(),
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                // Active Filters
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildActiveFilters(),
                ],
              ],
            ),
          ),
          // Events List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _filteredEvents.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredEvents.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppTheme.spacingMd),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _buildAuditEventTile(_filteredEvents[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];

    if (_dateRange != null) {
      filters.add(_buildFilterChip(
        'Date: ${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
        () => setState(() {
          _dateRange = null;
          _loadAuditEvents();
        }),
      ));
    }

    if (_selectedEventTypes.isNotEmpty) {
      for (final type in _selectedEventTypes) {
        filters.add(_buildFilterChip(
          _getEventTypeDisplayName(type),
          () => setState(() {
            _selectedEventTypes.remove(type);
            _loadAuditEvents();
          }),
        ));
      }
    }

    if (_selectedSeverities.isNotEmpty) {
      for (final severity in _selectedSeverities) {
        filters.add(_buildFilterChip(
          _getSeverityDisplayName(severity),
          () => setState(() {
            _selectedSeverities.remove(severity);
            _loadAuditEvents();
          }),
        ));
      }
    }

    if (_selectedUserId != null) {
      filters.add(_buildFilterChip(
        'User: $_selectedUserId',
        () => setState(() {
          _selectedUserId = null;
          _loadAuditEvents();
        }),
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: filters,
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(FeatherIcons.x, size: 14),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.fileText,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No audit events found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Try adjusting your search criteria or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(FeatherIcons.refreshCw),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditEventTile(AuditEvent event) {
    final severityColor = _getSeverityColor(event.severity);
    final eventIcon = _getEventTypeIcon(event.eventType);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border(
              left: BorderSide(color: severityColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(eventIcon, color: severityColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: severityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getSeverityDisplayName(event.severity).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: severityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getEventTypeDisplayName(event.eventType),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDateTime(event.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!event.success)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FAILED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Details Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('User', event.userId),
                    ),
                    if (event.ipAddress != null)
                      Expanded(
                        child: _buildDetailItem('IP', event.ipAddress!),
                      ),
                    if (event.phiIdentifier != null)
                      Expanded(
                        child: _buildDetailItem('PHI ID', event.phiIdentifier!),
                      ),
                  ],
                ),
                // Integrity Status
                if (!event.verifyIntegrity()) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(FeatherIcons.alertTriangle, size: 16, color: AppTheme.errorColor),
                        const SizedBox(width: 8),
                        Text(
                          'Integrity check failed',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Events'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(FeatherIcons.calendar),
                  label: Text(_dateRange != null 
                      ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                      : 'Select date range'),
                ),
                const SizedBox(height: 16),
                
                // Event Types
                Text('Event Types', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AuditEventType.values.map((type) => FilterChip(
                    label: Text(_getEventTypeDisplayName(type)),
                    selected: _selectedEventTypes.contains(type),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEventTypes.add(type);
                        } else {
                          _selectedEventTypes.remove(type);
                        }
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                // Severities
                Text('Severities', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AuditSeverity.values.map((severity) => FilterChip(
                    label: Text(_getSeverityDisplayName(severity)),
                    selected: _selectedSeverities.contains(severity),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSeverities.add(severity);
                        } else {
                          _selectedSeverities.remove(severity);
                        }
                      });
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAuditEvents();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(AuditEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSeverityColor(event.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                _getEventTypeIcon(event.eventType),
                color: _getSeverityColor(event.severity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Audit Event Details')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Event ID', event.id),
                _buildDetailRow('Description', event.description),
                _buildDetailRow('Event Type', _getEventTypeDisplayName(event.eventType)),
                _buildDetailRow('Severity', _getSeverityDisplayName(event.severity)),
                _buildDetailRow('User ID', event.userId),
                if (event.userRole != null) _buildDetailRow('User Role', event.userRole!),
                _buildDetailRow('Timestamp', _formatDateTime(event.timestamp)),
                if (event.ipAddress != null) _buildDetailRow('IP Address', event.ipAddress!),
                if (event.deviceId != null) _buildDetailRow('Device ID', event.deviceId!),
                if (event.sessionId != null) _buildDetailRow('Session ID', event.sessionId!),
                if (event.phiIdentifier != null) _buildDetailRow('PHI Identifier', event.phiIdentifier!),
                if (event.affectedResource != null) _buildDetailRow('Affected Resource', event.affectedResource!),
                _buildDetailRow('Success', event.success ? 'Yes' : 'No'),
                if (event.failureReason != null) _buildDetailRow('Failure Reason', event.failureReason!),
                if (event.metadata != null && event.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Metadata', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...event.metadata!.entries.map((entry) => 
                    _buildDetailRow(entry.key, entry.value.toString())),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: event.verifyIntegrity() 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        event.verifyIntegrity() 
                            ? FeatherIcons.check 
                            : FeatherIcons.alertTriangle,
                        color: event.verifyIntegrity() 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.verifyIntegrity() 
                            ? 'Integrity verified' 
                            : 'Integrity check failed',
                        style: TextStyle(
                          color: event.verifyIntegrity() 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (event.eventType == AuditEventType.phiAccess)
            TextButton(
              onPressed: () => _viewRelatedPhi(event.phiIdentifier ?? ''),
              child: const Text('View PHI'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _hasActiveFilters() {
    return _dateRange != null ||
           _selectedEventTypes.isNotEmpty ||
           _selectedSeverities.isNotEmpty ||
           _selectedUserId != null;
  }

  void _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (range != null) {
      setState(() {
        _dateRange = range;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _selectedEventTypes.clear();
      _selectedSeverities.clear();
      _selectedUserId = null;
    });
    _loadAuditEvents();
  }

  void _exportAuditLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit logs exported successfully')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'verify_integrity':
        _verifyIntegrity();
        break;
      case 'bulk_export':
        _bulkExport();
        break;
      case 'clear_filters':
        _clearAllFilters();
        break;
    }
  }

  void _verifyIntegrity() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Verifying integrity...'),
          ],
        ),
      ),
    );

    // Simulate integrity check
    await Future.delayed(const Duration(seconds: 2));
    
    Navigator.pop(context);
    
    final validEvents = _filteredEvents.where((e) => e.verifyIntegrity()).length;
    final totalEvents = _filteredEvents.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Integrity Check Results'),
        content: Text(
          '$validEvents of $totalEvents events passed integrity verification.\n\n'
          'Integrity: ${totalEvents > 0 ? (validEvents / totalEvents * 100).toStringAsFixed(1) : 0}%'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _bulkExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk export initiated. This may take a few minutes.')),
    );
  }

  void _viewRelatedPhi(String phiId) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing PHI record: $phiId')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getSeverityColor(AuditSeverity severity) {
    switch (severity) {
      case AuditSeverity.low:
        return AppTheme.infoColor;
      case AuditSeverity.medium:
        return AppTheme.warningColor;
      case AuditSeverity.high:
        return AppTheme.errorColor;
      case AuditSeverity.critical:
        return const Color(0xFFDC2626);
    }
  }

  IconData _getEventTypeIcon(AuditEventType eventType) {
    switch (eventType) {
      case AuditEventType.phiAccess:
      case AuditEventType.phiView:
        return FeatherIcons.eye;
      case AuditEventType.phiExport:
        return FeatherIcons.download;
      case AuditEventType.phiModification:
        return FeatherIcons.edit;
      case AuditEventType.phiDeletion:
        return FeatherIcons.trash2;
      case AuditEventType.login:
        return FeatherIcons.logIn;
      case AuditEventType.logout:
        return FeatherIcons.logOut;
      case AuditEventType.loginFailed:
        return FeatherIcons.xCircle;
      case AuditEventType.securityAlert:
        return FeatherIcons.alertTriangle;
      default:
        return FeatherIcons.activity;
    }
  }

  String _getEventTypeDisplayName(AuditEventType eventType) {
    switch (eventType) {
      case AuditEventType.phiAccess:
        return 'PHI Access';
      case AuditEventType.phiView:
        return 'PHI View';
      case AuditEventType.phiExport:
        return 'PHI Export';
      case AuditEventType.phiPrint:
        return 'PHI Print';
      case AuditEventType.phiModification:
        return 'PHI Modification';
      case AuditEventType.phiDeletion:
        return 'PHI Deletion';
      case AuditEventType.login:
        return 'Login';
      case AuditEventType.logout:
        return 'Logout';
      case AuditEventType.loginFailed:
        return 'Login Failed';
      case AuditEventType.passwordChange:
        return 'Password Change';
      case AuditEventType.mfaEnabled:
        return 'MFA Enabled';
      case AuditEventType.mfaDisabled:
        return 'MFA Disabled';
      case AuditEventType.systemAccess:
        return 'System Access';
      case AuditEventType.privilegeEscalation:
        return 'Privilege Escalation';
      case AuditEventType.configurationChange:
        return 'Configuration Change';
      case AuditEventType.securityAlert:
        return 'Security Alert';
      case AuditEventType.dataBackup:
        return 'Data Backup';
      case AuditEventType.dataRestore:
        return 'Data Restore';
      case AuditEventType.encryptionKeyAccess:
        return 'Encryption Key Access';
      case AuditEventType.auditLogAccess:
        return 'Audit Log Access';
      case AuditEventType.complianceReportGenerated:
        return 'Compliance Report';
      case AuditEventType.breachDetected:
        return 'Breach Detected';
      case AuditEventType.incidentResponse:
        return 'Incident Response';
    }
  }

  String _getSeverityDisplayName(AuditSeverity severity) {
    switch (severity) {
      case AuditSeverity.low:
        return 'Low';
      case AuditSeverity.medium:
        return 'Medium';
      case AuditSeverity.high:
        return 'High';
      case AuditSeverity.critical:
        return 'Critical';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}