import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Privacy Policy screen displaying the app's privacy policy
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 11, 2024',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              'Introduction',
              'WaitLess ("we", "our", or "us") is committed to protecting your privacy. '
              'This Privacy Policy explains how we collect, use, disclose, and safeguard '
              'your information when you use our mobile application.',
            ),
            
            _buildSection(
              'Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
              '• **Account Information**: When you create an account, we collect your '
              'display name and email address (if provided).\n\n'
              '• **Location Data**: With your permission, we collect your precise location '
              'to show nearby venues and crowd levels. You can disable location sharing in settings.\n\n'
              '• **Usage Data**: We collect information about how you use the app, including '
              'venues you visit, crowd reports you submit, and activities you complete.\n\n'
              '• **Device Information**: We collect device identifiers, operating system, '
              'and app version for analytics and troubleshooting.',
            ),
            
            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide real-time crowd levels and predictions\n'
              '• Personalize your experience and content recommendations\n'
              '• Track your time savings and contribution points\n'
              '• Send push notifications about venue crowd levels (with your permission)\n'
              '• Improve our services and develop new features\n'
              '• Respond to your requests and provide customer support',
            ),
            
            _buildSection(
              'Data Sharing',
              'We do not sell your personal information. We may share anonymized, '
              'aggregate data with:\n\n'
              '• **Business Partners**: Venue operators may receive aggregate crowd '
              'analytics (not individual user data).\n\n'
              '• **Service Providers**: We use Firebase (Google) for authentication, '
              'database, and analytics services.\n\n'
              '• **Legal Requirements**: We may disclose information if required by law '
              'or to protect our rights.',
            ),
            
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures including encryption '
              'in transit and at rest. However, no method of transmission over the '
              'internet is 100% secure.',
            ),
            
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
              '• Access and update your personal information\n'
              '• Delete your account and associated data\n'
              '• Disable location sharing at any time\n'
              '• Opt out of push notifications\n\n'
              'To exercise these rights, go to Settings > Account.',
            ),
            
            _buildSection(
              'Data Retention',
              'We retain your data as long as your account is active. If you delete '
              'your account, we will remove your personal data within 30 days, except '
              'where retention is required by law.',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              'WaitLess is not intended for children under 13. We do not knowingly '
              'collect information from children. If we learn we have collected data '
              'from a child, we will delete it promptly.',
            ),
            
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify '
              'you of material changes through the app or via email.',
            ),
            
            _buildSection(
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us at:\n\n'
              'Email: privacy@waitless.app\n'
              'Website: https://waitless.app/privacy',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
