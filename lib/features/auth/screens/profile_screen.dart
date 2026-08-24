import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../admin/services/settings_service.dart';
import '../../../models/settings.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/services.dart';

final profileSettingsProvider = FutureProvider.autoDispose<Settings>((ref) {
  return ref.watch(settingsServiceProvider).getSettings();
});

@RoutePage()
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _copied = false;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _pwdLoading = false;

  void _handleCopyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleChangePassword() async {
    if (_currentPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both fields'), backgroundColor: Colors.red));
      return;
    }
    if (_newPasswordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _pwdLoading = true);
    try {
      await ref.read(authServiceProvider).changePassword(_currentPasswordCtrl.text, _newPasswordCtrl.text);
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _pwdLoading = false);
    }
  }

  String _formatTime12h(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final parts = timeStr.split(':');
      final hours = int.parse(parts[0]);
      final ampm = hours >= 12 ? 'PM' : 'AM';
      final displayHours = hours % 12 == 0 ? 12 : hours % 12;
      final minutes = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return '$displayHours:$minutes $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final settingsAsync = ref.watch(profileSettingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: MediaQuery.of(context).size.width > 800 ? AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    children: [
                      // Profile Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                                foregroundColor: AppTheme.primaryRed,
                                child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 16),
                              Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(user.role, style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(height: 32),
                              _ProfileDetailRow(icon: Icons.email, label: 'Email Address', value: user.email, hasCopy: true, copied: _copied, onCopy: () => _handleCopyEmail(user.email)),
                              const Divider(),
                              _ProfileDetailRow(icon: Icons.work, label: 'Department', value: user.department ?? 'EMPLOYEE'),
                              const Divider(),
                              _ProfileDetailRow(icon: Icons.security, label: 'System Authorization', value: user.role == 'EMPLOYEE' ? 'Regular Employee' : 'Administrator'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Change Password Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.vpn_key, color: AppTheme.primaryRed),
                                  const SizedBox(width: 12),
                                  Text('Change Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _currentPasswordCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _newPasswordCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'New Password (min. 6 chars)', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: _pwdLoading ? null : _handleChangePassword,
                                  child: _pwdLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Update Password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop) const SizedBox(width: 24),
                if (!isDesktop) const SizedBox(height: 24),
                // Policy Settings Card
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: AppTheme.primaryRed),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Standard Office Policies', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'These limits are configured by the administration and determine late-arrival and early-checkout exceptions.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          settingsAsync.when(
                            data: (settings) => Column(
                              children: [
                                _PolicyItemBox(icon: Icons.access_time, color: Colors.blue, label: 'Shift Start Time', value: _formatTime12h(settings.officeStartTime)),
                                const SizedBox(height: 16),
                                _PolicyItemBox(icon: Icons.coffee, color: Colors.orange, label: 'Shift End Time', value: _formatTime12h(settings.officeEndTime)),
                                const SizedBox(height: 16),
                                _PolicyItemBox(icon: Icons.warning, color: Colors.purple, label: 'Grace Period', value: '${settings.gracePeriod} Minutes'),
                              ],
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade800),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Arriving after Shift Start + Grace Period automatically marks your attendance as Late. Leaving before Shift End marks it as Early Checkout, requesting administrative approval.',
                                    style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool hasCopy;
  final bool copied;
  final VoidCallback? onCopy;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.hasCopy = false,
    this.copied = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    if (hasCopy)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(copied ? Icons.check : Icons.copy, size: 16, color: copied ? Colors.green : Colors.grey),
                        onPressed: onCopy,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyItemBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _PolicyItemBox({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
