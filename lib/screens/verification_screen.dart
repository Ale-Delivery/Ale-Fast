import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/widgets/dark_widgets.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, this.email = 'example@gmail.com'});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<String> _otp = ['', '', '', ''];
  int _timerSeconds = 50;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 50);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == '⌫') {
        // Remove last filled digit
        for (int i = 3; i >= 0; i--) {
          if (_otp[i].isNotEmpty) {
            _otp[i] = '';
            break;
          }
        }
      } else {
        // Fill next empty box
        for (int i = 0; i < 4; i++) {
          if (_otp[i].isEmpty) {
            _otp[i] = key;
            break;
          }
        }
      }
    });
  }

  bool get _isComplete => _otp.every((d) => d.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          // Top content
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Verification',
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                            fontSize: 13, color: Colors.white38),
                        children: [
                          const TextSpan(
                              text: 'We have sent a code to your email\n'),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = _otp[i].isNotEmpty;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppTheme.orange.withOpacity(0.15)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: filled
                                  ? AppTheme.orange
                                  : Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _otp[i].isEmpty ? '—' : _otp[i],
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: filled ? Colors.white : Colors.white24,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Resend timer
                    Center(
                      child: _timerSeconds > 0
                          ? Text(
                              'Resend in $_timerSeconds sec',
                              style: GoogleFonts.nunito(
                                  fontSize: 12, color: Colors.white38),
                            )
                          : GestureDetector(
                              onTap: _startTimer,
                              child: Text(
                                'Resend Code',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppTheme.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    OrangeButton(
                      text: 'VERIFY',
                      onPressed: _isComplete
                          ? () {
                              // Navigate to home / success
                              Navigator.of(context).popUntil(
                                  (route) => route.isFirst);
                            }
                          : () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Numpad
          Container(
            color: Colors.white,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final keys = [
                  '1', '2', '3',
                  '4', '5', '6',
                  '7', '8', '9',
                  '', '0', '⌫',
                ];
                final key = keys[index];
                if (key.isEmpty) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  onTap: () => _onKeyTap(key),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[100]!, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: GoogleFonts.nunito(
                          fontSize: key == '⌫' ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBg,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
