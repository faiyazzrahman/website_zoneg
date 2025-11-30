import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../widgets/Sidenav.dart';
import '../services/notification_service.dart'; 
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  double _alertRadius = 500; // Default 500 meters
  String _selectedFilter = 'All';
  late TabController _tabController;
  int _crimeCount = 0;
  
  final List<String> _filters = ['All', 'Nearby', 'Today', 'This Week'];
  final List<double> _radiusOptions = [250, 500, 1000, 2000, 5000];


@override
void initState() {
  super.initState();
  _tabController = TabController(length: 1, vsync: this);
  _getCurrentLocation();
  
  // Start listening to crime posts for notifications
 // NotificationService().startListeningToCrimePosts();
}

Future<void> _getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });
    
    // Update notification service with location
    //NotificationService().setUserLocation(position);
    //NotificationService().setAlertRadius(_alertRadius);
    
  } catch (e) {
    setState(() => _isLoadingLocation = false);
  }
}
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Distance in meters
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getCrimeTypeColor(String crimeType) {
    switch (crimeType) {
      case 'Theft':
        return Colors.orange;
      case 'Assault':
        return Colors.red;
      case 'Cyber Crime':
        return Colors.purple;
      case 'Vandalism':
        return Colors.amber;
      case 'Drug Trafficking':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  IconData _getCrimeTypeIcon(String crimeType) {
    switch (crimeType) {
      case 'Theft':
        return Icons.shopping_bag_outlined;
      case 'Assault':
        return Icons.warning_amber_rounded;
      case 'Cyber Crime':
        return Icons.computer_outlined;
      case 'Vandalism':
        return Icons.broken_image_outlined;
      case 'Drug Trafficking':
        return Icons.medication_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  String _getPriorityLevel(double distance) {
    if (distance < 100) return 'Critical';
    if (distance < 300) return 'High';
    if (distance < 500) return 'Medium';
    return 'Low';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  List<QueryDocumentSnapshot> _filterAlerts(List<QueryDocumentSnapshot> alerts) {
    final now = DateTime.now();
    
    return alerts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
      final lat = data['latitude'] as double?;
      final lon = data['longitude'] as double?;
      
      // First, check if post is within radius (required for all filters)
      if (_currentPosition != null && lat != null && lon != null) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        );
        
        // If post is outside radius, exclude it from all views
        if (distance > _alertRadius) {
          return false;
        }
      } else {
        // If no location data, exclude the post
        return false;
      }
      
      // Then apply time-based filters
      if (_selectedFilter == 'Today') {
        return timestamp != null &&
            timestamp.year == now.year &&
            timestamp.month == now.month &&
            timestamp.day == now.day;
      } else if (_selectedFilter == 'This Week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        return timestamp != null && timestamp.isAfter(weekAgo);
      }
      
      // 'All' and 'Nearby' show all posts within radius
      return true;
    }).toList();
  }

String _formatDateTime(DateTime dateTime) {
  // Format: "Jan 15, 2024 at 3:30 PM"
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  final month = months[dateTime.month - 1];
  final day = dateTime.day;
  final year = dateTime.year;
  
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  
  return '$month $day, $year at $hour:$minute $period';
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            currentIndex: 3,
            onTabSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/map');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/post');
                  break;
                case 3:
                  break;
                case 4:
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
              }
            },
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    expandedHeight: 160,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.blueAccent),
                                      ),
                                      child: const Icon(Icons.notifications_active, 
                                        color: Colors.blueAccent, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                   Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Text(
            'Crime Alerts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Crime Count',
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _crimeCount > 0 
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _crimeCount > 0 ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
              child: Text(
                '$_crimeCount',
                style: TextStyle(
                  color: _crimeCount > 0 ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        _crimeCount == 0 
          ? 'No incidents nearby'
          : _crimeCount == 1
            ? '1 incident nearby'
            : '$_crimeCount incidents nearby',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    ],
  ),
),
                                    IconButton(
                                      icon: const Icon(Icons.tune, color: Colors.white),
                                      onPressed: _showRadiusSelector,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_isLoadingLocation)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.amber),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Getting location...',
                                          style: TextStyle(color: Colors.amber, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (_currentPosition != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.greenAccent),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Monitoring ${_alertRadius.toInt()}m radius',
                                          style: const TextStyle(
                                            color: Colors.greenAccent, 
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50),
                      child: Container(
                        height: 50,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.blueAccent,
                          indicatorWeight: 2,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          isScrollable: false,
                          tabAlignment: TabAlignment.center,
                          tabs: const [
                            Tab(child: Text('All Alerts', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = filter);
                                },
                                backgroundColor: Colors.black.withOpacity(0.1),
                                selectedColor: Colors.blueAccent,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? Colors.blueAccent : Colors.black.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Alerts List
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('crime_posts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.blueAccent),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SliverFillRemaining(
                          child: _buildEmptyState(),
                        );
                      }

                      var alerts = _filterAlerts(snapshot.data!.docs);

                      if (alerts.isEmpty) {
                        return SliverFillRemaining(
                          child: _buildEmptyState(),
                        );
                      }

                      // Update crime count
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_crimeCount != alerts.length) {
                          setState(() {
                            _crimeCount = alerts.length;
                          });
                        }
                      });

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final alert = alerts[index].data() as Map<String, dynamic>;
                              final alertId = alerts[index].id;
                              
                              return _buildAlertCard(alert, alertId);
                            },
                            childCount: alerts.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> alert, double? distance) {
    final crimeType = alert['crimeType'] ?? 'Unknown';
    final title = alert['title'] ?? 'Untitled';
    final description = alert['description'] ?? 'No description';
    final username = alert['username'] ?? 'Anonymous';
    final timestamp = (alert['createdAt'] as Timestamp?)?.toDate();
    final incidentTime = (alert['incidentTime'] as Timestamp?)?.toDate();
    final location = alert['location'] ?? 'Location not specified';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getCrimeTypeColor(crimeType).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCrimeTypeColor(crimeType).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCrimeTypeIcon(crimeType),
                            color: _getCrimeTypeColor(crimeType),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crime Alert Details',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCrimeTypeColor(crimeType).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getCrimeTypeColor(crimeType)),
                                ),
                                child: Text(
                                  crimeType,
                                  style: TextStyle(
                                    color: _getCrimeTypeColor(crimeType),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 24),

                    // Title
                    _buildDetailRow(Icons.title, 'Title', title),
                    const SizedBox(height: 16),

                    // Description
                    _buildDetailRow(Icons.description, 'Description', description),
                    const SizedBox(height: 16),

                    // Reporter
                    _buildDetailRow(Icons.person, 'Reported by', username),
                    const SizedBox(height: 16),

                    // Location
                    _buildDetailRow(Icons.location_on, 'Location', location),
                    const SizedBox(height: 16),

                    // Distance
                    if (distance != null)
                      _buildDetailRow(
                        Icons.my_location,
                        'Distance from you',
                        distance < 1000
                            ? '${distance.toInt()} meters'
                            : '${(distance / 1000).toStringAsFixed(2)} km',
                      ),
                    if (distance != null) const SizedBox(height: 16),

                    // Incident Time
                    if (incidentTime != null)
                      _buildDetailRow(
                        Icons.access_time,
                        'Incident Time',
                        _formatDateTime(incidentTime),
                      ),
                    if (incidentTime != null) const SizedBox(height: 16),

                    // Posted Time
                    if (timestamp != null)
                      _buildDetailRow(
                        Icons.schedule,
                        'Posted',
                        '${_getTimeAgo(timestamp)} (${_formatDateTime(timestamp)})',
                      ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No alerts found',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified of crimes in your area',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, String alertId) {
    final crimeType = alert['crimeType'] ?? 'Unknown';
    final title = alert['title'] ?? 'Untitled';
    final description = alert['description'] ?? '';
    final timestamp = (alert['createdAt'] as Timestamp?)?.toDate();
    final lat = alert['latitude'] as double?;
    final lon = alert['longitude'] as double?;
    
    double? distance;
    String? priority;
    
    if (_currentPosition != null && lat != null && lon != null) {
      distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );
      priority = _getPriorityLevel(distance);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: priority != null 
                  ? _getPriorityColor(priority).withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
                width: priority == 'Critical' ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCrimeTypeColor(crimeType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCrimeTypeIcon(crimeType),
                          color: _getCrimeTypeColor(crimeType),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getCrimeTypeColor(crimeType).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getCrimeTypeColor(crimeType)),
                                  ),
                                  child: Text(
                                    crimeType,
                                    style: TextStyle(
                                      color: _getCrimeTypeColor(crimeType),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (priority != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(priority).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _getPriorityColor(priority)),
                                    ),
                                    child: Text(
                                      priority,
                                      style: TextStyle(
                                        color: _getPriorityColor(priority),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (timestamp != null)
                              Text(
                                _getTimeAgo(timestamp),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        color: Colors.blueAccent,
                        size: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Location Info
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              distance < 1000
                                  ? '${distance.toInt()}m from your location'
                                  : '${(distance / 1000).toStringAsFixed(1)}km from your location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDetailsDialog(alert, distance),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 void _showRadiusSelector() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Radius',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how far to monitor for crime alerts',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ..._radiusOptions.map((radius) {
                    final isSelected = _alertRadius == radius;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() => _alertRadius = radius);
                          // Update notification service
                         //NotificationService().setAlertRadius(radius);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: isSelected ? Colors.blueAccent : Colors.white70,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                radius < 1000
                                    ? '${radius.toInt()} meters'
                                    : '${(radius / 1000).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.blueAccent),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}