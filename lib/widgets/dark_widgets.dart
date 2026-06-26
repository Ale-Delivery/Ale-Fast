import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/theme/app_theme.dart';

class DarkTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const DarkTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<DarkTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white38,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.nunito(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.orange, width: 1.5),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class OrangeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OrangeButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.color,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
