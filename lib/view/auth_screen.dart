// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/auth_service.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen>
//     with SingleTickerProviderStateMixin {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   bool _isLoginMode = true;
//   bool _obscurePassword = true;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _toggleMode() {
//     setState(() {
//       _isLoginMode = !_isLoginMode;
//     });
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     final authService = Provider.of<AuthService>(context, listen: false);
//     bool success = false;

//     if (_isLoginMode) {
//       success = await authService.signInWithEmailPassword(
//         _emailController.text.trim(),
//         _passwordController.text,
//       );
//     } else {
//       success = await authService.createUserWithEmailPassword(
//         _emailController.text.trim(),
//         _passwordController.text,
//       );
//     }

//     if (success) {
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _isLoginMode
//                   ? 'Login failed. Please try again.'
//                   : 'Sign up failed. Please try again.',
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _signInAnonymously() async {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     final success = await authService.signInAnonymously();

//     if (success && mounted) {
//       Navigator.pushReplacementNamed(context, '/home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context)
//           .colorScheme
//           .surface, // Fixed: background is deprecated
//       body: SafeArea(
//         child: Consumer<AuthService>(
//           builder: (context, authService, child) => FadeTransition(
//             opacity: _fadeAnimation,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 60),

//                   // App Logo/Icon
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).primaryColor,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color:
//                               Theme.of(context).primaryColor.withOpacity(0.3),
//                           blurRadius: 20,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.account_balance_wallet,
//                       size: 50,
//                       color: Colors.white,
//                     ),
//                   ),

//                   const SizedBox(height: 32),

//                   // App Title
//                   Text(
//                     'Finorix',
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   Text(
//                     'Smart Expense Tracking',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),

//                   const SizedBox(height: 48),

//                   // Auth Form
//                   Card(
//                     elevation: 8,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(24.0),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             Text(
//                               _isLoginMode ? 'Welcome Back' : 'Create Account',
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),

//                             const SizedBox(height: 24),

//                             // Email Field
//                             TextFormField(
//                               controller: _emailController,
//                               keyboardType: TextInputType.emailAddress,
//                               decoration: InputDecoration(
//                                 labelText: 'Email',
//                                 prefixIcon: const Icon(Icons.email),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your email';
//                                 }
//                                 // Fixed: Missing closing parenthesis in regex
//                                 if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                                     .hasMatch(value)) {
//                                   return 'Please enter a valid email';
//                                 }
//                                 return null;
//                               },
//                             ),

//                             const SizedBox(height: 16),

//                             // Password Field
//                             TextFormField(
//                               controller: _passwordController,
//                               obscureText: _obscurePassword,
//                               decoration: InputDecoration(
//                                 labelText: 'Password',
//                                 prefixIcon: const Icon(Icons.lock),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obscurePassword
//                                         ? Icons.visibility
//                                         : Icons.visibility_off,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _obscurePassword = !_obscurePassword;
//                                     });
//                                   },
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your password';
//                                 }
//                                 if (!_isLoginMode && value.length < 6) {
//                                   return 'Password must be at least 6 characters';
//                                 }
//                                 return null;
//                               },
//                             ),

//                             const SizedBox(height: 24),

//                             // Submit Button
//                             SizedBox(
//                               height: 50,
//                               child: ElevatedButton(
//                                 onPressed:
//                                     authService.isLoading ? null : _submitForm,
//                                 style: ElevatedButton.styleFrom(
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 child: authService.isLoading
//                                     ? const CircularProgressIndicator(
//                                         color: Colors.white)
//                                     : Text(
//                                         _isLoginMode ? 'Login' : 'Sign Up',
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                               ),
//                             ),

//                             const SizedBox(height: 16),

//                             // Toggle Mode Button
//                             TextButton(
//                               onPressed: _toggleMode,
//                               child: Text(
//                                 _isLoginMode
//                                     ? "Don't have an account? Sign Up"
//                                     : 'Already have an account? Login',
//                                 style: TextStyle(
//                                   color: Theme.of(context).primaryColor,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Divider
//                   Row(
//                     children: [
//                       const Expanded(child: Divider()),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Text(
//                           'OR',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const Expanded(child: Divider()),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   // Anonymous Login Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: OutlinedButton.icon(
//                       onPressed:
//                           authService.isLoading ? null : _signInAnonymously,
//                       icon: const Icon(Icons.person_outline),
//                       label: const Text(
//                         'Continue as Guest',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         side: BorderSide(
//                           color: Theme.of(context).primaryColor,
//                           width: 1.5,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 32),

//                   // Features List
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Features',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Theme.of(context).primaryColor,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           _buildFeatureItem(Icons.cloud_sync, 'Cloud Sync'),
//                           _buildFeatureItem(Icons.mic, 'Voice Input'),
//                           _buildFeatureItem(Icons.camera_alt, 'Bill Scanning'),
//                           _buildFeatureItem(Icons.pie_chart, 'Analytics'),
//                           _buildFeatureItem(
//                               Icons.notifications, 'Smart Reminders'),
//                           _buildFeatureItem(
//                               Icons.currency_exchange, 'Multi-Currency'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 20,
//             color: Theme.of(context).primaryColor,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             text,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    bool success = false;

    try {
      if (_isLoginMode) {
        success = await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authService.createUserWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (success && mounted) {
        // Don't use pushReplacementNamed, let the Consumer in app.dart handle navigation
        // The AuthService will notify listeners and the app will rebuild
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLoginMode
                  ? 'Login successful!'
                  : 'Account created successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLoginMode
                  ? 'Login failed. Please check your credentials.'
                  : 'Sign up failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInAnonymously() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final success = await authService.signInAnonymously();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in as guest!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Don't manually navigate, let the Consumer handle it
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anonymous sign-in failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // App Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Title
                  Text(
                    'Finorix',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Smart Expense Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Auth Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLoginMode ? 'Welcome Back' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (!_isLoginMode && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    authService.isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authService.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        _isLoginMode ? 'Login' : 'Sign Up',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Toggle Mode Button
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLoginMode
                                    ? "Don't have an account? Sign Up"
                                    : 'Already have an account? Login',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Anonymous Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed:
                          authService.isLoading ? null : _signInAnonymously,
                      icon: const Icon(Icons.person_outline),
                      label: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Features List
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(Icons.cloud_sync, 'Cloud Sync'),
                          _buildFeatureItem(Icons.mic, 'Voice Input'),
                          _buildFeatureItem(Icons.camera_alt, 'Bill Scanning'),
                          _buildFeatureItem(Icons.pie_chart, 'Analytics'),
                          _buildFeatureItem(
                              Icons.notifications, 'Smart Reminders'),
                          _buildFeatureItem(
                              Icons.currency_exchange, 'Multi-Currency'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
