import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/buyer_navigator.dart';
import '../services/google_maps_service.dart';
import '../screens/home_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

const _primaryColor = AppColors.orange;

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
  List<Map<String, dynamic>> _savedAddresses = [];
  int? _selectedAddressIndex;

  List<Map<String, dynamic>> _addressSuggestions = [];
  Timer? _debounceTimer;

  final _labelOptions = [
    {'label': 'Home', 'icon': LucideIcons.home},
    {'label': 'Work', 'icon': LucideIcons.briefcase},
    {'label': 'Apartment', 'icon': LucideIcons.building},
    {'label': 'Other', 'icon': LucideIcons.mapPin},
  ];

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
          setState(() => _addressSuggestions = suggestions);
        }
      } catch (e) {
        debugPrint('Error getting address suggestions: $e');
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.'), behavior: SnackBarBehavior.floating),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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
          _selectedAddressIndex = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
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

    await _loadSavedAddresses();

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('Saved_Addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _savedAddresses = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
    }
  }

  void _selectSavedAddress(Map<String, dynamic> address, int index) {
    setState(() {
      _selectedAddressIndex = index;
      _labelController.text = address['label'] ?? 'Home';
      _addressController.text = address['address'] ?? '';
      _phoneController.text = address['phone'] ?? '';
    });
  }

  Future<void> _deleteSavedAddress(String id) async {
    try {
      await Supabase.instance.client.from('Saved_Addresses').delete().eq('id', id);
      setState(() => _selectedAddressIndex = null);
      await _loadSavedAddresses();
    } catch (e) {
      debugPrint('Error deleting address: $e');
    }
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Delivery Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.textPrimary, size: 20),
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
                  // Saved addresses at top
                  if (_savedAddresses.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(LucideIcons.bookmark, size: 16, color: context.textHint),
                        const SizedBox(width: 6),
                        Text(
                          'SAVED ADDRESSES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.textHint,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_savedAddresses.length, (i) {
                      final addr = _savedAddresses[i];
                      final isSelected = _selectedAddressIndex == i;
                      final label = addr['label'] ?? 'Home';
                      final labelData = _labelOptions.firstWhere(
                        (l) => l['label'] == label,
                        orElse: () => _labelOptions.last,
                      );
                      return GestureDetector(
                        onTap: () => _selectSavedAddress(addr, i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.08)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? _primaryColor
                                  : context.cardBorder.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primaryColor.withValues(alpha: 0.15)
                                      : context.textHint.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  labelData['icon'] as IconData,
                                  size: 16,
                                  color: isSelected ? _primaryColor : context.textHint,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? _primaryColor : context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      addr['address'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: context.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(LucideIcons.check, size: 16, color: _primaryColor)
                              else
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 16, color: context.textHint),
                                  onPressed: () => _deleteSavedAddress(addr['id']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR ADD NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: context.textHint,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Heading when no saved addresses
                  if (_savedAddresses.isEmpty)
                    Text(
                      'Where should we deliver?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                  // Label chips
                  Text(
                    'LABEL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.textHint,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _labelOptions.map((opt) {
                      final isSelected = _labelController.text == opt['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _labelController.text = opt['label'] as String;
                            _selectedAddressIndex = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.12)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _primaryColor : context.cardBorder.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                size: 14,
                                color: isSelected ? _primaryColor : context.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? _primaryColor : context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Address field
                  _buildField(
                    label: 'Full address',
                    controller: _addressController,
                    icon: LucideIcons.mapPin,
                    hintText: 'Street address, city, postal code',
                    maxLines: 2,
                    onChanged: _onAddressChanged,
                  ),

                  if (_addressSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                            leading: const Icon(LucideIcons.mapPin, color: _primaryColor, size: 18),
                            title: Text(
                              item['display_name'],
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                            ),
                            onTap: () {
                              setState(() {
                                _addressController.text = item['display_name'];
                                _addressSuggestions = [];
                                _selectedAddressIndex = null;
                              });
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Location buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                                )
                              : const Icon(LucideIcons.crosshair, size: 16, color: _primaryColor),
                          label: Text(
                            _isLocating ? 'Locating...' : 'Locate Me',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: _primaryColor.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                _selectedAddressIndex = null;
                              });
                            }
                          },
                          icon: const Icon(LucideIcons.scan, size: 16, color: _primaryColor),
                          label: const Text(
                            'Select on Map',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: _primaryColor.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phone field
                  _buildField(
                    label: 'Recipient Phone number',
                    controller: _phoneController,
                    icon: LucideIcons.phone,
                    hintText: '07X XXX XXXX',
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),

                  // Delivery notes
                  _buildField(
                    label: 'Delivery notes (optional)',
                    controller: _notesController,
                    icon: LucideIcons.messageSquare,
                    hintText: 'e.g. Ring bell, leave at the door',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 36),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.proceedToCheckout ? 'Continue to Checkout' : 'Save Address',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.textHint,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.03),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: context.textHint,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: context.textHint, size: 20),
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
