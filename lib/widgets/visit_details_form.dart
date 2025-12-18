import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../core/providers/location_provider.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';
import '../services/sales/lead_dropdown_service.dart';

class VisitDetailsForm extends StatefulWidget {
  final Function(
    String place,
    String person,
    String reason,
    String? area,
    File? photo,
    Lead? selectedLead,
  )
  onSubmit;
  final VoidCallback? onCancel;
  final String? initialPlace;
  final String? initialPerson;
  final String? initialReason;
  final String? initialArea;
  final File? initialPhoto;
  final Lead? selectedLead;
  final List<Lead> leads;
  final bool isLoadingLeads;
  final VoidCallback? onRefreshLeads;

  const VisitDetailsForm({
    super.key,
    required this.onSubmit,
    this.onCancel,
    this.initialPlace,
    this.initialPerson,
    this.initialReason,
    this.initialArea,
    this.initialPhoto,
    this.selectedLead,
    this.leads = const [],
    this.isLoadingLeads = false,
    this.onRefreshLeads,
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
  final _connectingTimeController = TextEditingController();
  File? _selectedPhoto;
  bool _isSubmitting = false;
  Lead? _selectedLead;
  String? _selectedStatus;
  TimeOfDay? _connectingTime;
  String? _photoError;

  // API data for status dropdown
  List<String> _statusList = [];
  bool _isLoadingStatus = true;

  bool get _shouldShowConnectingTime => _isStatusRequiringTime(_selectedStatus);

  bool _isStatusRequiringTime(String? status) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return normalized.contains('in process') ||
        normalized.contains('demo pending');
  }

  void _clearConnectingTime() {
    _connectingTime = null;
    _connectingTimeController.clear();
  }

  @override
  void initState() {
    super.initState();

    // If a lead is preselected and leads list is available, find the matching lead from the list
    // This ensures reference equality for the dropdown
    if (widget.selectedLead != null && widget.leads.isNotEmpty) {
      try {
        _selectedLead = widget.leads.firstWhere(
          (lead) => lead.id == widget.selectedLead!.id,
        );
        debugPrint(
          '✅ Found preselected lead in initState: ${_selectedLead!.name}',
        );
      } catch (e) {
        // Lead not found in list, use the widget's selectedLead
        _selectedLead = widget.selectedLead;
        debugPrint('⚠️ Preselected lead not in leads list during initState');
      }
    } else {
      _selectedLead = widget.selectedLead;
    }

    // Auto-fill visiting place if lead is preselected
    // Priority: Address > Name (company removed)
    if (_selectedLead != null) {
      String visitingPlace = '';
      if (_selectedLead!.address != null &&
          _selectedLead!.address!.trim().isNotEmpty) {
        visitingPlace = _selectedLead!.address!.trim();
      } else {
        visitingPlace = _selectedLead!.name;
      }

      // Always use auto-filled value from lead if lead is preselected
      // This ensures drawer navigation always auto-fills properly
      _placeController.text = visitingPlace;
      _personController.text = _selectedLead!.name;
    } else {
      // Only use initialPlace if no lead is preselected
      _placeController.text = widget.initialPlace ?? '';
      _personController.text = widget.initialPerson ?? '';
    }

    _reasonController.text = widget.initialReason ?? '';
    _areaController.text = widget.initialArea ?? '';
    _selectedPhoto = widget.initialPhoto;

    // Auto-fetch area from location
    _fetchCurrentArea();

    // Load status dropdown from API
    _loadStatusDropdown();
  }

  // Load status dropdown from API
  Future<void> _loadStatusDropdown() async {
    try {
      setState(() {
        _isLoadingStatus = true;
      });

      // Clear cache to get fresh data
      LeadDropdownService.clearCache();

      // Load status list from API
      final statusList = await LeadDropdownService.getLeadStatusList();

      setState(() {
        _statusList = statusList;
        if (_statusList.isNotEmpty) {
          _selectedStatus = _statusList.first;
        }
        _isLoadingStatus = false;
        if (!_shouldShowConnectingTime) {
          _clearConnectingTime();
        }
      });

      debugPrint('✅ Status dropdown loaded: $_statusList');
    } catch (e) {
      debugPrint('❌ Error loading status dropdown: $e');
      setState(() {
        // Use fallback data
        _statusList = [
          'New',
          'Assigned',
          'In Process',
          'Converted',
          'Recycled',
          'Dead',
        ];
        if (_statusList.isNotEmpty) {
          _selectedStatus = _statusList.first;
        }
        _isLoadingStatus = false;
        if (!_shouldShowConnectingTime) {
          _clearConnectingTime();
        }
      });
    }
  }

  @override
  void didUpdateWidget(VisitDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update selected lead if widget's selectedLead changed
    if (widget.selectedLead != oldWidget.selectedLead) {
      setState(() {
        _selectedLead = widget.selectedLead;

        // Auto-fill visiting place when lead is updated
        // Priority: Address > Name (company removed)
        if (widget.selectedLead != null) {
          String visitingPlace = '';
          if (widget.selectedLead!.address != null &&
              widget.selectedLead!.address!.trim().isNotEmpty) {
            visitingPlace = widget.selectedLead!.address!.trim();
          } else {
            visitingPlace = widget.selectedLead!.name;
          }

          // Only auto-fill if place field is empty or was previously auto-filled
          if (_placeController.text.isEmpty ||
              _placeController.text == oldWidget.selectedLead?.address ||
              _placeController.text == oldWidget.selectedLead?.name) {
            _placeController.text = visitingPlace;
          }

          // Auto-fill visiting person
          if (_personController.text.isEmpty ||
              _personController.text == oldWidget.selectedLead?.name) {
            _personController.text = widget.selectedLead!.name;
          }
        }
      });
    }

    // Handle when leads list changes
    if (widget.leads.length != oldWidget.leads.length) {
      debugPrint(
        '📋 Leads list updated: ${oldWidget.leads.length} -> ${widget.leads.length} leads available',
      );
    }

    // If widget has a selectedLead and it's in the leads list, use it
    // This handles both cases: when leads list updates and when selectedLead changes
    if (widget.selectedLead != null && widget.leads.isNotEmpty) {
      if (widget.leads.any((lead) => lead.id == widget.selectedLead!.id)) {
        // Find the actual lead object from the list (to ensure reference equality)
        final leadFromList = widget.leads.firstWhere(
          (lead) => lead.id == widget.selectedLead!.id,
        );
        if (_selectedLead?.id != leadFromList.id) {
          debugPrint(
            '✅ Setting selected lead from widget: ${leadFromList.name}',
          );
          setState(() {
            _selectedLead = leadFromList;
          });
        }
      } else {
        debugPrint(
          '⚠️ Widget selectedLead not in leads list: ${widget.selectedLead!.name}',
        );
      }
    }

    // If current selected lead is not in the new leads list, clear it
    if (_selectedLead != null &&
        widget.leads.isNotEmpty &&
        !widget.leads.any((lead) => lead.id == _selectedLead!.id)) {
      debugPrint(
        '⚠️ Current selected lead not in new list, clearing selection',
      );
      setState(() {
        _selectedLead = null;
      });
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _personController.dispose();
    _reasonController.dispose();
    _areaController.dispose();
    _connectingTimeController.dispose();
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
            // Section Title
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Visit Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assigned Lead Dropdown
            _buildLeadDropdown(),
            const SizedBox(height: 16),

            // Visiting Place Field
            TextFormField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: 'Visiting Place',
                hintText: 'Enter the place you are visiting',
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

            // Status Dropdown Field (from API)
            _isLoadingStatus
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading status...'),
                        ],
                      ),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      hintText: 'Select status',
                      prefixIcon: const Icon(Icons.check_circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    items: _statusList.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                        if (!_isStatusRequiringTime(newValue)) {
                          _clearConnectingTime();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a status';
                      }
                      return null;
                    },
                  ),
            if (_shouldShowConnectingTime) ...[
              const SizedBox(height: 16),
              _buildConnectingTimeField(),
            ],
            const SizedBox(height: 16),

