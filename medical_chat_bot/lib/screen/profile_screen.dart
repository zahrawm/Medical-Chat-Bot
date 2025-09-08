import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobMonthController = TextEditingController();
  final _dobYearController = TextEditingController();
  final _dobDayController =
      TextEditingController(); // Not used, but kept for potential future use

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Assuming you have user data in your AuthProvider
    // You'll need to add these fields to your User model and AuthProvider
    _usernameController.text = authProvider.user?.username ?? '';
    _firstNameController.text = authProvider.user?.firstName ?? '';
    _lastNameController.text = authProvider.user?.lastName ?? '';
    _emailController.text = authProvider.user?.email ?? '';

    // Parse existing DOB if available
    final dob = authProvider.user?.dob ?? '';
    if (dob.isNotEmpty) {
      _parseDOB(dob);
    }
  }

  void _parseDOB(String dob) {
    // Assuming DOB format is MM/YYYY or YYYY-MM
    if (dob.contains('/')) {
      final parts = dob.split('/');
      if (parts.length >= 2) {
        _dobMonthController.text = parts[0];
        _dobYearController.text = parts.length == 3 ? parts[2] : parts[1];
        _dobDayController.text = parts.length == 3 ? parts[1] : '';
      }
    } else if (dob.contains('-')) {
      final parts = dob.split('-');
      if (parts.length >= 2) {
        if (parts[0].length == 4) {
          // Format: YYYY-MM
          _dobYearController.text = parts[0];
          _dobMonthController.text = parts[1];
          _dobDayController.text = parts[2];
        } else {
          // Format: MM-YYYY
          _dobMonthController.text = parts[0];
          _dobYearController.text = parts[1];
          _dobDayController.text = parts[2];
        }
      }
    }
  }

  String _formatDOB() {
    final month = _dobMonthController.text.trim();
    final year = _dobYearController.text.trim();
    final day = _dobDayController.text.trim();

    if (month.isNotEmpty && year.isNotEmpty) {
      return '$month/$year';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.green.shade600),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${_firstNameController.text} ${_lastNameController.text}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '@${_usernameController.text}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Profile Form
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Username
                    _buildProfileField(
                      'Username',
                      _usernameController,
                      Icons.person_outline,
                      enabled: _isEditing,
                    ),
                    SizedBox(height: 16),

                    // First Name & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileField(
                            'First Name',
                            _firstNameController,
                            Icons.person,
                            enabled: _isEditing,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildProfileField(
                            'Last Name',
                            _lastNameController,
                            Icons.person,
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Email
                    _buildProfileField(
                      'Email',
                      _emailController,
                      Icons.email_outlined,
                      enabled: false, // Email usually shouldn't be editable
                    ),
                    SizedBox(height: 16),

                    // Date of Birth - Month and Year only
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Month & Year',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDOBField(
                                'Month',
                                _dobMonthController,
                                '01-12',
                                maxLength: 2,
                                enabled: _isEditing,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDOBField(
                                'Year',
                                _dobYearController,
                                'YYYY',
                                maxLength: 4,
                                enabled: _isEditing,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDOBField(
                                'Day',
                                _dobDayController,
                                '',
                                maxLength: 2,
                                enabled: _isEditing,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Additional Options
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildSettingsOption(
                    'Change Password',
                    Icons.lock_outline,
                    onTap: _changePassword,
                  ),
                  Divider(height: 32),

                  _buildSettingsOption(
                    'Privacy Settings',
                    Icons.privacy_tip_outlined,
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),
                  Divider(height: 32),

                  _buildSettingsOption(
                    'Export Chat History',
                    Icons.download_outlined,
                    onTap: () {
                      // Export chat history
                    },
                  ),
                  Divider(height: 32),

                  _buildSettingsOption(
                    'Delete Account',
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _showLogoutConfirmation,
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.green.shade600 : Colors.grey.shade400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        fillColor: enabled ? null : Colors.grey.shade50,
        filled: !enabled,
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildDOBField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLength = 2,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '', // Remove character counter
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        fillColor: enabled ? null : Colors.grey.shade50,
        filled: !enabled,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Required';
        }

        final intValue = int.tryParse(value!);
        if (intValue == null) {
          return 'Invalid';
        }

        if (label == 'Month' && (intValue < 1 || intValue > 12)) {
          return '1-12';
        } else if (label == 'Year' &&
            (intValue < 1900 || intValue > DateTime.now().year)) {
          return 'Invalid year';
        }

        return null;
      },
    );
  }

  Widget _buildSettingsOption(
    String title,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final textColor = color ?? Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      return 'U'; // Default for User
    }

    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // You'll need to implement updateProfile method in your AuthProvider
      final success = await authProvider.updateProfile(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dob:
            _formatDOB(), // Format the DOB from separate fields (now just month/year)
      );

      if (success) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Text('Password change feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action will permanently:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Delete all your chat history',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  Text(
                    '• Remove your profile data',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  Text(
                    '• Cannot be undone',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange.shade600),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobMonthController.dispose();
    _dobDayController.dispose();
    _dobYearController.dispose();
    super.dispose();
  }
}
