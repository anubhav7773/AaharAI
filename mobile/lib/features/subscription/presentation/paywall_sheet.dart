import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  int _selectedTier = 1; // 0: Weekly (₹29), 1: Monthly (₹89), 2: Annual (₹499)

  final List<Map<String, dynamic>> _tiers = [
    {
      'title': 'Weekly Pass',
      'price': '₹29',
      'period': '/ week',
      'subtitle': 'Billed weekly • Cancel anytime',
      'tag': null,
    },
    {
      'title': 'Monthly Pro',
      'price': '₹89',
      'period': '/ month',
      'subtitle': 'Most popular • ₹2.9/day',
      'tag': 'RECOMMENDED',
    },
    {
      'title': 'Annual Elite',
      'price': '₹499',
      'period': '/ year',
      'subtitle': 'Save 53% • ₹41/month',
      'tag': 'BEST VALUE',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AaharTheme.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Header Badge & Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AAHARAI PRO',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Unlock Unlimited Nutritional Clarity',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AaharTheme.textHeadline,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Deconstruct unlimited food labels and roadside street foods without limits or ads.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: AaharTheme.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Feature List
              _buildFeatureItem('Unlimited Gemini 2.5 Flash label OCR photo scans'),
              _buildFeatureItem('FSSAI chemical additive safety badges (Safe/Moderate/Avoid)'),
              _buildFeatureItem('ICMR-NIN IFCT street food database & oil reuse alerts'),
              _buildFeatureItem('100% Ad-Free & priority server cold-start acceleration'),

              const SizedBox(height: 20),

              // Subscription Tiers
              ...List.generate(_tiers.length, (index) {
                final tier = _tiers[index];
                final isSelected = _selectedTier == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedTier = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AaharTheme.primarySurface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AaharTheme.primaryGreen
                            : AaharTheme.borderGrey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tier['title'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AaharTheme.textHeadline,
                                  ),
                                ),
                                if (tier['tag'] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AaharTheme.primaryGreen
                                          : const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tier['tag'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tier['subtitle'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AaharTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              tier['price'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AaharTheme.primaryGreen
                                    : AaharTheme.textHeadline,
                              ),
                            ),
                            Text(
                              tier['period'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AaharTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Google Play Billing Action Button
              ElevatedButton(
                onPressed: () {
                  final selected = _tiers[_selectedTier];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AaharTheme.primaryGreen,
                      content: Text(
                        'Connecting to Google Play Billing for ${selected['title']} (${selected['price']})...',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text('Subscribe with Google Play (${_tiers[_selectedTier]['price']})'),
              ),

              const SizedBox(height: 12),

              // Legal Links & Disclaimer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Terms of Service',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AaharTheme.textMuted,
                      ),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: AaharTheme.textLight)),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AaharTheme.textMuted,
                      ),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: AaharTheme.textLight)),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AaharTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AaharTheme.safeGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AaharTheme.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
