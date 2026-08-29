import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_header.dart';
import '../widgets/info_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No profile data available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshCurrentUser(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Log out',
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GradientHeader(
                  height: 220,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _Avatar(user: user),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text('@${user.username}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    InfoSection(
                      title: 'Profile',
                      children: [
                        InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Member since',
                          value: user.joinedAt != null ? DateFormat.yMMMM().format(user.joinedAt!) : 'Unknown',
                        ),
                        if (user.birthdate != null && user.birthdate!.isNotEmpty)
                          InfoRow(icon: Icons.cake_outlined, label: 'Date of birth', value: user.birthdate!),
                        if (user.gender != null && user.gender!.isNotEmpty)
                          InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Gender',
                            value: user.gender!,
                            showDivider: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (user.city != null && user.city!.isNotEmpty)
                      InfoSection(
                        title: 'Location',
                        children: [
                          InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'City',
                            value: user.city!,
                            showDivider: false,
                          ),
                        ],
                      ),
                    if (user.city != null && user.city!.isNotEmpty) const SizedBox(height: 20),
                    InfoSection(
                      title: 'Contact',
                      children: [
                        InfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: user.email,
                          showDivider: user.phone != null && user.phone!.isNotEmpty,
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: user.phone!,
                            showDivider: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(gradient: AppColors.avatarRing, shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ClipOval(
          child: _ProfileImage(url: user.profilePictureUrl),
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String? url;
  const _ProfileImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
      ),
    );
  }
}
