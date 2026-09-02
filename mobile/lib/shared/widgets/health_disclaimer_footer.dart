import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_env.dart';

class HealthDisclaimerFooter extends StatelessWidget {
  final bool isCompact;

  const HealthDisclaimerFooter({
    super.key,
    this.isCompact = false,
  });

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppEnv.fromEnvironment().privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: isCompact ? 8 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Educational Use Only: AaharAi is a wellness & nutrition education utility. It does not provide medical diagnoses, treatment, or clinical advice. Consult a qualified medical practitioner for health-related decisions.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            if (!isCompact) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openPrivacyPolicy,
                child: const Text(
                  'Read Health Data & Privacy Policy (asiverticals.me)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
