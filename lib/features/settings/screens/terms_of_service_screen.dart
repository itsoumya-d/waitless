import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Terms of Service screen displaying the app's terms and conditions
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By downloading, installing, or using WaitLess ("the App"), you agree '
              'to be bound by these Terms of Service. If you do not agree, please '
              'do not use the App.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'WaitLess is a crowd intelligence platform that provides:\n\n'
              '• Real-time crowd level information for venues\n'
              '• Predictions about optimal visit times\n'
              '• Activities to fill wait time\n'
              '• Gamification features including points and badges\n\n'
              'We strive for accuracy but cannot guarantee the precision of '
              'crowd predictions.',
            ),
            
            _buildSection(
              '3. User Accounts',
              'You may use the App anonymously or create an account. If you create '
              'an account, you are responsible for:\n\n'
              '• Maintaining the confidentiality of your credentials\n'
              '• All activities under your account\n'
              '• Providing accurate information',
            ),
            
            _buildSection(
              '4. User Contributions',
              'By submitting crowd reports, you:\n\n'
              '• Grant us a non-exclusive license to use, modify, and display '
              'your contributions\n'
              '• Confirm your reports are accurate to the best of your knowledge\n'
              '• Agree not to submit false, misleading, or spam reports\n\n'
              'We reserve the right to remove reports that violate these terms.',
            ),
            
            _buildSection(
              '5. Acceptable Use',
              'You agree not to:\n\n'
              '• Use the App for any unlawful purpose\n'
              '• Attempt to interfere with the App\'s operation\n'
              '• Submit false or spam crowd reports\n'
              '• Use automated systems to access the App\n'
              '• Reverse engineer or decompile the App\n'
              '• Collect other users\' information without consent',
            ),
            
            _buildSection(
              '6. Intellectual Property',
              'The App, including its design, features, and content, is owned by us '
              'and protected by intellectual property laws. You may not copy, modify, '
              'or distribute our content without permission.',
            ),
            
            _buildSection(
              '7. Third-Party Services',
              'The App integrates with third-party services including:\n\n'
              '• Firebase (authentication, database, analytics)\n'
              '• Map providers for venue locations\n\n'
              'Your use of these services is subject to their respective terms.',
            ),
            
            _buildSection(
              '8. Disclaimer of Warranties',
              'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. '
              'We do not warrant that:\n\n'
              '• The App will be uninterrupted or error-free\n'
              '• Crowd predictions will be accurate\n'
              '• Venue information will be current\n\n'
              'USE THE APP AT YOUR OWN RISK.',
            ),
            
            _buildSection(
              '9. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, we shall not be liable for '
              'any indirect, incidental, special, or consequential damages arising '
              'from your use of the App.',
            ),
            
            _buildSection(
              '10. Account Termination',
              'We may suspend or terminate your account if you violate these Terms. '
              'You may delete your account at any time through Settings.',
            ),
            
            _buildSection(
              '11. Changes to Terms',
              'We may update these Terms from time to time. Continued use of the App '
              'after changes constitutes acceptance of the new Terms.',
            ),
            
            _buildSection(
              '12. Governing Law',
              'These Terms are governed by the laws of the jurisdiction where we operate, '
              'without regard to conflict of law principles.',
            ),
            
            _buildSection(
              '13. Contact',
              'For questions about these Terms, contact us at:\n\n'
              'Email: legal@waitless.app\n'
              'Website: https://waitless.app/terms',
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
