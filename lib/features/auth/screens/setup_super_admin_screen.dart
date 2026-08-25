import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/router/app_router.dart';
import '../../../services/auth_service.dart';
import '../widgets/auth_layout.dart';

@RoutePage()
class SetupSuperAdminScreen extends ConsumerStatefulWidget {
  const SetupSuperAdminScreen({super.key});

  @override
  ConsumerState<SetupSuperAdminScreen> createState() => _SetupSuperAdminScreenState();
}

class _SetupSuperAdminScreenState extends ConsumerState<SetupSuperAdminScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasskey = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).setupSuperAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passkey: _passkeyController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Super Admin setup successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        context.router.replace(const LoginRoute());
      }
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'System Setup',
      subtitle: 'Initialize the Super Admin account',
      formChildren: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passkeyController,
                obscureText: _obscurePasskey,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'System Passkey',
                  prefixIcon: const Icon(Icons.security),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePasskey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePasskey = !_obscurePasskey;
                      });
                    },
                  ),
                  helperText: 'Requires the secret key defined in backend',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Passkey is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SETUP SUPER ADMIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.router.replace(const LoginRoute()),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
