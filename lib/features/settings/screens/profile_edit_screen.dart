import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/app_providers.dart';

/// User profile editing screen
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedAvatar;
  
  final _avatarEmojis = ['👤', '😀', '🙂', '😎', '🤓', '🧑‍💻', '👨‍🔬', '👩‍🎨', '🧙', '🦸'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final currentUser = ref.read(userDataProvider);
    
    if (currentUser != null) {
      _nameController.text = currentUser.displayName;
      _emailController.text = currentUser.email ?? '';
      _bioController.text = currentUser.bio ?? 'WaitLess power user';
      _selectedAvatar = currentUser.photoUrl;
    } else {
      // Fallback if no user data yet (shouldn't happen if logged in)
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      _nameController.text = user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
      _bioController.text = 'WaitLess power user';
    }
    
    if (_selectedAvatar == null || !_avatarEmojis.contains(_selectedAvatar)) {
      _selectedAvatar = _avatarEmojis[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.backgroundLight,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar picker
              _buildAvatarPicker(),
              const SizedBox(height: 32),
              
              // Name field
              _buildTextField(
                controller: _nameController,
                label: 'Display Name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              
              // Email field (read-only for Firebase users)
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
                helperText: 'Email cannot be changed',
              ),
              const SizedBox(height: 16),
              
              // Bio field
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.info_outline,
                maxLines: 3,
                helperText: 'Tell others about yourself',
              ),
              const SizedBox(height: 32),
              
              // Stats summary
              _buildStatsCard(),
              const SizedBox(height: 24),
              
              // Danger zone
              _buildDangerZone(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _selectedAvatar ?? '👤',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showAvatarPicker,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change Avatar'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
        filled: true,
        fillColor: readOnly ? AppColors.backgroundLight : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Your WaitLess Stats',
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Reports', '47'),
              _buildStat('Time Saved', '2.5h'),
              _buildStat('Streak', '🔥 7'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: AppTypography.titleSmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Avatar', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatarEmojis.map((emoji) {
                final isSelected = _selectedAvatar == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(
        displayName: _nameController.text.trim(),
        photoUrl: _selectedAvatar,
      );
      
      // Update local state
      final currentUser = ref.read(userDataProvider);
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          photoUrl: _selectedAvatar,
        );
        ref.read(userDataProvider.notifier).setUser(updatedUser);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data including reports and saved venues will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      
      if (mounted) {
        // Clear local user data
        ref.read(userDataProvider.notifier).clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Navigate to initial route (auth wrapper handles state)
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to delete account. Please try again.';
        
        // Firebase specific error for re-authentication
        if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'For security, please sign out and sign in again to delete your account.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
