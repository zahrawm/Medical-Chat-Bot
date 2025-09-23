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
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _dobDayController = TextEditingController();
  final _dobYearController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedMonth;

  // List of months for the dropdown
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _usernameController.text = authProvider.user?.username ?? '';
    _firstNameController.text = authProvider.user?.firstName ?? '';
    _lastNameController.text = authProvider.user?.lastName ?? '';
    _emailController.text = authProvider.user?.email ?? '';

    // Parse existing DOB if available
    final dob = authProvider.user?.dob ?? '';
    if (dob.isNotEmpty) {
      _parseDOB(dob);
    } else {
      // Set default date
      _selectedDate = DateTime(2002, 5, 5);
      _dobDayController.text = '05';
      _selectedMonth = 'May';
      _dobYearController.text = '2002';
    }
  }

  void _parseDOB(String dob) {
    try {
      DateTime parsedDate;

      // Try different date formats
      if (dob.contains('/')) {
        final parts = dob.split('/');
        if (parts.length == 3) {
          // MM/DD/YYYY or DD/MM/YYYY
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else if (parts.length == 2) {
          // MM/YYYY
          parsedDate = DateTime(int.parse(parts[1]), int.parse(parts[0]), 1);
        } else {
          return;
        }
      } else if (dob.contains('-')) {
        final parts = dob.split('-');
        if (parts.length >= 2) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            parsedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              parts.length > 2 ? int.parse(parts[2]) : 1,
            );
          } else {
            // MM-DD-YYYY or MM-YYYY
            parsedDate = DateTime(
              int.parse(parts[parts.length - 1]),
              int.parse(parts[0]),
              parts.length > 2 ? int.parse(parts[1]) : 1,
            );
          }
        } else {
          return;
        }
      } else {
        return;
      }

      _selectedDate = parsedDate;
      _updateDateControllers();
    } catch (e) {
      // If parsing fails, set default date
      _selectedDate = DateTime(2002, 5, 5);
      _updateDateControllers();
    }
  }

  void _updateDateControllers() {
    if (_selectedDate != null) {
      _dobDayController.text = _selectedDate!.day.toString().padLeft(2, '0');
      _selectedMonth = _getMonthName(_selectedDate!.month);
      _dobYearController.text = _selectedDate!.year.toString();
    }
  }

  void _updateSelectedDate() {
    try {
      final day = int.tryParse(_dobDayController.text);
      final year = int.tryParse(_dobYearController.text);

      if (day != null && year != null && _selectedMonth != null) {
        // Get month number from selected month name
        final monthIndex = _months.indexOf(_selectedMonth!) + 1;

        setState(() {
          _selectedDate = DateTime(year, monthIndex, day);
        });
      }
    } catch (e) {
      // Ignore parsing errors during typing
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2002, 5, 5),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'OK',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateControllers();
      });
    }
  }

  String _formatDOB() {
    if (_selectedDate != null) {
      return '${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Profile Avatar and Info
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${_firstNameController.text} ${_lastNameController.text}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First Name and Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            'First Name',
                            _firstNameController,
                            Icons.person_outline,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            'Last Name',
                            _lastNameController,
                            Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Phone Number
                    _buildFormField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone_outlined,
                      placeholder: 'Enter phone number',
                    ),
                    SizedBox(height: 16),

                    // Date of Birth - Updated with dropdown for month
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Day field
                            SizedBox(width: 12),
                            // Month dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                hint: Text(
                                  'Month',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 2,
                                    ),
                                  ),
                                  fillColor: Colors.grey.shade50,
                                  filled: true,
                                ),
                                items: _months.map((String month) {
                                  return DropdownMenuItem<String>(
                                    value: month,
                                    child: Text(month),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                    _updateSelectedDate();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _dobDayController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: InputDecoration(
                                  hintText: 'DD',
                                  counterText: '',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 2,
                                    ),
                                  ),
                                  fillColor: Colors.grey.shade50,
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final day = int.tryParse(value);
                                  if (day == null || day < 1 || day > 31) {
                                    return 'Invalid day';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.length <= 2) {
                                    _updateSelectedDate();
                                  }
                                },
                              ),
                            ),

                            SizedBox(width: 12),
                            // Year field
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _dobYearController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                decoration: InputDecoration(
                                  hintText: 'YYYY',
                                  counterText: '',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 2,
                                    ),
                                  ),
                                  fillColor: Colors.grey.shade50,
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final year = int.tryParse(value);
                                  if (year == null ||
                                      year < 1900 ||
                                      year > DateTime.now().year) {
                                    return 'Invalid year';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.length <= 4) {
                                    _updateSelectedDate();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Occupation
                    _buildFormField(
                      'Occupation',
                      _occupationController,
                      Icons.work_outline,
                      placeholder: 'Enter occupation',
                    ),
                    SizedBox(height: 32),

                    // Account Info
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Account Type:', 'User'),
                          SizedBox(height: 8),
                          _buildInfoRow('Username:', _usernameController.text),
                          SizedBox(height: 8),
                          _buildInfoRow('Member since:', '8/30/2025'),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder ?? controller.text,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      return 'ZA'; // Default initials
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
        dob: _formatDOB(),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _dobDayController.dispose();
    _dobYearController.dispose();
    super.dispose();
  }
}
