import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/velocity_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both password fields'),
          backgroundColor: VelocityColors.danger,
        ),
      );
      return;
    }
    if (_newPasswordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: VelocityColors.danger,
        ),
      );
      return;
    }
    setState(() => _pwdLoading = true);
    try {
      await ref.read(authServiceProvider).changePassword(
            _currentPasswordCtrl.text,
            _newPasswordCtrl.text,
          );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully.'),
            backgroundColor: Color(0xFF00B894),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserMessage(e)),
            backgroundColor: VelocityColors.danger,
          ),
        );
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
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF667EEA)),
        ),
      );
    }

    final settingsAsync = ref.watch(profileSettingsProvider);

    final leftColumn = Column(
      children: [
        // Profile Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  user.role,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ProfileDetailRow(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: user.email,
                hasCopy: true,
                copied: _copied,
                onCopy: () => _handleCopyEmail(user.email),
              ),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              _ProfileDetailRow(
                icon: Icons.business_outlined,
                label: 'Department',
                value: user.department ?? 'General',
              ),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              _ProfileDetailRow(
                icon: Icons.security_outlined,
                label: 'System Authorization',
                value: user.role == 'EMPLOYEE'
                    ? 'Regular Employee'
                    : 'Administrator',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Change Password Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password (min. 6 chars)',
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _pwdLoading ? null : _handleChangePassword,
                  child: _pwdLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final rightColumn = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.policy_rounded,
                  color: Color(0xFF00B894),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Standard Office Policies',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configured organization limits that determine work shifts, late arrival thresholds, and grace periods.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          settingsAsync.when(
            data: (settings) => Column(
              children: [
                _PolicyItemBox(
                  icon: Icons.access_time_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  label: 'Shift Start Time',
                  value: _formatTime12h(settings.officeStartTime),
                ),
                const SizedBox(height: 14),
                _PolicyItemBox(
                  icon: Icons.nightlight_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0984E3), Color(0xFF00CEC9)],
                  ),
                  label: 'Shift End Time',
                  value: _formatTime12h(settings.officeEndTime),
                ),
                const SizedBox(height: 14),
                _PolicyItemBox(
                  icon: Icons.timelapse_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                  ),
                  label: 'Grace Period',
                  value: '${settings.gracePeriod} Minutes',
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF667EEA)),
              ),
            ),
            error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arriving after Shift Start + Grace Period records late arrival. Leaving before Shift End prompts an early checkout exception requiring administrative regularization.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 850;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftColumn),
                  const SizedBox(width: 28),
                  Expanded(child: rightColumn),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftColumn,
                  const SizedBox(height: 24),
                  rightColumn,
                ],
              );
            }
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (hasCopy)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: copied
                            ? const Color(0xFF00B894)
                            : const Color(0xFF94A3B8),
                      ),
                      onPressed: onCopy,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicyItemBox extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String label;
  final String value;

  const _PolicyItemBox({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
