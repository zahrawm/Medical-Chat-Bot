import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/button.dart';
import '../widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
   
    _addTextControllerListeners();
  }

  @override
  void dispose() {
   
    _removeTextControllerListeners();
    super.dispose();
  }

  void _addTextControllerListeners() {
    final controllers = [
      _emailController,
      _passwordController,
      if (!_isLoginMode) ...[
        _usernameController,
        _firstNameController,
        _lastNameController,
        _dayController,
        _monthController,
        _yearController,
      ],
    ];

    for (final controller in controllers) {
      controller.addListener(_checkFormValidity);
    }
  }

  void _removeTextControllerListeners() {
    final controllers = [
      _emailController,
      _passwordController,
      _usernameController,
      _firstNameController,
      _lastNameController,
      _dayController,
      _monthController,
      _yearController,
    ];

    for (final controller in controllers) {
      controller.removeListener(_checkFormValidity);
    }
  }

  void _checkFormValidity() {
    final isValid = _validateForm();
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool _validateForm() {
   
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return false;
    }

    if (!_isLoginMode) {
      if (_usernameController.text.isEmpty ||
          _firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _dayController.text.isEmpty ||
          _monthController.text.isEmpty ||
          _yearController.text.isEmpty) {
        return false;
      }

    
      final month = int.tryParse(_monthController.text);
      final day = int.tryParse(_dayController.text);
      final year = int.tryParse(_yearController.text);

      if (month == null || month < 1 || month > 12) return false;
      if (day == null || day < 1 || day > 31) return false;
      if (year == null || year < 1900 || year > DateTime.now().year) return false;
    }

  
    if (!_emailController.text.contains('@')) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/logo.png', height: 50, width: 50)),
                  SizedBox(height: 24),
                  Text(
                    _isLoginMode ? 'Welcome back' : 'Create account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),

                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: _isLoginMode
                              ? 'Don\'t have an account? '
                              : 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: _isLoginMode ? 'Sign up' : 'Sign in',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _isFormValid = false;
                              });
                              _formKey.currentState?.reset();
                              
                              _removeTextControllerListeners();
                              _addTextControllerListeners();
                              _checkFormValidity();
                            },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  if (!_isLoginMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            labelText: 'First Name',
                            hintText: 'Enter your first name',
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              return null;
                            },
                            onChanged: (_) => _checkFormValidity(),
                          ),
                        ),

                        SizedBox(width: 16),
                        Expanded(
                          child: CustomInputField(
                            labelText: 'Last Name',
                            hintText: 'Enter your last name',
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              return null;
                            },
                            onChanged: (_) => _checkFormValidity(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    CustomInputField(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                      onChanged: (_) => _checkFormValidity(),
                    ),
                    SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: CustomInputField(
                                labelText: 'Date of birth',
                                hintText: 'Month',
                                controller: _monthController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Month required';
                                  }
                                  final month = int.tryParse(value!);
                                  if (month == null ||
                                      month < 1 ||
                                      month > 12) {
                                    return 'Invalid month';
                                  }
                                  return null;
                                },
                                onChanged: (_) => _checkFormValidity(),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: CustomInputField(
                                labelText: '',
                                hintText: 'Day',
                                controller: _dayController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Day required';
                                  }
                                  final day = int.tryParse(value!);
                                  if (day == null || day < 1 || day > 31) {
                                    return 'Invalid day';
                                  }
                                  return null;
                                },
                                onChanged: (_) => _checkFormValidity(),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: CustomInputField(
                                labelText: '',
                                hintText: 'Year',
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Year required';
                                  }
                                  final year = int.tryParse(value!);
                                  if (year == null ||
                                      year < 1900 ||
                                      year > DateTime.now().year) {
                                    return 'Invalid year';
                                  }
                                  return null;
                                },
                                onChanged: (_) => _checkFormValidity(),
                              ),
                            ),
                          ],
                        ),

                    SizedBox(height: 16),
                  ],

                  CustomInputField(
                    labelText: 'Email address',
                    hintText: 'Enter your email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter email';
                      }
                      if (!value!.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                    onChanged: (_) => _checkFormValidity(),
                  ),

                  SizedBox(height: 10),

                  CustomInputField(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    keyboardType: TextInputType.visiblePassword,
                    suffixIcon: _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                    onSuffixPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    onChanged: (_) => _checkFormValidity(),
                  ),
                  SizedBox(height: 50),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.error != null) {
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                authProvider.error!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return MyButton(
                        child: authProvider.isLoading
                            ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          _isLoginMode ? 'Sign in' : 'Create account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        color: Colors.green,
                        onPressed: (authProvider.isLoading || !_isFormValid)
                            ? null
                            : _submitForm,
                        isEnabled: _isFormValid && !authProvider.isLoading,
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLoginMode) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
     
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Login successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
      }
    } else {
      final success = await authProvider.register(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        dob:
        '${_yearController.text.trim()}-${_monthController.text.trim().padLeft(2, '0')}-${_dayController.text.trim().padLeft(2, '0')}',
      );

      if (success) {
        setState(() {
          _isLoginMode = true;
          _isFormValid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Sign up successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}