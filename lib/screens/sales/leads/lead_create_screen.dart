import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vms/core/providers/lead_provider.dart';
import 'package:vms/core/theme/app_theme.dart';
import 'package:vms/models/lead_model.dart';
import 'package:vms/utils/auth_helper.dart';
import 'package:vms/utils/responsive_utils.dart';
import 'package:vms/utils/validation_utils.dart';
import 'package:vms/widgets/custom_button.dart';
import 'package:vms/widgets/custom_text_field.dart';
import '../../../services/sales/lead_dropdown_service.dart';
import 'package:flutter/services.dart';

class LeadCreateScreen extends StatefulWidget {
  const LeadCreateScreen({super.key});

  @override
  State<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends State<LeadCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _opportunityAmountController = TextEditingController();
  // final _assignedUserController = TextEditingController(); // Commented out - assigned user field removed
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'New';
  String _selectedSource = 'Cold Calling';
  String _selectedIndustry = 'Sales';

  // API data
  List<String> _statusList = [];
  Map<String, String> _sourceMap = {};
  bool _isLoadingDropdowns = true;
  final List<String> _productOptions = ['SPOS', 'BharatBill', 'EPOS'];
  String _selectedProduct = 'SPOS';
  bool _showAdditionalFields = false;

  final List<String> _industries = [
    'Sales',
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Real Estate',
    'Consulting',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _countryController.text = 'India';
    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _opportunityAmountController.dispose();
    // _assignedUserController.dispose(); // Commented out - assigned user field removed
    _descriptionController.dispose();
    super.dispose();
  }

