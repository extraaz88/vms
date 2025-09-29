import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/lead_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

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
  final _campaignController = TextEditingController();
  final _assignedUserController = TextEditingController();
  final _descriptionController = TextEditingController();

  LeadStatus _selectedStatus = LeadStatus.newLead;
  LeadSource _selectedSource = LeadSource.coldCalling;
  String _selectedIndustry = 'Sales';

  final List<String> _industries = [
    'Sales',
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Real Estate',
    'Marketing',
    'Consulting',
  ];

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
    _campaignController.dispose();
    _assignedUserController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Lead'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person_add,
              size: 30,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create New Lead',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the details to create a new lead',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildPersonalInfoFields(),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Address Information'),
          const SizedBox(height: 16),
          _buildAddressFields(),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Details'),
          const SizedBox(height: 16),
          _buildDetailsFields(),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Description'),
          const SizedBox(height: 16),
          _buildDescriptionField(),
          
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter Name',
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _accountController,
                label: 'Account',
                hint: '--',
                prefixIcon: const Icon(Icons.account_balance),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _companyController,
                label: 'Company',
                hint: 'Enter Company',
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter Email',
                prefixIcon: const Icon(Icons.email),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: 'Enter Phone',
                prefixIcon: const Icon(Icons.phone),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter Title',
                prefixIcon: const Icon(Icons.work),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _websiteController,
          label: 'Website',
          hint: 'Enter Website',
          prefixIcon: const Icon(Icons.web),
        ),
      ],
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Address',
          prefixIcon: const Icon(Icons.location_on),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cityController,
                label: 'City',
                hint: 'City',
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _stateController,
                label: 'State',
                hint: 'State',
                prefixIcon: const Icon(Icons.map),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _postalCodeController,
                label: 'Postal Code',
                hint: 'Postal Code',
                prefixIcon: const Icon(Icons.local_post_office),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _countryController,
                label: 'Country',
                hint: 'Country',
                prefixIcon: const Icon(Icons.public),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Status',
                value: _selectedStatus.displayName,
                onTap: () => _showStatusPicker(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                label: 'Source',
                value: _selectedSource.displayName,
                onTap: () => _showSourcePicker(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _opportunityAmountController,
                label: 'Opportunity Amount',
                hint: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _campaignController,
                label: 'Campaign',
                hint: '--',
                prefixIcon: const Icon(Icons.campaign),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Industry',
                value: _selectedIndustry,
                onTap: () => _showIndustryPicker(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _assignedUserController,
                label: 'Assign User',
                hint: '--',
                prefixIcon: const Icon(Icons.person_pin),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter Description',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancel',
            onPressed: () => context.pop(),
            backgroundColor: Colors.grey.shade300,
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
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

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...LeadStatus.values.map((status) => ListTile(
              title: Text(status.displayName),
              selected: status == _selectedStatus,
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...LeadSource.values.map((source) => ListTile(
              title: Text(source.displayName),
              selected: source == _selectedSource,
              onTap: () {
                setState(() {
                  _selectedSource = source;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showIndustryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Industry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._industries.map((industry) => ListTile(
              title: Text(industry),
              selected: industry == _selectedIndustry,
              onTap: () {
                setState(() {
                  _selectedIndustry = industry;
                });
                Navigator.pop(context);
              },
            )),
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
      account: _accountController.text.trim().isEmpty ? null : _accountController.text.trim(),
      company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      status: _selectedStatus,
      source: _selectedSource,
      opportunityAmount: _opportunityAmountController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_opportunityAmountController.text.trim()),
      campaign: _campaignController.text.trim().isEmpty ? null : _campaignController.text.trim(),
      industry: _selectedIndustry,
      assignedUser: _assignedUserController.text.trim().isEmpty ? null : _assignedUserController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
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
