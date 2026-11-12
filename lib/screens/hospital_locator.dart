import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class HospitalLocator extends StatefulWidget {
  final VoidCallback onBack;

  const HospitalLocator({super.key, required this.onBack});

  @override
  State<HospitalLocator> createState() => _HospitalLocatorState();
}

class Hospital {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final double distanceInMeters;
  final String address;
  final String type; // 'hospital', 'clinic', or 'center'

  Hospital({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceInMeters,
    required this.address,
    this.type = 'hospital',
  });
}

class _HospitalLocatorState extends State<HospitalLocator>
    with TickerProviderStateMixin {
  LatLng? _currentPosition;
  Position? _lastPosition;
  bool _isLoading = true;
  String? _errorMessage;
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _filterType = 'hospital'; // 'all', 'hospital', 'clinic', or 'center'
  int _activeFetchId = 0;

  @override
  void initState() {
    super.initState();
    const cartoApiKey = String.fromEnvironment('CARTO_API_KEY');
    if (cartoApiKey.isEmpty) {
      debugPrint('CARTO_API_KEY is missing; start Flutter with --dart-define-from-file=.env');
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initLocationAndFetchHospitals();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetchHospitals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hospitals = [];
        _selectedHospital = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in settings.');
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ));

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _lastPosition = position;
      });

      await _fetchHospitals(position, category: _filterType);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _buildOverpassQuery(Position pos, String category) {
    const hospitalFilters = [
      'node["amenity"="hospital"]',
      'way["amenity"="hospital"]',
      'node["healthcare"="hospital"]',
      'way["healthcare"="hospital"]',
    ];
    const clinicFilters = [
      'node["amenity"="clinic"]',
      'way["amenity"="clinic"]',
      'node["amenity"="doctors"]',
      'way["amenity"="doctors"]',
      'node["healthcare"="clinic"]',
      'way["healthcare"="clinic"]',
      'node["healthcare"="doctor"]',
      'way["healthcare"="doctor"]',
    ];
    const centerFilters = [
      'node["healthcare"="rehabilitation"]',
      'way["healthcare"="rehabilitation"]',
      'node["amenity"="rehabilitation"]',
      'way["amenity"="rehabilitation"]',
      'node["social_facility:for"="disabled"]',
      'way["social_facility:for"="disabled"]',
    ];

    final filters = switch (category) {
      'hospital' => hospitalFilters,
      'clinic' => clinicFilters,
      'center' => centerFilters,
      _ => [...hospitalFilters, ...clinicFilters, ...centerFilters],
    };
    final selectors = filters
        .map((filter) =>
            '$filter(around:3500, ${pos.latitude}, ${pos.longitude});')
        .join('\n  ');

    return '''
[out:json][timeout:10];
(
  $selectors
);
out center 35;
''';
  }

  List<Hospital> _getFallbackHospitals(Position pos) {
    final rawList = [
      (
        'Lokmanya Tilak Municipal General Hospital (Sion Hospital)',
        19.0373,
        72.8601,
        'Sion West, Mumbai, Maharashtra 400022',
        'hospital',
      ),
      (
        'KEM Hospital (King Edward Memorial)',
        19.0028,
        72.8427,
        'Acharya Donde Marg, Parel, Mumbai 400012',
        'hospital',
      ),
      (
        'Tata Memorial Hospital',
        19.0048,
        72.8436,
        'Dr. E Borges Road, Parel, Mumbai 400012',
        'hospital',
      ),
      (
        'P.D. Hinduja Hospital & Medical Research Centre',
        19.0330,
        72.8384,
        'Veer Savarkar Marg, Mahim, Mumbai 400016',
        'hospital',
      ),
      (
        'Acworth Municipal Hospital',
        19.0195,
        72.8580,
        'Wadala West, Mumbai, Maharashtra 400031',
        'hospital',
      ),
      (
        'K.J. Somaiya Hospital & Research Centre',
        19.0494,
        72.8765,
        'Somaiya Ayurvihar Complex, Sion East, Mumbai 400022',
        'hospital',
      ),
      (
        'Wadala Municipal Health & Maternity Care Center',
        19.0220,
        72.8550,
        'Near Station Road, Wadala, Mumbai 400031',
        'clinic',
      ),
      (
        'Matunga Health & Family Clinic',
        19.0270,
        72.8505,
        'Lakhamsi Napoo Road, Matunga East, Mumbai 400019',
        'clinic',
      ),
      (
        'Sion Diagnostic & Polyclinic Center',
        19.0390,
        72.8620,
        'Opp. Railway Station, Sion West, Mumbai 400022',
        'clinic',
      ),
      (
        'Ali Yavar Jung National Institute of Speech and Hearing Disabilities (Divyangjan)',
        19.0544,
        72.8290,
        'K.C. Marg, Bandra Reclamation, Mumbai 400050',
        'center',
      ),
      (
        'National Association for the Blind (NAB) Rehabilitation Center',
        19.0090,
        72.8190,
        'Khan Abdul Gaffar Khan Road, Worli Seaface, Mumbai 400030',
        'center',
      ),
      (
        'Fellowship of the Physically Handicapped (FPH) Rehab Center',
        18.9720,
        72.8180,
        'Haji Ali Park, Mahalaxmi, Mumbai 400034',
        'center',
      ),
    ];

    return rawList.map((item) {
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        item.$2,
        item.$3,
      );
      return Hospital(
        id: 'fallback_${item.$1.hashCode.abs()}',
        name: item.$1,
        lat: item.$2,
        lon: item.$3,
        distanceInMeters: distance,
        address: item.$4,
        type: item.$5,
      );
    }).toList()
      ..sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
  }

  Future<void> _fetchHospitals(
    Position pos, {
    required String category,
  }) async {
    final fetchId = ++_activeFetchId;
    // Fast reliable Overpass API mirrors
    final List<String> overpassMirrors = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://lz4.overpass-api.de/api/interpreter',
      'https://overpass-api.de/api/interpreter',
    ];
    final query = _buildOverpassQuery(pos, category);

    for (final mirror in overpassMirrors) {
      try {
        final uri = Uri.parse(mirror);
        final response = await http
            .post(
              uri,
              headers: {
                'User-Agent': 'AshaSahyogApp/1.0 (https://ashasahyog.app)',
                'Accept': 'application/json',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List elements = data['elements'] ?? [];

          List<Hospital> fetchedHospitals = [];

          for (var el in elements) {
            double? lat;
            double? lon;

            if (el['type'] == 'node') {
              lat = (el['lat'] as num).toDouble();
              lon = (el['lon'] as num).toDouble();
            } else if ((el['type'] == 'way' || el['type'] == 'relation') &&
                el['center'] != null) {
              lat = (el['center']['lat'] as num).toDouble();
              lon = (el['center']['lon'] as num).toDouble();
            }

            if (lat == null || lon == null) continue;

            final tags = el['tags'] ?? {};
            final name = tags['name'] ??
                tags['name:en'] ??
                tags['operator'] ??
                (tags['healthcare'] == 'rehabilitation' ||
                        tags['amenity'] == 'rehabilitation' ||
                        tags['social_facility:for'] == 'disabled'
                    ? 'Disability support center'
                    : 'Unknown Facility');

            // Build a better address from available tags
            final List<String> addrParts = [];
            if (tags['addr:housenumber'] != null) {
              addrParts.add(tags['addr:housenumber']);
            }
            if (tags['addr:street'] != null) addrParts.add(tags['addr:street']);
            if (tags['addr:suburb'] != null) addrParts.add(tags['addr:suburb']);
            if (tags['addr:city'] != null) addrParts.add(tags['addr:city']);

            String address = addrParts.isNotEmpty
                ? addrParts.join(', ')
                : (tags['description'] ?? 'Address not available');

            final amenity = tags['amenity'] ?? '';
            final healthcare = tags['healthcare'] ?? '';
            final facilityFor = tags['social_facility:for'] ?? '';
            final nameForClassification = name.toLowerCase();
            final bool isCenter = healthcare == 'rehabilitation' ||
                amenity == 'rehabilitation' ||
                facilityFor == 'disabled' ||
                nameForClassification.contains('disabil') ||
                nameForClassification.contains('divyang') ||
                nameForClassification.contains('rehab') ||
                nameForClassification.contains('special needs');
            final String type = isCenter
                ? 'center'
                : (amenity == 'clinic' || amenity == 'doctors' ||
                        healthcare == 'doctor' || healthcare == 'clinic'
                    ? 'clinic'
                    : 'hospital');

            double distance = Geolocator.distanceBetween(
                pos.latitude, pos.longitude, lat, lon);

            fetchedHospitals.add(Hospital(
              id: el['id'].toString(),
              name: name,
              lat: lat,
              lon: lon,
              distanceInMeters: distance,
              address: address,
              type: type,
            ));
          }

          // Remove duplicates by name and location proximity
          final Map<String, Hospital> uniqueHospitals = {};
          for (var h in fetchedHospitals) {
            final key = "${h.name.toLowerCase()}_${(h.lat * 1000).round()}_${(h.lon * 1000).round()}";
            if (!uniqueHospitals.containsKey(key)) {
              uniqueHospitals[key] = h;
            }
          }
          fetchedHospitals = uniqueHospitals.values.toList();

          fetchedHospitals.sort(
              (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));

          if (!mounted || fetchId != _activeFetchId) return;
          setState(() {
            if (category == 'all') {
              _hospitals = fetchedHospitals;
            } else {
              _hospitals = [
                ..._hospitals.where((hospital) => hospital.type != category),
                ...fetchedHospitals,
              ];
            }
            _isLoading = false;
            _errorMessage = null;
          });
          return; // Success — exit loop
        }
      } catch (e) {
        debugPrint('Overpass mirror failed: $e');
        continue; // Try next mirror
      }
    }

    // If live OpenStreetMap mirrors timed out or failed, fall back to verified facilities
    final fallbackList = _getFallbackHospitals(pos);
    if (!mounted || fetchId != _activeFetchId) return;
    setState(() {
      if (category == 'all') {
        _hospitals = fallbackList;
      } else {
        _hospitals = [
          ..._hospitals.where((hospital) => hospital.type != category),
          ...fallbackList.where((hospital) => hospital.type == category),
        ];
      }
      _isLoading = false;
      _errorMessage = null;
    });
  }

  List<Hospital> get _filteredHospitals {
    if (_filterType == 'all') return _hospitals;
    return _hospitals.where((h) => h.type == _filterType).toList();
  }

  IconData _facilityIcon(String type) => switch (type) {
        'clinic' => Icons.medical_services_rounded,
        'center' => Icons.accessible_rounded,
        _ => Icons.local_hospital_rounded,
      };

  Color _facilityColor(String type) => switch (type) {
        'clinic' => AppTheme.concession,
        'center' => AppTheme.success,
        _ => AppTheme.primary,
      };

  String get _facilityLabel => switch (_filterType) {
        'hospital' => 'Hospitals',
        'clinic' => 'Clinics',
        'center' => 'Disability centers',
        _ => 'Care near you',
      };

  void _selectFilter(String category) {
    if (_filterType == category && _errorMessage == null) return;
    final position = _lastPosition;
    setState(() {
      _filterType = category;
      _selectedHospital = null;
      _errorMessage = null;
      _isLoading = position != null;
    });
    if (position != null) {
      _fetchHospitals(position, category: category);
    } else {
      _initLocationAndFetchHospitals();
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14.0);
      setState(() => _selectedHospital = null);
    }
  }

  void _selectHospital(Hospital h) {
    setState(() => _selectedHospital = h);
    _mapController.move(LatLng(h.lat, h.lon), 16.0);
  }

  Future<void> _openGoogleMaps(Hospital hospital) async {
    // Try Google Maps app first, then web fallback
    final String googleMapsApp =
        'google.navigation:q=${hospital.lat},${hospital.lon}&mode=d';
    final String googleMapsWeb =
        'https://www.google.com/maps/dir/?api=1&destination=${hospital.lat},${hospital.lon}&travelmode=driving';

    final Uri appUri = Uri.parse(googleMapsApp);
    final Uri webUri = Uri.parse(googleMapsWeb);

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation.')),
        );
      }
    }
  }

  Future<void> _openCurrentCategoryInGoogleMaps() async {
    final position = _currentPosition;
    if (position == null) return;
    final searchTerm = switch (_filterType) {
      'clinic' => 'clinics and doctors',
      'center' => 'disability rehabilitation centers',
      _ => 'hospitals',
    };
    final query = Uri.encodeComponent(
        '$searchTerm near ${position.latitude},${position.longitude}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cartoApiKey = String.fromEnvironment('CARTO_API_KEY');
    final cartoKeyQuery = cartoApiKey.isEmpty ? '' : '?key=$cartoApiKey';
    final tileUrl = cartoApiKey.isNotEmpty
        ? 'https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png$cartoKeyQuery'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      body: Stack(
        children: [
          Column(
            children: [
              // ── MAP SECTION (Top ~42%) ──────────────────────────────────
              Expanded(
                flex: _errorMessage == null ? 42 : 32,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Map or loading placeholder
                      if (_currentPosition != null)
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition!,
                            initialZoom: 12.5,
                            onTap: (_, _) =>
                                setState(() => _selectedHospital = null),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: tileUrl,
                              userAgentPackageName: 'com.ashasahyog.app',
                            ),
                            MarkerLayer(
                              markers: [
                                // Hospital markers
                                ..._filteredHospitals.map((h) => Marker(
                                      point: LatLng(h.lat, h.lon),
                                      width: 48,
                                      height: 54,
                                      child: GestureDetector(
                                        onTap: () => _selectHospital(h),
                                        child: AnimatedScale(
                                          scale: _selectedHospital?.id == h.id
                                              ? 1.25
                                              : 1.0,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: _selectedHospital?.id ==
                                                          h.id
                                                      ? _facilityColor(h.type)
                                                      : Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _facilityColor(h.type),
                                                    width: 2.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _facilityColor(h.type)
                                                          .withValues(alpha: 0.3),
                                                      blurRadius: 8,
                                                    )
                                                  ],
                                                ),
                                                child: Icon(
                                                  _facilityIcon(h.type),
                                                  color: _selectedHospital?.id ==
                                                          h.id
                                                      ? Colors.white
                                                      : _facilityColor(h.type),
                                                  size: 16,
                                                ),
                                              ),
                                              // Triangle pin bottom
                                              CustomPaint(
                                                size: const Size(10, 5),
                                                painter: _TrianglePainter(
                                                  color: _selectedHospital?.id ==
                                                          h.id
                                                      ? _facilityColor(h.type)
                                                      : Colors.white,
                                                  stroke: _facilityColor(h.type),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                                // Current location marker (pulsing)
                                Marker(
                                  point: _currentPosition!,
                                  width: 60,
                                  height: 60,
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (_, child) => Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.blue
                                                  .withValues(alpha: 0.15),
                                              border: Border.all(
                                                color: Colors.blue
                                                    .withValues(alpha: 0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.blue,
                                          ),
                                          child: const Icon(Icons.person,
                                              color: Colors.white, size: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: AppTheme.primary),
                                SizedBox(height: 12),
                                Text('Getting your location...',
                                    style:
                                        TextStyle(color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                        ),

                      // Header overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                _GlassButton(
                                  onTap: () {
                                    final langCode = context.read<LanguageProvider>().langCode;
                                    TTSService().speakFeedback(
                                      'Going back',
                                      hiMessage: 'वापस जा रहे हैं',
                                      mrMessage: 'मागे जात आहे',
                                      langCode: langCode,
                                    );
                                    widget.onBack();
                                  },
                                  child: const Icon(Icons.arrow_back_rounded,
                                      color: Color(0xFF1F2937), size: 20),
                                ),
                                const Spacer(),
                                // Stats badge
                                if (!_isLoading && _hospitals.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_hospital_rounded,
                                            color: AppTheme.primary, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_filteredHospitals.length} nearby',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
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

                      // Floating controls
                      if (_currentPosition != null)
                        Positioned(
                          right: 16,
                          bottom: 32,
                          child: Column(
                            children: [
                              _MapControlButton(
                                icon: Icons.my_location_rounded,
                                onTap: _centerOnUser,
                              ),
                            ],
                          ),
                        ),

                      if (_currentPosition != null)
                        Positioned(
                          left: 12,
                          top: 64,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '© OpenStreetMap contributors, © CARTO',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),

                      // Selected hospital mini-card on map
                      if (_selectedHospital != null)
                        Positioned(
                          bottom: 24,
                          left: 16,
                          right: 68,
                          child: _MapInfoCard(
                            hospital: _selectedHospital!,
                            onNavigate: () =>
                                _openGoogleMaps(_selectedHospital!),
                            onDismiss: () =>
                                setState(() => _selectedHospital = null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── LIST SECTION (Bottom ~58%) ─────────────────────────────
              Expanded(
                flex: _errorMessage == null ? 58 : 68,
                child: Container(
                  color: const Color(0xFFF8F6FC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + filter chips
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Text(
                              _facilityLabel,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Spacer(),
                            if (!_isLoading && _hospitals.isNotEmpty)
                              Text(
                                '${_filteredHospitals.length} found',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Filter chips
                      if (_errorMessage == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                              _FilterChip(
                                label: 'All',
                                isSelected: _filterType == 'all',
                                onTap: () => _selectFilter('all'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Hospitals',
                                isSelected: _filterType == 'hospital',
                                onTap: () => _selectFilter('hospital'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Clinics',
                                isSelected: _filterType == 'clinic',
                                onTap: () => _selectFilter('clinic'),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Disability centers',
                                isSelected: _filterType == 'center',
                                onTap: () => _selectFilter('center'),
                              ),
                              ],
                            ),
                          ),
                        ),

                      // List body
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                        color: AppTheme.primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Finding care near you...',
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            : _errorMessage != null
                                ? _ErrorView(
                                    message: _errorMessage!,
                                    onRetry: _initLocationAndFetchHospitals,
                                    onOpenMaps: _currentPosition == null
                                        ? null
                                        : _openCurrentCategoryInGoogleMaps,
                                  )
                                : _filteredHospitals.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.search_off_rounded,
                                                size: 48,
                                                color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No facilities found nearby.',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 4),
                                        itemCount:
                                            _filteredHospitals.length + 1,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          if (index ==
                                              _filteredHospitals.length) {
                                            return const SizedBox(height: 80);
                                          }
                                          final h = _filteredHospitals[index];
                                          return _HospitalCard(
                                            hospital: h,
                                            isSelected:
                                                _selectedHospital?.id == h.id,
                                            onNavigate: () =>
                                                _openGoogleMaps(h),
                                            onTapCard: () =>
                                                _selectHospital(h),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── TRIANGLE PAINTER (map pin arrow) ─────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color stroke;
  const _TrianglePainter({required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => color != old.color;
}

// ── GLASS BUTTON ──────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── MAP CONTROL BUTTON ────────────────────────────────────────────────────────

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
      ),
    );
  }
}

// ── MAP INFO CARD (mini popup on map) ─────────────────────────────────────────

class _MapInfoCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onNavigate;
  final VoidCallback onDismiss;
  const _MapInfoCard(
      {required this.hospital,
      required this.onNavigate,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hospital.type == 'center'
                  ? Icons.accessible_rounded
                  : hospital.type == 'clinic'
                      ? Icons.medical_services_rounded
                      : Icons.local_hospital_rounded,
              color: hospital.type == 'center'
                  ? AppTheme.success
                  : hospital.type == 'clinic'
                      ? AppTheme.concession
                      : AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hospital.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(_formatDist(hospital.distanceInMeters),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onNavigate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDist(double m) =>
      m < 1000 ? '${m.toStringAsFixed(0)} m away' : '${(m / 1000).toStringAsFixed(1)} km away';
}

// ── FILTER CHIP ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8)
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── ERROR VIEW ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenMaps;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (onOpenMaps != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onOpenMaps,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Search on Google Maps'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── HOSPITAL CARD ─────────────────────────────────────────────────────────────

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final bool isSelected;
  final VoidCallback onNavigate;
  final VoidCallback onTapCard;

  const _HospitalCard({
    required this.hospital,
    required this.isSelected,
    required this.onNavigate,
    required this.onTapCard,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFEDE9F8),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : const Color(0xFF6A1B9A).withValues(alpha: 0.05),
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hospital.type == 'clinic'
                          ? const Color(0xFFE0F2FE)
                          : hospital.type == 'center'
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hospital.type == 'clinic'
                          ? Icons.medical_services_rounded
                          : hospital.type == 'center'
                              ? Icons.accessible_rounded
                              : Icons.local_hospital_rounded,
                      color: hospital.type == 'clinic'
                          ? const Color(0xFF0284C7)
                          : hospital.type == 'center'
                              ? AppTheme.success
                              : AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hospital.type == 'center'
                              ? 'Disability support'
                              : hospital.type == 'clinic'
                                  ? 'Clinic'
                                  : 'Hospital',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hospital.type == 'center'
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (hospital.address != 'Address not available') ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 12, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  hospital.address,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Distance badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDistance(hospital.distanceInMeters),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),

              // Navigate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.directions_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Get Directions',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
