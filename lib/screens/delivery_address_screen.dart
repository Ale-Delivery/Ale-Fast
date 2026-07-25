import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/saved_address.dart';
import '../navigation/buyer_navigator.dart';
import '../screens/home_screen.dart';
import '../services/address_service.dart';
import '../services/google_maps_service.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

const _primaryColor = AppColors.orange;

class DeliveryAddressScreen extends StatefulWidget {
  final bool proceedToCheckout;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const DeliveryAddressScreen({
    super.key,
    this.proceedToCheckout = true,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _labelController = TextEditingController(text: 'Home');

  final _addressController = TextEditingController();

  final _phoneController = TextEditingController();

  final _notesController = TextEditingController();

  final _addressService = AddressService();
  final _locationService = LocationService();

  bool _loading = true;
  bool _isLocating = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isDefault = false;
  bool _coordinatesNeedRefresh = false;
  bool _programmaticAddressChange = false;

  double? _latitude;
  double? _longitude;

  String? _selectedAddressId;

  List<SavedAddress> _savedAddresses = [];
  List<Map<String, dynamic>> _addressSuggestions = [];

  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _labelOptions = [
    {
      'label': 'Home',
      'icon': LucideIcons.home,
    },
    {
      'label': 'Work',
      'icon': LucideIcons.briefcase,
    },
    {
      'label': 'Apartment',
      'icon': LucideIcons.building,
    },
    {
      'label': 'Other',
      'icon': LucideIcons.mapPin,
    },
  ];

  @override
  void initState() {
    super.initState();

    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    final initialAddress = widget.initialAddress?.trim();

    if (initialAddress != null && initialAddress.isNotEmpty) {
      _setAddressText(initialAddress);
    }

    _loadScreen();
  }

  Future<void> _loadScreen() async {
    try {
      final userPhone = await LocalStorageService.getUserPhone();

      if (userPhone != null && _phoneController.text.isEmpty) {
        _phoneController.text = userPhone;
      }

      final addresses = await _addressService.getSavedAddresses();

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses = addresses;
      });

      final hasInitialAddress = widget.initialAddress != null &&
          widget.initialAddress!.trim().isNotEmpty;

      if (!hasInitialAddress && addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (item) => item.isDefault,
          orElse: () => addresses.first,
        );

        _selectSavedAddress(defaultAddress);
      }
    } catch (error) {
      debugPrint(
        'Error loading delivery screen: $error',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load saved addresses: '
              '$error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _reloadAddresses() async {
    final addresses = await _addressService.getSavedAddresses();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedAddresses = addresses;
    });
  }

  void _setAddressText(String value) {
    _programmaticAddressChange = true;
    _addressController.text = value;
    _addressController.selection = TextSelection.collapsed(
      offset: value.length,
    );
    _programmaticAddressChange = false;
  }

  void _onAddressChanged(String query) {
    _debounceTimer?.cancel();

    if (!_programmaticAddressChange) {
      final hadCoordinates = _latitude != null || _longitude != null;

      if (hadCoordinates) {
        setState(() {
          _latitude = null;
          _longitude = null;
          _coordinatesNeedRefresh = true;
        });
      }
    }

    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _addressSuggestions = [];
        });
      }

      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 350),
      () async {
        try {
          final suggestions =
              await GoogleMapsService.getAutocompleteSuggestions(
            query.trim(),
          );

          if (mounted) {
            setState(() {
              _addressSuggestions = suggestions;
            });
          }
        } catch (error) {
          debugPrint(
            'Autocomplete error: $error',
          );
        }
      },
    );
  }

  Future<void> _selectSuggestion(
    Map<String, dynamic> item,
  ) async {
    try {
      final displayName = item['display_name']?.toString() ??
          item['description']?.toString() ??
          '';

      double? latitude = _toDouble(
        item['latitude'] ?? item['lat'],
      );

      double? longitude = _toDouble(
        item['longitude'] ?? item['lon'] ?? item['lng'],
      );

      if (latitude == null || longitude == null) {
        final coordinates =
            await GoogleMapsService.getCoordinatesFromPlace(item);

        if (coordinates != null) {
          latitude = _toDouble(
            coordinates['latitude'],
          );

          longitude = _toDouble(
            coordinates['longitude'],
          );
        }
      }

      if (latitude == null || longitude == null) {
        throw Exception(
          'Coordinates were not returned for this location.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _setAddressText(displayName);
        _latitude = latitude;
        _longitude = longitude;
        _addressSuggestions = [];
        _coordinatesNeedRefresh = false;
      });

      FocusScope.of(context).unfocus();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to select location: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocating) {
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final result = await _locationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _setAddressText(result.address);
        _latitude = result.latitude;
        _longitude = result.longitude;
        _addressSuggestions = [];
        _coordinatesNeedRefresh = false;
      });

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location detected.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to detect location: '
              '$error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    try {
      final result = await BuyerNavigator.locationPicker(
        context,
      );

      if (result == null) {
        return;
      }

      final address = result['address']?.toString();

      final latitude = _toDouble(
        result['latitude'] ?? result['lat'],
      );

      final longitude = _toDouble(
        result['longitude'] ?? result['lng'] ?? result['lon'],
      );

      if (address == null ||
          address.trim().isEmpty ||
          latitude == null ||
          longitude == null) {
        throw Exception(
          'The map picker did not return a valid address and coordinates.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _setAddressText(address.trim());
        _latitude = latitude;
        _longitude = longitude;
        _addressSuggestions = [];
        _coordinatesNeedRefresh = false;
      });

      FocusScope.of(context).unfocus();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to select location: '
              '$error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectSavedAddress(
    SavedAddress address,
  ) {
    setState(() {
      _selectedAddressId = address.id;
      _labelController.text = address.label;
      _setAddressText(address.address);
      _phoneController.text = address.phone;
      _latitude = address.latitude;
      _longitude = address.longitude;
      _isDefault = address.isDefault;
      _coordinatesNeedRefresh = !address.hasValidCoordinates;
      _addressSuggestions = [];
    });

    FocusScope.of(context).unfocus();
  }

  Future<void> _addNewAddress() async {
    final userPhone = await LocalStorageService.getUserPhone();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAddressId = null;
      _labelController.text = 'Home';
      _setAddressText('');
      _phoneController.text = userPhone ?? '';
      _notesController.clear();
      _latitude = null;
      _longitude = null;
      _isDefault = _savedAddresses.isEmpty;
      _coordinatesNeedRefresh = false;
      _addressSuggestions = [];
    });
  }

  Future<void> _deleteAddress(
    SavedAddress address,
  ) async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Address',
          ),
          content: Text(
            'Delete "${address.label}" from your saved addresses?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _addressService.deleteAddress(
        address.id,
      );

      if (_selectedAddressId == address.id) {
        await _addNewAddress();
      }

      await _reloadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Address deleted.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to delete address: '
              '$error',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    final label = _labelController.text.trim();

    final address = _addressController.text.trim();

    final phone = _phoneController.text.trim();

    final notes = _notesController.text.trim();

    if (address.isEmpty) {
      _showMessage(
        'Please enter a delivery address.',
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage(
        'Please select the location using autocomplete, Locate Me, or the map.',
      );
      return;
    }

    if (!_isValidSriLankanPhone(phone)) {
      _showMessage(
        'Please enter a valid Sri Lankan phone number.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final serviceable = await _addressService.isAddressServiceable(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      if (!serviceable) {
        throw Exception(
          'This location is currently outside our service area.',
        );
      }

      final duplicate = await _addressService.findDuplicateAddress(
        latitude: _latitude!,
        longitude: _longitude!,
        excludeId: _selectedAddressId,
      );

      if (duplicate != null) {
        throw Exception(
          'This location is already saved as "${duplicate.label}".',
        );
      }

      late final SavedAddress savedAddress;

      if (_selectedAddressId == null) {
        savedAddress = await _addressService.createAddress(
          label: label.isEmpty ? 'Home' : label,
          address: address,
          phone: phone,
          latitude: _latitude!,
          longitude: _longitude!,
          isDefault: _isDefault,
        );
      } else {
        savedAddress = await _addressService.updateAddress(
          id: _selectedAddressId!,
          label: label.isEmpty ? 'Home' : label,
          address: address,
          phone: phone,
          latitude: _latitude!,
          longitude: _longitude!,
          isDefault: _isDefault,
        );
      }

      await _reloadAddresses();

      if (!mounted) {
        return;
      }

      _selectedAddressId = savedAddress.id;

      if (!widget.proceedToCheckout) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );

        return;
      }

      BuyerNavigator.checkout(
        context,
        deliveryAddress: savedAddress.address,
        deliveryPhone: savedAddress.phone,
        deliveryNotes: notes.isEmpty ? null : notes,
        addressLabel: savedAddress.label,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(error),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _isValidSriLankanPhone(
    String phone,
  ) {
    final normalized = phone.replaceAll(
      RegExp(r'[\s\-()]'),
      '',
    );

    return RegExp(
      r'^(?:\+94|94|0)7\d{8}$',
    ).hasMatch(normalized);
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isDeleting || _isLocating;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: busy
              ? null
              : () {
                  Navigator.pop(context);
                },
          icon: Icon(
            LucideIcons.arrowLeft,
            color: context.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_savedAddresses.isNotEmpty) ...[
                    _buildSavedAddressSection(
                      busy,
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    _selectedAddressId == null
                        ? 'Add delivery address'
                        : 'Edit delivery address',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildLabelSelector(busy),
                  const SizedBox(height: 18),
                  _buildField(
                    label: 'Full address',
                    controller: _addressController,
                    icon: LucideIcons.mapPin,
                    hintText: 'Street address, city, postal code',
                    maxLines: 2,
                    enabled: !busy,
                    onChanged: _onAddressChanged,
                  ),
                  _buildSuggestionList(),
                  if (_coordinatesNeedRefresh) _buildCoordinateWarning(),
                  const SizedBox(height: 14),
                  _buildLocationButtons(busy),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'Recipient phone number',
                    controller: _phoneController,
                    icon: LucideIcons.phone,
                    hintText: '07X XXX XXXX',
                    keyboard: TextInputType.phone,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    label: 'Delivery notes (optional)',
                    controller: _notesController,
                    icon: LucideIcons.messageSquare,
                    hintText: 'Ring bell, leave at the door',
                    maxLines: 2,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  _buildDefaultSwitch(busy),
                  const SizedBox(height: 34),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: busy ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.proceedToCheckout
                                  ? 'Continue to Checkout'
                                  : _selectedAddressId == null
                                      ? 'Save Address'
                                      : 'Update Address',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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

  Widget _buildSavedAddressSection(
    bool busy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAVED ADDRESSES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ..._savedAddresses.map(
          (address) {
            final selected = _selectedAddressId == address.id;

            return GestureDetector(
              onTap: busy
                  ? null
                  : () {
                      _selectSavedAddress(
                        address,
                      );
                    },
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? _primaryColor.withValues(
                          alpha: 0.08,
                        )
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _primaryColor : context.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(
                                  width: 6,
                                ),
                                const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            address.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: busy
                          ? null
                          : () {
                              _deleteAddress(
                                address,
                              );
                            },
                      icon: const Icon(
                        LucideIcons.trash2,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : _addNewAddress,
            icon: const Icon(
              LucideIcons.plus,
            ),
            label: const Text('Add New Address'),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelSelector(bool busy) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _labelOptions.map((option) {
        final selected = _labelController.text == option['label'];

        return ChoiceChip(
          selected: selected,
          onSelected: busy
              ? null
              : (_) {
                  setState(() {
                    _labelController.text = option['label'] as String;
                  });
                },
          avatar: Icon(
            option['icon'] as IconData,
            size: 16,
          ),
          label: Text(
            option['label'] as String,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionList() {
    if (_addressSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.cardBorder,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _addressSuggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _addressSuggestions[index];

          return ListTile(
            leading: const Icon(
              LucideIcons.mapPin,
              color: _primaryColor,
            ),
            title: Text(
              item['display_name']?.toString() ??
                  item['description']?.toString() ??
                  '',
            ),
            onTap: () {
              _selectSuggestion(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildCoordinateWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'The address text changed. Select the location again to confirm the map coordinates.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildLocationButtons(bool busy) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: busy ? null : _getCurrentLocation,
            icon: const Icon(
              LucideIcons.crosshair,
              color: _primaryColor,
            ),
            label: Text(
              _isLocating ? 'Locating...' : 'Locate Me',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton.icon(
            onPressed: busy ? null : _openMapPicker,
            icon: const Icon(
              LucideIcons.scan,
              color: _primaryColor,
            ),
            label: const Text('Select on Map'),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultSwitch(bool busy) {
    return SwitchListTile(
      value: _isDefault,
      activeThumbColor: _primaryColor,
      onChanged: busy
          ? null
          : (value) {
              setState(() {
                _isDefault = value;
              });
            },
      title: const Text(
        'Set as default address',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: EdgeInsets.zero,
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
    bool enabled = true,
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
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
