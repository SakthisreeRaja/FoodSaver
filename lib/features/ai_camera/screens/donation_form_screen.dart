import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/services/donation_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/map_service.dart';
import '../services/ai_service.dart';

class DonationFormScreen extends StatefulWidget {
  final String? imagePath;
  final FoodAnalysisResult? analysisResult;

  // Legacy support: if older code passes analysisText as a string
  final String? analysisText;

  const DonationFormScreen({
    super.key,
    this.imagePath,
    this.analysisResult,
    this.analysisText,
  });

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donationService = DonationService();
  final _locationService = LocationService();

  late TextEditingController _foodTypeCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;

  String _selectedCategory = 'other';
  String _selectedUnit = 'kg';
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  // GPS coordinates (auto-detected)
  double _lat = 0;
  double _lng = 0;
  LatLng? _mapCenter;

  // Was this field pre-filled by AI?
  bool _foodTypeAiSuggested = false;
  bool _quantityAiSuggested = false;
  bool _categoryAiSuggested = false;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Bakery',
    'Processed',
    'other',
  ];

  final List<String> _units = [
    'kg',
    'g',
    'litres',
    'pieces',
    'portions',
    'servings',
  ];

  @override
  void initState() {
    super.initState();

    // Resolve the analysis result (handle legacy string path too)
    FoodAnalysisResult? result = widget.analysisResult;
    if (result == null && widget.analysisText != null) {
      result = FoodAnalysisResult.fromRawText(widget.analysisText!);
    }

    // Pre-fill from AI result
    if (result != null && !result.hasError) {
      _foodTypeCtrl =
          TextEditingController(text: result.foodType);
      _quantityCtrl =
          TextEditingController(text: result.estimatedQuantity.toString());
      _notesCtrl = TextEditingController(text: result.notes);
      _selectedUnit = _units.contains(result.unit) ? result.unit : 'kg';
      _selectedCategory =
          _categories.contains(result.category) ? result.category : 'other';
      _foodTypeAiSuggested = true;
      _quantityAiSuggested = true;
      _categoryAiSuggested = true;
    } else {
      _foodTypeCtrl = TextEditingController();
      _quantityCtrl = TextEditingController(text: '1');
      _notesCtrl = TextEditingController();
    }

    _locationCtrl = TextEditingController();

    // Auto-fill location on init
    _autoFillLocation();
  }

  /// Auto-detect GPS location and reverse-geocode to an address string
  Future<void> _autoFillLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse geocode to get a readable address
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(_lat, _lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.name != null && p.name!.isNotEmpty) p.name!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.postalCode != null && p.postalCode!.isNotEmpty)
              p.postalCode!,
          ];
          address = parts.join(', ');
        }
      } catch (_) {
        // Geocoding failed — use coordinate string as fallback
        address = '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _locationCtrl.text = address;
          _mapCenter = LatLng(_lat, _lng);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _foodTypeCtrl.dispose();
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // If no GPS was detected earlier, try one more time
      if (_lat == 0 && _lng == 0) {
        try {
          final pos = await _locationService.getCurrentLocation();
          _lat = pos.latitude;
          _lng = pos.longitude;
        } catch (_) {}
      }

      // Build AI analysis snapshot to store alongside donation
      Map<String, dynamic>? aiData;
      final result = widget.analysisResult;
      if (result != null && !result.hasError) {
        aiData = {
          'foodType': result.foodType,
          'category': result.category,
          'estimatedQuantity': result.estimatedQuantity,
          'unit': result.unit,
          'safeToEat': result.safeToEat,
          'notes': result.notes,
          'analyzedAt': DateTime.now().toIso8601String(),
        };
      }

      await _donationService.createDonation(
        foodType: _foodTypeCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
        unit: _selectedUnit,
        description: _notesCtrl.text.trim(),
        pickupLocation: _locationCtrl.text.trim(),
        latitude: _lat,
        longitude: _lng,
        category: _selectedCategory,
        imageUrl: widget.imagePath, // store path reference
        aiAnalysis: aiData,
      );

      if (!mounted) return;
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit donation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child:
                  const Icon(Icons.check, color: Colors.green, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('Donation Listed! 🎉',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'NGOs and volunteers nearby have been notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Back to Dashboard',
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/donor-dashboard');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Donation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/donor-dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image preview
              if (widget.imagePath != null)
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(File(widget.imagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // AI badge
              if (_foodTypeAiSuggested)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fields marked ✨ were pre-filled by AI. Review and edit before submitting.',
                          style: TextStyle(
                              fontSize: 12,
                              color: primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Food Type
              _buildLabel(
                  'Food Type',
                  aiSuggested: _foodTypeAiSuggested),
              const SizedBox(height: 6),
              TextFormField(
                controller: _foodTypeCtrl,
                decoration: _inputDecoration('e.g. Rice, Bread, Mixed Curry'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Category', aiSuggested: _categoryAiSuggested),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Select category'),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c[0].toUpperCase() + c.substring(1),
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? 'other'),
              ),
              const SizedBox(height: 20),

              // Quantity + Unit (side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantity',
                            aiSuggested: _quantityAiSuggested),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quantityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 5'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Unit'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: _inputDecoration('Unit'),
                          items: _units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedUnit = v ?? 'kg'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pickup Location with auto-fill button
              Row(
                children: [
                  Expanded(child: _buildLabel('Pickup Address')),
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _autoFillLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location,
                                size: 14, color: primary),
                            const SizedBox(width: 4),
                            Text('Use My Location',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationCtrl,
                decoration: _inputDecoration(
                    'e.g. 12 Park Street, Building A'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              // Mini-map preview
              if (_mapCenter != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _mapCenter!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        MapService.openStreetMapTileLayer,
                        MarkerLayer(
                          markers: [
                            MapService.createUserLocationMarker(
                              latitude: _mapCenter!.latitude,
                              longitude: _mapCenter!.longitude,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '📍 Your donation pickup location',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Notes / Instructions
              _buildLabel('Notes / Pickup Instructions (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: _inputDecoration(
                    'Any allergies, dietary notes, or access instructions...'),
              ),
              const SizedBox(height: 36),

              PrimaryButton(
                text: _isSaving ? 'Submitting...' : 'Confirm & Donate',
                isLoading: _isSaving,
                onPressed: _isSaving ? () {} : _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool aiSuggested = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        if (aiSuggested) ...[
          const SizedBox(width: 6),
          Text('✨',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
    );
  }
}