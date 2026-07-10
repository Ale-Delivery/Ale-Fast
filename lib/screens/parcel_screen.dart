import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  static const _parcelPurple = Color(0xFF6C5CE7);

  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  int _selectedSize = 1; // 0=Small, 1=Medium, 2=Large
  int _selectedType = 0; // 0=Documents, 1=Food, 2=Electronics, 3=Clothing, 4=Other

  final _sizes = [
    {
      'label': 'Small',
      'icon': LucideIcons.package,
      'fare': 'Rs. 200',
      'desc': 'Up to 1kg, fits in bag',
    },
    {
      'label': 'Medium',
      'icon': LucideIcons.box,
      'fare': 'Rs. 350',
      'desc': 'Up to 5kg, medium box',
    },
    {
      'label': 'Large',
      'icon': LucideIcons.packageCheck,
      'fare': 'Rs. 500',
      'desc': 'Up to 15kg, large box',
    },
  ];

  final _types = const ['Documents', 'Food', 'Electronics', 'Clothing', 'Other'];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    final temp = _pickupController.text;
    _pickupController.text = _dropoffController.text;
    _dropoffController.text = temp;
    setState(() {});
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
      appBar: AppBar(
        title: const Text('Send Parcel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _buildLocationSection()
                    .animate()
                    .fade(duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                _buildSectionTitle('Package Size')
                    .animate()
                    .fade(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                _buildSizeCards()
                    .animate()
                    .fade(delay: 150.ms, duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                _buildSectionTitle('Package Type')
                    .animate()
                    .fade(delay: 200.ms, duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                _buildTypeChips()
                    .animate()
                    .fade(delay: 250.ms, duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                _buildFareSummary()
                    .animate()
                    .fade(delay: 300.ms, duration: 350.ms)
                    .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
        boxShadow: context.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Column(
            children: [
              _locationInput(
                controller: _pickupController,
                icon: Icons.circle,
                iconColor: AppColors.green,
                hint: 'Pickup location',
                isFirst: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 28,
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: context.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _locationInput(
                controller: _dropoffController,
                icon: Icons.location_on_rounded,
                iconColor: AppColors.orange,
                hint: 'Drop-off location',
                isFirst: false,
              ),
            ],
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _swapLocations,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _parcelPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _parcelPurple.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationInput({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required bool isFirst,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: context.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.cardBorder.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _parcelPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? _parcelPurple : context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? _parcelPurple
                      : context.cardBorder.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _parcelPurple.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    size['icon'] as IconData,
                    color: isSelected ? Colors.white : context.textMuted,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    size['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size['fare'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : _parcelPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size['desc'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : context.textMuted,
                      fontSize: 10,
                      height: 1.3,
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
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _parcelPurple : context.surfaceColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected
                    ? _parcelPurple
                    : context.cardBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _types[i],
              style: TextStyle(
                color: isSelected ? Colors.white : context.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFareSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _parcelPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _parcelPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: _parcelPurple, size: 20),
              const SizedBox(width: 10),
              Text(
                'Delivery Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Package size', _sizes[_selectedSize]['label'] as String),
          const SizedBox(height: 8),
          _summaryRow('Package type', _types[_selectedType]),
          const SizedBox(height: 8),
          _summaryRow('Estimated time', _estimatedTime),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x1A8B5CF6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated fare',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                ),
              ),
              Text(
                _estimatedFare,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _parcelPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _parcelPurple.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_pickupController.text.isEmpty ||
                  _dropoffController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter both pickup and drop-off locations'),
                    backgroundColor: context.textPrimary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Parcel booking confirmed! ${_sizes[_selectedSize]['label']} - $_estimatedFare',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: _parcelPurple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Send Parcel  •  $_estimatedFare',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const gap = 3.0;
    double y = 0;

    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, y + dashHeight),
        paint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
