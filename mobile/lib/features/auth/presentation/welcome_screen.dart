import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/health_disclaimer_footer.dart';
import '../../../core/auth/auth_state_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF2F9F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Identity Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AaharTheme.borderGrey.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AaharTheme.primaryGreen.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Master Circular Emblem Badge
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AaharTheme.primaryGreen
                                      .withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/app_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Title
                          Text(
                            'AaharAi',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AaharTheme.textHeadline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Tagline
                          Text(
                            'Know What You Eat • Molecule by Molecule',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AaharTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Middle Stack: 3 Feature Badges
                    _buildFeatureBadge(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Barcode & OCR Ingredient Scanner',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureBadge(
                      icon: Icons.science_outlined,
                      title: 'Plain Language Molecule Breakdown',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureBadge(
                      icon: Icons.ramen_dining_outlined,
                      title: 'Unpacked Street Food & Calorie Tracker',
                    ),

                    const SizedBox(height: 24),

                    // Bottom Action Dock
                    // Google Sign-In Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AaharTheme.borderGrey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isLoading ? null : () async {
                            final success = await ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle();
                            if (success && context.mounted) {
                              context.go('/scanner');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Color(0xFF4285F4),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Continue with Google',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AaharTheme.textHeadline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Explore as Guest Text Button
                    TextButton(
                      onPressed: isLoading ? null : () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signInAsGuest();
                        if (success && context.mounted) {
                          context.go('/scanner');
                        }
                      },
                      child: Text(
                        'Explore as Guest',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AaharTheme.primaryGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Mandatory Health Disclaimer Footer
                    const HealthDisclaimerFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AaharTheme.borderGrey.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AaharTheme.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AaharTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AaharTheme.textHeadline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
