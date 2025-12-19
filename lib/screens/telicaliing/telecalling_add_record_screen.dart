import 'package:flutter/material.dart';

import 'telecalling_record_model.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class TelecallingAddRecordScreen extends StatefulWidget {
  final TelecallingRecord? initialRecord;

  const TelecallingAddRecordScreen({super.key, this.initialRecord});

  @override
  State<TelecallingAddRecordScreen> createState() =>
      _TelecallingAddRecordScreenState();
}

class _TelecallingAddRecordScreenState
    extends State<TelecallingAddRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _leadNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _timeController = TextEditingController();

  String _selectedStatus = 'Follow up';
  String _selectedProductType = 'SPOS';
  DateTime? _selectedDate;

  final List<String> _statusOptions = ['Demo', 'Follow up', 'Closed'];
  final List<String> _productTypes = ['SPOS', 'BPOS', 'EPOS'];

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    if (record != null) {
      _leadNameController.text = record.leadName;
      _businessTypeController.text = record.businessType;
      _locationController.text = record.location;
      _phoneController.text = record.phoneNumber;
      _amountController.text = record.amount;
      _remarkController.text = record.remark;
      _timeController.text = record.time;
      _selectedStatus = record.status;
      if (_productTypes.contains(record.productType)) {
        _selectedProductType = record.productType;
      }
    }
  }

  @override
  void dispose() {
    _leadNameController.dispose();
    _businessTypeController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        title: const Text(
          'Add New Record',
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing),
        child: Form(
          key: _formKey,
          child: Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(context, 'Lead Name *'),
                _buildTextField(
                  context,
                  controller: _leadNameController,
                  hint: 'Enter lead name',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Status *'),
                _buildDropdownField(
                  context,
                  value: _selectedStatus,
                  items: _statusOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Business Type'),
                _buildTextField(
                  context,
                  controller: _businessTypeController,
                  hint: 'Enter business type',
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Product Type'),
                _buildDropdownField(
                  context,
                  value: _selectedProductType,
                  items: _productTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProductType = value);
                    }
                  },
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Location'),
                _buildTextField(
                  context,
                  controller: _locationController,
                  hint: 'Enter location',
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Phone Number'),
                _buildTextField(
                  context,
                  controller: _phoneController,
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Amount'),
                _buildTextField(
                  context,
                  controller: _amountController,
                  hint: 'Enter amount',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),

                _buildLabel(context, 'Remark'),
                _buildTextField(
                  context,
                  controller: _remarkController,
                  hint: 'Add remark',
                  maxLines: 2,
                ),
                SizedBox(height: spacing),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Next Reminder *'),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                context,
                                hint: _selectedDate == null
                                    ? 'Select date'
                                    : '${_selectedDate!.day.toString().padLeft(2, '0')} '
                                          '${_selectedDate!.month.toString().padLeft(2, '0')} ${_selectedDate!.year}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Time *'),
                          _buildTextField(
                            context,
                            controller: _timeController,
                            hint: 'Enter time',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 1.5),

                _buildPrimaryButton(context, 'Save', _handleSave),
                SizedBox(height: spacing * 0.75),
                _buildSecondaryButton(context, 'Cancel', () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    TextEditingController? controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final record = TelecallingRecord(
      leadName: _leadNameController.text.trim(),
      status: _selectedStatus,
      businessType: _businessTypeController.text.trim(),
      productType: _selectedProductType,
      location: _locationController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      amount: _amountController.text.trim(),
      remark: _remarkController.text.trim(),
      nextReminderDate: _selectedDate == null
          ? ''
          : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                '${_selectedDate!.year}',
      time: _timeController.text.trim(),
    );

    Navigator.pop(context, record);
  }
}
