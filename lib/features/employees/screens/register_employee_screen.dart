import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/employee_service.dart';

@RoutePage()
class RegisterEmployeeScreen extends ConsumerStatefulWidget {
  const RegisterEmployeeScreen({super.key});

  @override
  ConsumerState<RegisterEmployeeScreen> createState() => _RegisterEmployeeScreenState();
}

class _RegisterEmployeeScreenState extends ConsumerState<RegisterEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await ref.read(employeeServiceProvider).registerEmployee(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              department: _departmentController.text.trim(),
              location: _locationController.text.trim(),
            );
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee added successfully'), backgroundColor: Colors.green),
          );
          context.router.maybePop(true); // Pop with success flag
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Employee Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                        ),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Initial Password', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Location / City', prefixIcon: Icon(Icons.location_on_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('SAVE EMPLOYEE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
