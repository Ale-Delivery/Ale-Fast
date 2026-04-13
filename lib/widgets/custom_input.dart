import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String hint;
  final bool isPassword;

  const CustomInput({super.key, required this.hint, this.isPassword = false});

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: TextField(
        obscureText: widget.isPassword ? obscure : false,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),

          // 👁️ EYE ICON
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      key: ValueKey(obscure),
                      color: Colors.grey,
                    ),
                  ),
                )
              : null,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
