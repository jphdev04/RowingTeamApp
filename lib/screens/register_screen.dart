import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/athlete_service.dart';
import '../models/athlete.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _athleteService = AthleteService();

  String _selectedRole = 'coach';
  bool _isLoading = false;
  bool _linkingExistingProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();

        // Check if an athlete profile exists with this email
        final existingProfiles = await _athleteService.getAthleteByEmail(email);

        // Create auth account
        final userCredential = await _authService.register(
          email,
          _passwordController.text,
        );

        if (userCredential != null) {
          final userId = userCredential.user!.uid;

          if (existingProfiles != null) {
            // Link existing profile to this auth account
            setState(() => _linkingExistingProfile = true);

            final updatedAthlete = existingProfiles.copyWith(
              id: userId, // Update ID to match auth UID
            );

            // Delete old profile and create new one with auth UID
            await _athleteService.deleteAthlete(existingProfiles.id);
            await _athleteService.addAthlete(updatedAthlete);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile linked successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Create new athlete profile (for coaches registering)
            final athlete = Athlete(
              id: userId,
              name: _nameController.text.trim(),
              email: email,
              role: _selectedRole,
              createdAt: DateTime.now(),
            );

            await _athleteService.addAthlete(athlete);
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _linkingExistingProfile = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'If your coach added you to the roster, use the same email to link your profile',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  helperText: 'Use the email your coach provided',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  helperText: 'Only needed if you\'re a coach',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'I am a...',
                  border: OutlineInputBorder(),
                  helperText: 'Select coach only if creating a new team',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'coach',
                    child: Text('Coach (creating team)'),
                  ),
                  DropdownMenuItem(
                    value: 'coxswain',
                    child: Text('Coxswain (joining team)'),
                  ),
                  DropdownMenuItem(
                    value: 'rower',
                    child: Text('Rower (joining team)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            if (_linkingExistingProfile) ...[
                              const SizedBox(height: 8),
                              const Text('Linking profile...'),
                            ],
                          ],
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
