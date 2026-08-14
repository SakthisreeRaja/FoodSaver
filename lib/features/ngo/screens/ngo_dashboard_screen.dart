import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'pickup_mode_dialog.dart';

/// NGO Dashboard — streams available donations from Firestore and lets the NGO claim them.
/// Now with distance-based filtering, sort-by-distance, and full Gemini AI report display.
class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  String? _selectedCategory;
  String _sortBy = 'nearest'; // 'nearest' | 'newest' | 'quantity'
  String _ngoName = '';
  final Set<String> _claimedIds = {};
  final bool _isClaiming = false;
  double _radiusKm = 25.0;

  // Location state
  double? _userLat;
  double? _userLng;
  bool _locationLoading = true;
  String? _locationError;
  final _locationService = LocationService();

  final _categories = [
    'All', 'Vegetables', 'Fruits', 'Grains', 'Dairy', 'Meat', 'Bakery', 'Processed'
  ];

  @override
  void initState() {
    super.initState();
    _loadNgoName();
    _loadLocation();
  }

  Future<void> _loadNgoName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _ngoName = doc.data()?['name'] as String? ??
              doc.data()?['orgName'] as String? ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'NGO';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    setState(() => _locationLoading = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _locationLoading = false;
          _locationError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _locationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// Haversine distance in km
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // Build query
    Query query = FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available');

    if (_selectedCategory != null && _selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.business, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_ngoName.isNotEmpty ? _ngoName : 'NGO'} 👋',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Nearby food donations',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: _categories.map((cat) {
                    final selected = cat == 'All'
                        ? _selectedCategory == null
                        : _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() =>
                            _selectedCategory = cat == 'All' ? null : cat),
                        selectedColor: primary.withOpacity(0.15),
                        checkmarkColor: primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Location error banner
          if (_locationError != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location unavailable — showing all donations',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadLocation,
                      child: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // Radius slider + Sort row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  // Radius slider
                  if (_userLat != null && _userLng != null)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Radius: ${_radiusKm.toInt()} km',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Expanded(
                          child: Slider(
                            value: _radiusKm,
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '${_radiusKm.toInt()} km',
                            onChanged: (v) => setState(() => _radiusKm = v),
                          ),
                        ),
                      ],
                    ),
                  // Sort row
                  Row(
                    children: [
                      Text('Sort by: ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      GestureDetector(
                        onTap: () => setState(() => _sortBy = 'nearest'),
                        child: _sortChip('Nearest', _sortBy == 'nearest', primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortBy = 'newest'),
                        child: _sortChip('Newest', _sortBy == 'newest', primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortBy = 'quantity'),
                        child: _sortChip('Largest', _sortBy == 'quantity', primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Donations list
          StreamBuilder<QuerySnapshot>(
            stream: query.limit(100).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _locationLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Build donation list with distance
              var donations = docs.map((doc) {
                final d = {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                };
                // Calculate distance if we have location
                if (_userLat != null && _userLng != null) {
                  final coords = d['coordinates'] as Map<String, dynamic>?;
                  if (coords != null) {
                    final lat = (coords['latitude'] as num?)?.toDouble();
                    final lng = (coords['longitude'] as num?)?.toDouble();
                    if (lat != null && lng != null) {
                      d['_distance'] = _haversine(_userLat!, _userLng!, lat, lng);
                    }
                  }
                }
                return d;
              }).toList();

              // Filter by radius if location available
              if (_userLat != null && _userLng != null) {
                donations = donations.where((d) {
                  final dist = d['_distance'] as double?;
                  return dist == null || dist <= _radiusKm;
                }).toList();
              }

              // Sort
              switch (_sortBy) {
                case 'nearest':
                  donations.sort((a, b) {
                    final da = a['_distance'] as double? ?? double.infinity;
                    final db = b['_distance'] as double? ?? double.infinity;
                    return da.compareTo(db);
                  });
                  break;
                case 'newest':
                  donations.sort((a, b) {
                    final ta = a['createdAt'] as Timestamp?;
                    final tb = b['createdAt'] as Timestamp?;
                    if (ta == null && tb == null) return 0;
                    if (ta == null) return 1;
                    if (tb == null) return -1;
                    return tb.compareTo(ta);
                  });
                  break;
                case 'quantity':
                  donations.sort((a, b) {
                    final qa = a['quantity'] as int? ?? 0;
                    final qb = b['quantity'] as int? ?? 0;
                    return qb.compareTo(qa);
                  });
                  break;
              }

              if (donations.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _userLat != null
                              ? 'No donations within ${_radiusKm.toInt()} km.'
                              : 'No available donations nearby.',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (_userLat != null)
                          TextButton(
                            onPressed: () => setState(() => _radiusKm = 50),
                            child: const Text('Expand to 50 km'),
                          )
                        else
                          const Text('Check back soon!',
                              style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _donationCard(context, donations[i]),
                    childCount: donations.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, bool selected, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected ? color : Colors.grey.shade300),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: selected ? color : Colors.grey,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _donationCard(BuildContext context, Map<String, dynamic> d) {
    final donId = d['id'] as String;
    final isClaimed = _claimedIds.contains(donId);
    final foodType = d['foodType'] as String? ?? 'Food Donation';
    final qty = d['quantity'] as int? ?? 0;
    final unit = d['unit'] as String? ?? '';
    final category = d['category'] as String? ?? '';
    final location = d['pickupLocation'] as String? ?? 'N/A';
    final aiData = d['aiAnalysis'] as Map<String, dynamic>?;
    final distance = d['_distance'] as double?;
    final ts = d['createdAt'];
    String timeAgo = '';
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inHours < 1) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/donation-details', extra: d),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu,
                        color: Colors.green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(foodType,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        if (category.isNotEmpty)
                          Text(category,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  // Distance badge
                  if (distance != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: distance < 5
                            ? Colors.green.shade50
                            : distance < 15
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me, size: 12,
                              color: distance < 5
                                  ? Colors.green.shade700
                                  : distance < 15
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700),
                          const SizedBox(width: 3),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: distance < 5
                                  ? Colors.green.shade700
                                  : distance < 15
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // AI safety badge
                  if (aiData != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (aiData['safeToEat'] == true)
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (aiData['safeToEat'] == true) ? '✅' : '⚠️',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: (aiData['safeToEat'] == true)
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (timeAgo.isNotEmpty)
                    Text(timeAgo,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),

              // Gemini AI Report Section — expanded view
              if (aiData != null) ...[
                const SizedBox(height: 8),
                _geminiReportCard(aiData),
              ],

              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(Icons.scale, '$qty $unit'),
                  const SizedBox(width: 8),
                  Expanded(child: _chip(Icons.location_on_outlined, location)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isClaimed || _isClaiming)
                  ? null
                  : () => PickupModeDialog.show(context, d),
                  icon: Icon(isClaimed ? Icons.check : Icons.handshake, size: 16),
                  label: Text(isClaimed ? 'Claimed ✓' : 'Claim Donation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimed ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gemini AI Report card — shows full analysis from donor's AI scan
  Widget _geminiReportCard(Map<String, dynamic> ai) {
    final safeToEat = ai['safeToEat'] as bool? ?? true;
    final foodType = ai['foodType'] as String?;
    final notes = ai['notes']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.06),
            const Color(0xFF3F51B5).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Gemini AI Report',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: const Color(0xFF6C63FF).withOpacity(0.8))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: safeToEat
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  safeToEat ? '✅ Safe' : '⚠️ Check',
                  style: TextStyle(
                      fontSize: 10,
                      color: safeToEat ? Colors.green.shade700 : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (foodType != null) ...[
            const SizedBox(height: 4),
            Text('Detected: $foodType',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(notes,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
