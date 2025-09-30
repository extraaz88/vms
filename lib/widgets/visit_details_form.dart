import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../core/providers/location_provider.dart';

class VisitDetailsForm extends StatefulWidget {
  final Function(String place, String person, String reason, String? area, File? photo) onSubmit;
  final VoidCallback? onCancel;
  final String? initialPlace;
  final String? initialPerson;
  final String? initialReason;
  final String? initialArea;
  final File? initialPhoto;

  const VisitDetailsForm({
    super.key,
    required this.onSubmit,
    this.onCancel,
    this.initialPlace,
    this.initialPerson,
    this.initialReason,
    this.initialArea,
    this.initialPhoto,
  });

  @override
  State<VisitDetailsForm> createState() => _VisitDetailsFormState();
}

class _VisitDetailsFormState extends State<VisitDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _personController = TextEditingController();
  final _reasonController = TextEditingController();
  final _areaController = TextEditingController();
  File? _selectedPhoto;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _placeController.text = widget.initialPlace ?? '';
    _personController.text = widget.initialPerson ?? '';
    _reasonController.text = widget.initialReason ?? '';
    _areaController.text = widget.initialArea ?? '';
    _selectedPhoto = widget.initialPhoto;
    
    // Auto-fetch area from location
    _fetchCurrentArea();
  }

  @override
  void dispose() {
    _placeController.dispose();
    _personController.dispose();
    _reasonController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Visit Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Visiting Area Field (Auto-fetched, Read-only)
            TextFormField(
              controller: _areaController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Visiting Area',
                hintText: 'Auto-detected from your location',
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: _isLoadingLocation 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.location_searching),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            
            // Visiting Place Field
            TextFormField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: 'Visiting Place',
                hintText: 'Enter the place you are visiting',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter visiting place';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Photo Field
            _buildPhotoField(),
            const SizedBox(height: 16),
            
            // Visiting Person Field
            TextFormField(
              controller: _personController,
              decoration: InputDecoration(
                labelText: 'Visiting Person',
                hintText: 'Enter the person you are meeting',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter visiting person';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Visiting Reason Field
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Visiting Reason',
                hintText: 'Enter the reason for your visit',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter visiting reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Save Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _placeController.text.trim(),
        _personController.text.trim(),
        _reasonController.text.trim(),
        _areaController.text.trim(),
        _selectedPhoto,
      );
    }
  }

  Future<void> _fetchCurrentArea() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.getCurrentLocation();
      
      if (locationProvider.currentPosition != null) {
        // Simulate area detection (in real app, use reverse geocoding)
        final area = await _getAreaFromCoordinates(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        
        setState(() {
          _areaController.text = area;
        });
      }
    } catch (e) {
      setState(() {
        _areaController.text = 'Unable to detect area';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<String> _getAreaFromCoordinates(double lat, double lng) async {
    // Simulate reverse geocoding - in real app, use Google Maps API or similar
    await Future.delayed(const Duration(seconds: 2));
    
    // More precise area detection based on exact coordinates
    String area = '';
    
    // Delhi area detection
    if (lat >= 28.4 && lat <= 28.9 && lng >= 76.8 && lng <= 77.4) {
      if (lat >= 28.6 && lat <= 28.7 && lng >= 77.1 && lng <= 77.3) {
        area = 'Central Delhi, New Delhi';
      } else if (lat >= 28.5 && lat <= 28.6 && lng >= 77.0 && lng <= 77.2) {
        area = 'South Delhi, New Delhi';
      } else if (lat >= 28.6 && lat <= 28.8 && lng >= 77.0 && lng <= 77.1) {
        area = 'North Delhi, New Delhi';
      } else if (lat >= 28.4 && lat <= 28.6 && lng >= 77.1 && lng <= 77.4) {
        area = 'East Delhi, New Delhi';
      } else if (lat >= 28.5 && lat <= 28.7 && lng >= 76.8 && lng <= 77.0) {
        area = 'West Delhi, New Delhi';
      } else {
        area = 'New Delhi, India';
      }
    }
    // Mumbai area detection
    else if (lat >= 18.9 && lat <= 19.3 && lng >= 72.7 && lng <= 73.1) {
      if (lat >= 19.0 && lat <= 19.1 && lng >= 72.8 && lng <= 72.9) {
        area = 'South Mumbai, Maharashtra';
      } else if (lat >= 19.1 && lat <= 19.2 && lng >= 72.8 && lng <= 73.0) {
        area = 'Central Mumbai, Maharashtra';
      } else if (lat >= 19.2 && lat <= 19.3 && lng >= 72.8 && lng <= 73.0) {
        area = 'North Mumbai, Maharashtra';
      } else if (lat >= 19.0 && lat <= 19.2 && lng >= 73.0 && lng <= 73.1) {
        area = 'East Mumbai, Maharashtra';
      } else {
        area = 'Mumbai, Maharashtra, India';
      }
    }
    // Bangalore area detection
    else if (lat >= 12.8 && lat <= 13.2 && lng >= 77.4 && lng <= 77.8) {
      if (lat >= 12.9 && lat <= 13.0 && lng >= 77.5 && lng <= 77.7) {
        area = 'Central Bangalore, Karnataka';
      } else if (lat >= 12.8 && lat <= 12.9 && lng >= 77.5 && lng <= 77.7) {
        area = 'South Bangalore, Karnataka';
      } else if (lat >= 13.0 && lat <= 13.1 && lng >= 77.5 && lng <= 77.7) {
        area = 'North Bangalore, Karnataka';
      } else if (lat >= 12.9 && lat <= 13.1 && lng >= 77.7 && lng <= 77.8) {
        area = 'East Bangalore, Karnataka';
      } else {
        area = 'Bangalore, Karnataka, India';
      }
    }
    // Chennai area detection
    else if (lat >= 12.9 && lat <= 13.2 && lng >= 80.1 && lng <= 80.4) {
      area = 'Chennai, Tamil Nadu, India';
    }
    // Kolkata area detection
    else if (lat >= 22.4 && lat <= 22.7 && lng >= 88.2 && lng <= 88.5) {
      area = 'Kolkata, West Bengal, India';
    }
    // Hyderabad area detection
    else if (lat >= 17.3 && lat <= 17.5 && lng >= 78.3 && lng <= 78.6) {
      area = 'Hyderabad, Telangana, India';
    }
    // Pune area detection
    else if (lat >= 18.4 && lat <= 18.6 && lng >= 73.7 && lng <= 74.0) {
      area = 'Pune, Maharashtra, India';
    }
    // Ahmedabad area detection
    else if (lat >= 23.0 && lat <= 23.1 && lng >= 72.5 && lng <= 72.7) {
      area = 'Ahmedabad, Gujarat, India';
    }
    // Jaipur area detection
    else if (lat >= 26.8 && lat <= 27.0 && lng >= 75.7 && lng <= 75.9) {
      area = 'Jaipur, Rajasthan, India';
    }
    // Default case with exact coordinates
    else {
      area = 'Area ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    
    return area;
  }

  Widget _buildPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Place Photo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedPhoto != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          _selectedPhoto!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhoto = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to take photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    // Directly open camera when tapped
    _pickImage('camera');
  }

  Future<void> _pickImage(String source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo captured successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing photo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