            // Remark Field
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remark',
                hintText: 'Enter the remark for your visit',
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
                  return 'Please enter remark';
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
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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

  void _submitForm() async {
    // Validate photo field
    setState(() {
      if (_selectedPhoto == null) {
        _photoError = 'Please capture a photo';
      } else {
        _photoError = null;
      }
    });

    // Validate all form fields including photo
    if (_formKey.currentState!.validate() && _selectedPhoto != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final locationProvider = context.read<LocationProvider>();

        // Ensure we have location data
        if (locationProvider.currentPosition == null) {
          await locationProvider.getCurrentLocation();
        }

        if (locationProvider.currentPosition == null) {
          throw Exception('Unable to get current location');
        }

        final apiService = ApiService();
        final connectingTimeValue = _shouldShowConnectingTime
            ? _connectingTimeController.text.trim()
            : null;

        // Prepare photo path if available
        String? photoPath;
        if (_selectedPhoto != null) {
          // In a real app, you would upload the photo to a server and get the path
          photoPath = _selectedPhoto!.path;
        }

        // Call the API to create visit details
        final result = await apiService.createVisitDetails(
          visitingPlace: _placeController.text.trim(),
          visitingPerson: _personController.text.trim(),
          visitingReason: _reasonController.text.trim(),
          visitingArea: _areaController.text.trim().isEmpty
              ? null
              : _areaController.text.trim(),
          photoPath: photoPath,
          leadId: _selectedLead?.id,
          leadName: _selectedLead?.name,
          leadEmail: _selectedLead?.email,
          leadPhone: _selectedLead?.phone,
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          connectingTime:
              (connectingTimeValue != null && connectingTimeValue.isNotEmpty)
              ? connectingTimeValue
              : null,
          status: _selectedStatus,
        );

        if (result['status'] == 'success') {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Visit details saved successfully!',
                ),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }

          // Call the original onSubmit callback with the data
          widget.onSubmit(
            _placeController.text.trim(),
            _personController.text.trim(),
            _reasonController.text.trim(),
            _areaController.text.trim(),
            _selectedPhoto,
            _selectedLead,
          );

          // Clear the form after successful submission
          _clearForm();
        } else {
          throw Exception(result['message'] ?? 'Failed to save visit details');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _fetchCurrentArea() async {
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
        Row(
          children: [
            Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Visit Place Photo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: _photoError != null
                    ? AppTheme.errorColor
                    : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.values[1], // Dashed border
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
                              _photoError = null;
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showImagePickerOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Browse files'),
                      ),
                    ],
                  ),
          ),
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 8),
          Text(
            _photoError!,
            style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ],
      ],
    );
  }

  void _showImagePickerOptions() {
    // Directly open camera when tapped
    _pickImage('camera');
  }

  Widget _buildConnectingTimeField() {
    return TextFormField(
      controller: _connectingTimeController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Connecting Time',
        hintText: 'Select connecting time',
        prefixIcon: const Icon(Icons.access_time),
        suffixIcon: IconButton(
          icon: const Icon(Icons.schedule),
          onPressed: _pickConnectingTime,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: (value) {
        if (_shouldShowConnectingTime &&
            (value == null || value.trim().isEmpty)) {
          return 'Please select connecting time';
        }
        return null;
      },
      onTap: _pickConnectingTime,
    );
  }

  Future<void> _pickConnectingTime() async {
    final initialTime = _connectingTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _connectingTime = picked;
        _connectingTimeController.text = picked.format(context);
      });
    }
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
          _photoError = null; // Clear error when photo is selected
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

  Widget _buildLeadDropdown() {
    // Debug: Log current state
    debugPrint(
      '🔄 Building lead dropdown - Loading: ${widget.isLoadingLeads}, Leads count: ${widget.leads.length}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Assigned Lead',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.leads.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: widget.isLoadingLeads
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading assigned leads...'),
                          ],
                        ),
                      ),
                    )
                  : widget.leads.isEmpty
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No assigned leads available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<Lead>(
                      key: ValueKey(
                        'leads_dropdown_${widget.leads.length}_${_selectedLead?.id ?? 'none'}',
                      ),
                      value:
                          _selectedLead != null &&
                              widget.leads.any(
                                (lead) => lead.id == _selectedLead!.id,
                              )
                          ? widget.leads.firstWhere(
                              (lead) => lead.id == _selectedLead!.id,
                            )
                          : null,
                      isExpanded: true,
                      menuMaxHeight: 300,
                      selectedItemBuilder: (BuildContext context) {
                        // Return widget for each lead - the one at selected index will be shown
                        return widget.leads.map<Widget>((Lead lead) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                lead.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      decoration: InputDecoration(
                        hintText: 'Select lead',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      items: widget.leads.map((lead) {
                        return DropdownMenuItem<Lead>(
                          value: lead,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lead.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (lead.address != null &&
                                    lead.address!.trim().isNotEmpty)
                                  Text(
                                    lead.address!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                Text(
                                  lead.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: widget.isLoadingLeads
                          ? null
                          : (Lead? newValue) {
                              setState(() {
                                _selectedLead = newValue;
                                if (newValue != null) {
                                  // Auto-fill visiting place with proper priority:
                                  // 1. Address (if available)
                                  // 2. Lead name (fallback)
                                  String visitingPlace = '';
                                  if (newValue.address != null &&
                                      newValue.address!.trim().isNotEmpty) {
                                    visitingPlace = newValue.address!.trim();
                                  } else {
                                    visitingPlace = newValue.name;
                                  }
                                  _placeController.text = visitingPlace;

                                  // Auto-fill visiting person with lead name
                                  _personController.text = newValue.name;
                                }
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a lead to visit';
                        }
                        return null;
                      },
                    ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                context.push('/leads/create');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('+ New Lead'),
            ),
          ],
        ),
      ],
    );
  }

  // Clear all form fields and reset state
  void _clearForm() {
    setState(() {
      _placeController.clear();
      _personController.clear();
      _reasonController.clear();
      _areaController.clear();
      _selectedPhoto = null;
      _selectedLead = null;
      _selectedStatus = null;
      _clearConnectingTime();
      _photoError = null;
    });
  }
}
