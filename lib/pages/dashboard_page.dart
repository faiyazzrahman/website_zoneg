import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/Sidenav.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  final List<String> _filters = ['All', 'Theft', 'Assault', 'Cyber Crime', 'Vandalism', 'Drug Trafficking'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
final String defaultUserAvatar =
    "https://res.cloudinary.com/dcyjussfg/image/upload/v1764491534/samples/balloons.jpg";   

Future<String> _getUserAvatar(String? uid) async {
  if (uid == null) return defaultUserAvatar;

  final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

  if (!doc.exists) return defaultUserAvatar;

  final data = doc.data()!;
  final profilePic = data["profilePic"];

  if (profilePic != null && profilePic.toString().isNotEmpty) {
    return profilePic;
  }

  return defaultUserAvatar;
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

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              setState(() => _currentIndex = index);
              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/map');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/post');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/inbox');
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
                  // App Bar with User Info
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    floating: true,
                    expandedHeight: 180,
                    backgroundColor: Colors.transparent,
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
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? _firestore.collection('users').doc(user?.uid).snapshots()
                              : null,
                          builder: (context, snapshot) {
                            String username = 'User';
                            if (snapshot.hasData && snapshot.data!.data() != null) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              username = data['username'] ?? 'User';
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child:FutureBuilder(
  future: _getUserAvatar(user?.uid),
  builder: (context, snapshot) {
    final avatarUrl = snapshot.data ?? defaultUserAvatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(avatarUrl),
      ),
    );
  },
)

                                   

                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
  onTap: () {
    Navigator.pushNamed(context, '/report');
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.blueAccent.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.report, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        const Text(
          'Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    ),
  ),
),

                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Search Bar and Filters
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Search Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value.toLowerCase());
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search crime reports...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.white70),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                ),
                              ),                            ),
                          ),
                          const SizedBox(height: 20),

                          // Filter Chips
                          SizedBox(
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
                                    backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                                    selectedColor: Colors.blueAccent,
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(179, 0, 0, 0),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? Colors.blueAccent : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Crime Posts Stream
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
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 80, color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No crime reports yet',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      var posts = snapshot.data!.docs;

                      // Apply filters
                      posts = posts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        final description = (data['description'] ?? '').toString().toLowerCase();
                        final crimeType = data['crimeType'] ?? '';

                        final matchesSearch = _searchQuery.isEmpty ||
                            title.contains(_searchQuery) ||
                            description.contains(_searchQuery);

                        final matchesFilter = _selectedFilter == 'All' || crimeType == _selectedFilter;

                        return matchesSearch && matchesFilter;
                      }).toList();

                      if (posts.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No matching reports found',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = posts[index].data() as Map<String, dynamic>;
                              final postId = posts[index].id;
                              
                              return _buildCrimeCard(post, postId);
                            },
                            childCount: posts.length,
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

  Widget _buildCrimeCard(Map<String, dynamic> post, String postId) {
    final crimeType = post['crimeType'] ?? 'Unknown';
    final title = post['title'] ?? 'Untitled';
    final description = post['description'] ?? '';
    final username = post['username'] ?? 'Anonymous';
    final userId = post['userId'];
    final timestamp = post['createdAt'] as Timestamp?;
    final incidentTime = post['incidentTime'] as Timestamp?;

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
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar, Username, Time
                  Row(
                    children: [
                      FutureBuilder(
  future: _getUserAvatar(userId),
  builder: (context, snapshot) {
    final avatarUrl = snapshot.data ?? defaultUserAvatar;

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white,
      backgroundImage: NetworkImage(avatarUrl),
    );
  },
),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (username == 'Anonymous') ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.verified_user, color: Colors.grey[400], size: 16),
                                ],
                              ],
                            ),
                            if (timestamp != null)
                              Text(
                                _getTimeAgo(timestamp.toDate()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCrimeTypeColor(crimeType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _getCrimeTypeColor(crimeType)),
                        ),
                        child: Text(
                          crimeType,
                          style: TextStyle(
                            color: _getCrimeTypeColor(crimeType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (title.isNotEmpty) const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                    // Post Image (if exists)
if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        post['imageUrl'],
        fit: BoxFit.cover,
        height: 250,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: Colors.white.withOpacity(0.05),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: Colors.white.withOpacity(0.1),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white60),
            ),
          );
        },
      ),
    ),
  ),

                  // Incident Time
                  if (incidentTime != null)
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white.withOpacity(0.7), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Incident: ${_formatDateTime(incidentTime.toDate())}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Action Buttons
              
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  String _formatDateTime(DateTime dateTime) =>
      "${dateTime.day}/${dateTime.month}/${dateTime.year} "
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}