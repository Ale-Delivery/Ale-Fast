import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ParcelScreen extends StatefulWidget {
  final bool isEmbedded;
  const ParcelScreen({super.key, this.isEmbedded = false});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  int _selectedSize = 1;
  int _selectedType = 0;

  final _sizes = [
    {
      'label': 'Small',
      'icon': LucideIcons.package,
      'fare': 'Rs. 200',
      'desc': 'Up to 1kg',
    },
    {
      'label': 'Medium',
      'icon': LucideIcons.box,
      'fare': 'Rs. 350',
      'desc': 'Up to 5kg',
    },
    {
      'label': 'Large',
      'icon': LucideIcons.packageCheck,
      'fare': 'Rs. 500',
      'desc': 'Up to 15kg',
    },
  ];

  final _types = const ['Documents', 'Food', 'Electronics', 'Clothing', 'Other'];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  String get _estimatedFare => _sizes[_selectedSize]['fare'] as String;

  String get _estimatedTime {
    switch (_selectedSize) {
      case 0:
        return '15-25 min';
      case 1:
        return '20-35 min';
      case 2:
        return '30-45 min';
      default:
        return '20-35 min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _buildLocationSection(),
                const SizedBox(height: 32),
                _buildSectionTitle('Package Size'),
                const SizedBox(height: 12),
                _buildSizeCards(),
                const SizedBox(height: 32),
                _buildSectionTitle('Package Type'),
                const SizedBox(height: 12),
                _buildTypeChips(),
                const SizedBox(height: 32),
                _buildFareSummary(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          if (!widget.isEmbedded) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Text(
            'Send Parcel',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        children: [
          _locationField(
            controller: _pickupController,
            icon: LucideIcons.circle,
            hint: 'Pickup location',
            iconColor: AppColors.accent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 1,
                  height: 24,
                  color: context.cardBorder,
                ),
              ],
            ),
          ),
          _locationField(
            controller: _dropoffController,
            icon: LucideIcons.mapPin,
            hint: 'Drop-off location',
            iconColor: AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textHint, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, size: 18, color: iconColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildSizeCards() {
    return Row(
      children: List.generate(_sizes.length, (i) {
        final size = _sizes[i];
        final isSelected = _selectedSize == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.06)
                    : context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.accent : context.cardBorder,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    size['icon'] as IconData,
                    size: 24,
                    color: isSelected ? AppColors.accent : context.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    size['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size['desc'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    size['fare'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_types.length, (i) {
        final isSelected = _selectedType == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : context.cardBorder,
                width: 0.5,
              ),
            ),
            child: Text(
              _types[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFareSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          _fareRow('Estimated fare', _estimatedFare, isHighlight: true),
          const SizedBox(height: 12),
          _fareRow('Delivery time', _estimatedTime),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppColors.accent : context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppGradients.glow,
          ),
          alignment: Alignment.center,
          child: const Text(
            'Send Parcel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
