import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'telecalling_report_model.dart';

class TelecallingAddReportScreen extends StatefulWidget {
  const TelecallingAddReportScreen({super.key});

  @override
  State<TelecallingAddReportScreen> createState() =>
      _TelecallingAddReportScreenState();
}

class _TelecallingAddReportScreenState
    extends State<TelecallingAddReportScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  final _totalCallsController = TextEditingController();
  final _ringingController = TextEditingController();
  final _notConnectedController = TextEditingController();
  final _invalidNumberController = TextEditingController();
  final _notRequiredController = TextEditingController();
  final _notInterestedController = TextEditingController();
  final _whatsappPdfController = TextEditingController();

  @override
  void dispose() {
    _totalCallsController.dispose();
    _ringingController.dispose();
    _notConnectedController.dispose();
    _invalidNumberController.dispose();
    _notRequiredController.dispose();
    _notInterestedController.dispose();
    _whatsappPdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        title: const Text(
          'Add Daily Report',
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
                _buildLabel(context, 'Date *'),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _buildTextField(
                      context,
                      hint: _selectedDate == null
                          ? 'Date'
                          : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                '${_selectedDate!.year}',
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Total Calls'),
                _buildTextField(
                  context,
                  controller: _totalCallsController,
                  hint: 'Enter total calls',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Ringing (Not Answered)'),
                _buildTextField(
                  context,
                  controller: _ringingController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Not Connected'),
                _buildTextField(
                  context,
                  controller: _notConnectedController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Invalid Number'),
                _buildTextField(
                  context,
                  controller: _invalidNumberController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Not Required'),
                _buildTextField(
                  context,
                  controller: _notRequiredController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'Not Interested'),
                _buildTextField(
                  context,
                  controller: _notInterestedController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing),
                _buildLabel(context, 'WhatsApp PDF Sent'),
                _buildTextField(
                  context,
                  controller: _whatsappPdfController,
                  hint: 'Enter count',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing * 1.5),
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryButton(
                        context,
                        'Cancel',
                        () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildPrimaryButton(context, 'Save', _handleSave),
                    ),
                  ],
                ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildPrimaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 16),
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
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    final report = TelecallingDailyReport(
      date: _selectedDate!,
      totalCalls: int.tryParse(_totalCallsController.text.trim()) ?? 0,
      ringing: int.tryParse(_ringingController.text.trim()) ?? 0,
      notConnected: int.tryParse(_notConnectedController.text.trim()) ?? 0,
      invalidNumber: int.tryParse(_invalidNumberController.text.trim()) ?? 0,
      notRequired: int.tryParse(_notRequiredController.text.trim()) ?? 0,
      notInterested: int.tryParse(_notInterestedController.text.trim()) ?? 0,
      whatsappPdfSent: int.tryParse(_whatsappPdfController.text.trim()) ?? 0,
    );

    Navigator.pop(context, report);
  }
}