  // Load dropdown data from API
  Future<void> _loadDropdownData() async {
    try {
      print('\n📋 LEAD CREATE SCREEN: Loading dropdown data...');

      setState(() {
        _isLoadingDropdowns = true;
      });

      // Clear cache to get fresh data from backend
      LeadDropdownService.clearCache();
      print('🗑️ Cache cleared - fetching fresh data from backend');

      // Get authenticated user ID (created_by)
      final createdBy = await AuthHelper.getAuthenticatedUserId();

      print('🔑 Lead Create - Authenticated User ID (created_by): $createdBy');

      // Load status and source data in parallel
      final results = await Future.wait([
        LeadDropdownService.getLeadStatusList(),
        LeadDropdownService.getLeadSourceMap(createdBy),
      ]);

      print('\n✅ DROPDOWN DATA LOADED:');
      print('Status List: ${results[0]}');
      print('Source Map: ${results[1]}');
      print(
        'Source Map Values: ${(results[1] as Map<String, String>).values.toList()}',
      );

      setState(() {
        _statusList = results[0] as List<String>;
        _sourceMap = results[1] as Map<String, String>;

        print('\n📊 SETTING DROPDOWN VALUES IN STATE:');
        print('Status List Count: ${_statusList.length}');
        print('Status List Items: $_statusList');
        print('Source Map Count: ${_sourceMap.length}');
        print('Source Map Items: $_sourceMap');
        print('Source Map Values: ${_sourceMap.values.toList()}');

        // Set default values from API data
        if (_statusList.isNotEmpty) {
          _selectedStatus = _statusList.first;
          print('✅ Default Status Set: $_selectedStatus');
          print('✅ All Status Values in Dropdown: $_statusList');
        } else {
          print('⚠️ Status List is EMPTY! Using fallback.');
          _statusList = [
            'New',
            'Assigned',
            'In Process',
            'Converted',
            'Recycled',
            'Dead',
          ];
          _selectedStatus = 'New';
        }

        if (_sourceMap.isNotEmpty) {
          _selectedSource = _sourceMap.values.first;
          print('✅ Default Source Set: $_selectedSource');
          print(
            '✅ All Source Values in Dropdown: ${_sourceMap.values.toList()}',
          );
        } else {
          print('⚠️ Source Map is EMPTY! Using fallback.');
          _sourceMap = {
            "1": "Website",
            "2": "Social media",
            "3": "Google",
            "4": "Refferal",
            "5": "partner",
            "8": "Other",
          };
          _selectedSource = 'Website';
        }

        _isLoadingDropdowns = false;
        print('\n✅ Dropdown loading complete!');
        print('🔍 Final _statusList value: $_statusList');
        print('🔍 _isLoadingDropdowns: $_isLoadingDropdowns\n');
      });
    } catch (e, stackTrace) {
      print('\n❌ ERROR LOADING DROPDOWNS:');
      print('Error: $e');
      print('Stack Trace: $stackTrace');

      setState(() {
        // Use fallback data on error
        _statusList = [
          'New',
          'Assigned',
          'In Process',
          'Converted',
          'Recycled',
          'Dead',
        ];
        _sourceMap = {
          "1": "Cold Calling",
          "2": "Referral",
          "3": "contact",
          "4": "blueprint",
          "5": "partner",
        };
        _selectedStatus = 'New';
        _selectedSource = 'Cold Calling';
        _isLoadingDropdowns = false;
      });

      print('⚠️ Using fallback dropdown data\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lead'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  _buildResponsiveHeader(context),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  _buildResponsiveForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveUtils.getResponsiveIconSize(context, 60),
            height: ResponsiveUtils.getResponsiveIconSize(context, 60),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 30),
              ),
            ),
            child: Icon(
              Icons.person_add,
              size: ResponsiveUtils.getResponsiveIconSize(context, 30),
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          Text(
            'Create New Lead',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Text(
            'Fill in the details below to create a new lead',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildResponsiveForm(BuildContext context) {
    return Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsiveSectionTitle(context, 'Primary Details'),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              _buildPrimaryFields(context),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
              ),
              _buildResponsiveSectionTitle(context, 'Description'),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              _buildResponsiveDescriptionField(context),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              _buildAdditionalFieldsToggle(),

              if (_showAdditionalFields) ...[
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                ),
                _buildResponsiveSectionTitle(context, 'Additional Information'),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                _buildResponsivePersonalInfoFields(context),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                ),
                _buildResponsiveSectionTitle(context, 'Address Information'),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                _buildResponsiveAddressFields(context),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                ),
                _buildResponsiveSectionTitle(context, 'Details'),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                _buildResponsiveDetailsFields(context),
              ],

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
              ),
              _buildResponsiveActionButtons(context),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildResponsiveSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
      ),
    );
  }

  Widget _buildPrimaryFields(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Name',
          hint: 'Enter Name',
          prefixIcon: const Icon(Icons.person),
          validator: ValidationUtils.validateName,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter 10 digit phone number',
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.number,
          validator: ValidationUtils.validatePhone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          maxLength: 10,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter Address',
          prefixIcon: const Icon(Icons.location_on),
          validator: ValidationUtils.validateAddress,
          maxLines: 3,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        _buildProductDropdown(context),
      ],
    );
  }

  Widget _buildProductDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: _selectedProduct,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSpacing(context),
              vertical: ResponsiveUtils.getResponsiveSpacing(context),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
          items: _productOptions
              .map(
                (product) => DropdownMenuItem<String>(
                  value: product,
                  child: Text(product),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedProduct = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalFieldsToggle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showAdditionalFields = !_showAdditionalFields;
          });
        },
        icon: Icon(
          _showAdditionalFields
              ? Icons.keyboard_arrow_up
              : Icons.keyboard_arrow_down,
        ),
        label: Text(
          _showAdditionalFields
              ? 'Hide Additional Fields'
              : 'Show Additional Fields',
        ),
      ),
    );
  }

  Widget _buildResponsivePersonalInfoFields(BuildContext context) {
    return Column(
      children: [
        ResponsiveUtils.isMobile(context)
            ? Column(
                children: [
                  CustomTextField(
                    controller: _accountController,
                    label: 'Business Name',
                    hint: '--',
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  CustomTextField(
                    controller: _companyController,
                    label: 'Company',
                    hint: '--',
                    prefixIcon: const Icon(Icons.business),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _accountController,
                      label: 'Business Name',
                      hint: '--',
                      prefixIcon: const Icon(Icons.account_balance),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: _companyController,
                      label: 'Company',
                      hint: '--',
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                ],
              ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        // Email and Designation Row
        ResponsiveUtils.isMobile(context)
            ? Column(
                children: [
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter Email',
                    prefixIcon: const Icon(Icons.email),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Designation',
                    hint: '--',
                    prefixIcon: const Icon(Icons.work),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter Email',
                      prefixIcon: const Icon(Icons.email),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: _titleController,
                      label: 'Designation',
                      hint: '--',
                      prefixIcon: const Icon(Icons.badge),
                    ),
                  ),
                ],
              ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        // Website Row
        CustomTextField(
          controller: _websiteController,
          label: 'Website',
          hint: '--',
          prefixIcon: const Icon(Icons.web),
          keyboardType: TextInputType.url,
          // validator: ValidationUtils.validateWebsite,
        ),
      ],
    );
  }

  Widget _buildResponsiveAddressFields(BuildContext context) {
    return Column(
      children: [
        // City, State Row
        ResponsiveUtils.isMobile(context)
            ? Column(
                children: [
                  CustomTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: '--',
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  CustomTextField(
                    controller: _stateController,
                    label: 'State/Region',
                    hint: '--',
                    prefixIcon: const Icon(Icons.map),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: '--',
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State/Region',
                      hint: '--',
                      prefixIcon: const Icon(Icons.map),
                    ),
                  ),
                ],
              ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        // Postal Code and Country Row
        ResponsiveUtils.isMobile(context)
            ? Column(
                children: [
                  CustomTextField(
                    controller: _postalCodeController,
                    label: 'Postal Code',
                    hint: '--',
                    prefixIcon: const Icon(Icons.local_post_office),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  CustomTextField(
                    controller: _countryController,
                    label: 'Country',
                    hint: '--',
                    prefixIcon: const Icon(Icons.public),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code',
                      hint: '--',
                      prefixIcon: const Icon(Icons.local_post_office),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: _countryController,
                      label: 'Country',
                      hint: '--',
                      prefixIcon: const Icon(Icons.public),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildResponsiveDetailsFields(BuildContext context) {
    return Column(
      children: [
        // Status and Source Row
        ResponsiveUtils.isMobile(context)
            ? Column(
                children: [
                  _buildResponsiveDropdownField(
                    context,
                    label: 'Status',
                    value: _isLoadingDropdowns ? 'Loading...' : _selectedStatus,
                    onTap: _isLoadingDropdowns
                        ? null
                        : () => _showStatusPicker(),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  _buildResponsiveDropdownField(
                    context,
                    label: 'Source',
                    value: _isLoadingDropdowns ? 'Loading...' : _selectedSource,
                    onTap: _isLoadingDropdowns
                        ? null
                        : () => _showSourcePicker(),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildResponsiveDropdownField(
                      context,
                      label: 'Status',
                      value: _isLoadingDropdowns
                          ? 'Loading...'
                          : _selectedStatus,
                      onTap: _isLoadingDropdowns
                          ? null
                          : () => _showStatusPicker(),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: _buildResponsiveDropdownField(
                      context,
                      label: 'Source',
                      value: _isLoadingDropdowns
                          ? 'Loading...'
                          : _selectedSource,
                      onTap: _isLoadingDropdowns
                          ? null
                          : () => _showSourcePicker(),
                    ),
                  ),
                ],
              ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        // Opportunity Amount
        CustomTextField(
          controller: _opportunityAmountController,
          label: 'Opportunity Amount',
          hint: '--',
          prefixIcon: const Icon(Icons.attach_money),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        // Industry Row (Assigned User field commented out)
        _buildResponsiveDropdownField(
          context,
          label: 'Industry',
          value: _selectedIndustry,
          onTap: () => _showIndustryPicker(),
        ),
        // Assigned User field commented out
        // ResponsiveUtils.isMobile(context)
        //     ? Column(
        //         children: [
        //           _buildResponsiveDropdownField(
        //             context,
        //             label: 'Industry',
        //             value: _selectedIndustry,
        //             onTap: () => _showIndustryPicker(),
        //           ),
        //           SizedBox(
        //             height: ResponsiveUtils.getResponsiveSpacing(context),
        //           ),
        //           CustomTextField(
        //             controller: _assignedUserController,
        //             label: 'Assigned User',
        //             hint: '--',
        //             prefixIcon: const Icon(Icons.person_pin),
        //           ),
        //         ],
        //       )
        //     : Row(
        //         children: [
        //           Expanded(
        //             child: _buildResponsiveDropdownField(
        //               context,
        //               label: 'Industry',
        //               value: _selectedIndustry,
        //               onTap: () => _showIndustryPicker(),
        //             ),
        //           ),
        //           SizedBox(
        //             width: ResponsiveUtils.getResponsiveSpacing(context),
        //           ),
        //           Expanded(
        //             child: CustomTextField(
        //               controller: _assignedUserController,
        //               label: 'Assigned User',
        //               hint: '--',
        //               prefixIcon: const Icon(Icons.person_pin),
        //             ),
        //           ),
        //         ],
        //       ),
      ],
    );
  }

  Widget _buildResponsiveDescriptionField(BuildContext context) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Remark',
        hintText: 'Enter remark',
        labelStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        hintStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 8),
          ),
        ),
        alignLabelWithHint: true,
      ),
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      },
    );
  }

  Widget _buildResponsiveActionButtons(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Create Lead',
                  onPressed: _createLead,
                  backgroundColor: AppTheme.primaryColor,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => context.pop(),
                  backgroundColor: Colors.grey.shade300,
                  textColor: Colors.black87,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => context.pop(),
                  backgroundColor: Colors.grey.shade300,
                  textColor: Colors.black87,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
              Expanded(
                child: CustomButton(
                  text: 'Create Lead',
                  onPressed: _createLead,
                  backgroundColor: AppTheme.primaryColor,
                  textColor: Colors.white,
                ),
              ),
            ],
          );
  }

  Widget _buildResponsiveDropdownField(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context),
          vertical: ResponsiveUtils.getResponsiveSpacing(context),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        14,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    print('\n🎯 STATUS DROPDOWN CLICKED!');
    print('Current _statusList: $_statusList');
    print('Current _statusList length: ${_statusList.length}');
    print('Building dropdown with these values...\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _statusList
                      .map(
                        (status) => ListTile(
                          title: Text(
                            status,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                16,
                              ),
                            ),
                          ),
                          selected: status == _selectedStatus,
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker() {
    print('\n🎯 SOURCE DROPDOWN CLICKED!');
    print('Current _sourceMap: $_sourceMap');
    print('Current _sourceMap length: ${_sourceMap.length}');
    print('Source values: ${_sourceMap.values.toList()}');
    print('Building dropdown with these values...\n');

    // Check if source map is empty and reload if needed
    if (_sourceMap.isEmpty) {
      print('⚠️ Source map is empty! Reloading...');
      _loadDropdownData();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Flexible(
              child: _sourceMap.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No sources available. Please refresh.'),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: _sourceMap.values
                            .map(
                              (source) => ListTile(
                                title: Text(
                                  source,
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                          context,
                                          16,
                                        ),
                                  ),
                                ),
                                selected: source == _selectedSource,
                                onTap: () {
                                  setState(() {
                                    _selectedSource = source;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIndustryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Industry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _industries
                      .map(
                        (industry) => ListTile(
                          title: Text(
                            industry,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                16,
                              ),
                            ),
                          ),
                          selected: industry == _selectedIndustry,
                          onTap: () {
                            setState(() {
                              _selectedIndustry = industry;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final leadProvider = context.read<LeadProvider>();

    final lead = Lead.create(
      name: _nameController.text.trim(),
      account: _accountController.text.trim().isEmpty
          ? null
          : _accountController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      status: LeadDropdownService.getStatusFromApiString(_selectedStatus),
      source: LeadDropdownService.getSourceFromApiString(_selectedSource),
      opportunityAmount: _opportunityAmountController.text.trim().isEmpty
          ? null
          : double.tryParse(_opportunityAmountController.text.trim()),
      campaign: _selectedProduct,
      industry: _selectedIndustry,
      // assignedUser: _assignedUserController.text.trim().isEmpty
      //     ? null
      //     : _assignedUserController.text.trim(), // Commented out - assigned user field removed
      assignedUser: null, // Assigned user field removed
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final success = await leadProvider.createLead(lead);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead created successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create lead: ${leadProvider.error}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
