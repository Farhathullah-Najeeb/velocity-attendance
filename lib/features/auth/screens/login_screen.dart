import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/auth_layout.dart';

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    // print('LOGIN DEBUG: _submit() called');
    if (_formKey.currentState!.validate()) {
      // print('LOGIN DEBUG: Form validated successfully');
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      
      // print('LOGIN DEBUG: login() returned $success');
      
      if (!success) {
        // Error handling handled via state in authProvider
      }
    } else {
      // print('LOGIN DEBUG: Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.user != null && !next.isLoading) {
        if (next.user!.isApproved == false) {
          context.router.replace(const PendingApprovalRoute());
        } else if (next.user!.isActive == false) {
          // Do nothing, UI will show error from auth provider logic below,
          // but we should technically log them out so they aren't stuck logged in 
          // without access to the shell.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account is deactivated. Please contact an admin.')),
          );
          ref.read(authProvider.notifier).logout();
        } else {
          context.router.replace(const AppShellRoute());
        }
      } else if (next.error != null && next.error!.toLowerCase().contains('pending')) {
        context.router.replace(const PendingApprovalRoute());
      }
    });

    final authState = ref.watch(authProvider);

    return AuthLayout(
      title: 'Sign In',
      subtitle: 'Welcome back to Attendance Manager',
      formChildren: [
        if (authState.error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => authState.isLoading ? null : _submit(),
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
                validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.router.push(const RegisterRoute()),
                    child: const Text('Create Account'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.router.push(const ForgotPasswordRoute());
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.router.push(const SetupSuperAdminRoute()),
                  child: Text(
                    'Initialize System (Super Admin)',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
