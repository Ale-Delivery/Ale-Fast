import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/buyer_navigator.dart';
import '../services/google_maps_service.dart';
import '../screens/home_screen.dart';

const _primaryColor = Color(0xFFFF6B35);
const _darkInk = Color(0xFF1E1E2C);

class DeliveryAddressScreen extends StatefulWidget {
  final bool proceedToCheckout;

  const DeliveryAddressScreen({super.key, this.proceedToCheckout = true});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {

  final _labelController = TextEditingController(text: 'Home');
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = true;
  bool _isLocating = false;

  List<Map<String, dynamic>> _addressSuggestions = [];
  Timer? _debounceTimer;

  Future<void> _onAddressChanged(String query) async {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggestions = await GoogleMapsService.getAutocompleteSuggestions(query);
        if (mounted) {
          setState(() {
            _addressSuggestions = suggestions;
          });
        }
      } catch (e) {
        debugPrint('Error getting address suggestions: $e');
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.'), behavior: SnackBarBehavior.floating),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.'), behavior: SnackBarBehavior.floating),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.'), behavior: SnackBarBehavior.floating),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final resolvedAddress = await GoogleMapsService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _addressController.text = resolvedAddress;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await LocalStorageService.getDeliveryAddress();
    final userPhone = await LocalStorageService.getUserPhone();
    if (saved != null) {
      _labelController.text = saved['label'] ?? 'Home';
      _addressController.text = saved['address'] ?? '';
      _phoneController.text = saved['phone'] ?? '';
    } else if (userPhone != null) {
      _phoneController.text = userPhone;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _labelController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_phoneController.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    await LocalStorageService.saveDeliveryAddress(
      label: _labelController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // Also save to Supabase for persistence across logins
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId != null) {
        final authService = AuthService();
        await authService.saveDeliveryAddress(
          userId: userId,
          label: _labelController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      }
    } catch (e) {
      debugPrint('Supabase address save failed (local save OK): $e');
    }

    if (!mounted) return;

    if (!widget.proceedToCheckout) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    BuyerNavigator.checkout(
      context,
      deliveryAddress: _addressController.text.trim(),
      deliveryPhone: _phoneController.text.trim(),
      deliveryNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      addressLabel: _labelController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkInk),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkInk, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where should we deliver?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkInk,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Label Field
                  _buildField(
                    label: 'Label (e.g. Home, Office)',
                    controller: _labelController,
                    icon: Icons.label_important_outline_rounded,
                    hintText: 'Home, Office, Apartment...',
                  ),
                  const SizedBox(height: 18),
                  
                  // Address Field
                  _buildField(
                    label: 'Full address',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    hintText: 'Street address, city, postal code',
                    maxLines: 2,
                    onChanged: _onAddressChanged,
                  ),
                  
                  if (_addressSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _addressSuggestions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, index) {
                          final item = _addressSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: _primaryColor, size: 18),
                            title: Text(
                              item['display_name'],
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkInk),
                            ),
                            onTap: () {
                              setState(() {
                                _addressController.text = item['display_name'];
                                _addressSuggestions = [];
                              });
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  
                  // Location Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primaryColor,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 16, color: _primaryColor),
                          label: Text(
                            _isLocating ? 'Locating...' : 'Locate Me',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: _primaryColor.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final result = await BuyerNavigator.locationPicker(context);
                            if (result != null && result['address'] != null) {
                              setState(() {
                                _addressController.text = result['address'];
                              });
                            }
                          },
                          icon: const Icon(Icons.map_outlined, size: 16, color: _primaryColor),
                          label: const Text(
                            'Select on Map',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: _primaryColor.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Phone Field
                  _buildField(
                    label: 'Recipient Phone number',
                    controller: _phoneController,
                    icon: Icons.phone_android_outlined,
                    hintText: '07X XXX XXXX',
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  
                  // Delivery Notes Field
                  _buildField(
                    label: 'Delivery notes (optional)',
                    controller: _notesController,
                    icon: Icons.note_alt_outlined,
                    hintText: 'e.g. Ring bell, leave at the door',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 36),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.proceedToCheckout
                            ? 'Continue to Checkout'
                            : 'Save Address',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9E9EAE),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E2C),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFC0C0D0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF9E9EAE), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
