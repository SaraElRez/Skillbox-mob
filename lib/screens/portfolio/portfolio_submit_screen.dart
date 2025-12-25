import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/service.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/scaffold_with_nav.dart';
import '../../services/services_service.dart';
import '../../models/user.dart';

class PortfolioSubmitScreen extends StatefulWidget {
  final int? portfolioId;
  final bool isEdit;

  const PortfolioSubmitScreen({
    super.key,
    this.portfolioId,
    this.isEdit = false,
  });

  @override
  State<PortfolioSubmitScreen> createState() => _PortfolioSubmitScreenState();
}

class _PortfolioSubmitScreenState extends State<PortfolioSubmitScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedinController = TextEditingController();

  List<Service> _services = [];
  final Set<int> _selectedServiceIds = {};
  bool _loadingServices = true;
  bool _loadingExisting = false;
  bool _submitting = false;
  File? _attachment;
  String? _attachmentName;

  int get _workerRoleId {
    final envValue = dotenv.env['WORKER_ROLE_ID'];
    final parsed = int.tryParse(envValue ?? '');
    return parsed ?? 2; // Default to 2 if not set
  }

  @override
  void initState() {
    super.initState();
    _prefillUser();
    _loadExistingIfNeeded().then((_) => _loadServices());
  }

  void _prefillUser() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
    }
  }

  Future<void> _loadServices() async {
    try {
      final list = await ServicesService.getServices();
      if (mounted) {
        setState(() {
          _services = list;
          _loadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('No auth token found. Please log in again.');
      }

      Map<String, dynamic> response;
      if (widget.isEdit && widget.portfolioId != null) {
        response = await ApiService.updatePortfolio(
          token: token,
          portfolioId: widget.portfolioId!,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          linkedin: _linkedinController.text.trim(),
          requestedRoleId: _workerRoleId,
          serviceIds: _selectedServiceIds.toList(),
          attachmentFile: _attachment,
        );
      } else {
        response = await ApiService.submitPortfolio(
          token: token,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          linkedin: _linkedinController.text.trim(),
          requestedRoleId: _workerRoleId,
          serviceIds: _selectedServiceIds.toList(),
          attachmentFile: _attachment,
        );
      }

      setState(() => _submitting = false);

      if (response['success'] == true) {
        // Save pending portfolio id locally (from create response)
        if (!widget.isEdit && response['portfolio_id'] != null) {
          await prefs.setInt('pending_portfolio_id', response['portfolio_id']);
        }

        // Refresh user to pick up role change (worker) if approved immediately.
        try {
          final me = await ApiService.getCurrentUser(token);
          if (!me.containsKey('error')) {
            Provider.of<UserProvider>(context, listen: false)
                .setUser(User.fromJson(me));
          }
        } catch (_) {
          // ignore refresh errors; not critical for submission success
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Portfolio submitted successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ScaffoldWithNav(initialIndex: 0),
            ),
            (route) => false,
          );
        }
      } else {
        final error = response['error'] ??
            response['errors']?.values?.first ??
            'Failed to submit portfolio';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _submitting = false);
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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply to be a Worker'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final emailRegex =
                      RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _linkedinController,
                label: 'LinkedIn (optional)',
                icon: Icons.link,
                keyboardType: TextInputType.url,
                validator: (v) => null,
              ),
              const SizedBox(height: 16),
              _buildAttachmentSection(),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _attachment = file;
        _attachmentName = result.files.single.name;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade400, Colors.cyan.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Become a Worker',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Submit your details to apply as a worker. Our team will review your application.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.cyan.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.cyan.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload CV (PDF)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Attach your CV as a PDF. This helps us review your application faster.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose PDF'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _attachmentName ?? 'No file selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _attachmentName == null
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
              if (_attachment != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _attachment = null;
                      _attachmentName = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No services available to select. You can still submit your application.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Services (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._services.map(
          (service) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedServiceIds.contains(service.id),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedServiceIds.add(service.id);
                } else {
                  _selectedServiceIds.remove(service.id);
                }
              });
            },
            title: Text(service.title),
            subtitle: Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            activeColor: Colors.cyan,
          ),
        ),
      ],
    );
  }

  Future<void> _loadExistingIfNeeded() async {
    if (!widget.isEdit || widget.portfolioId == null) return;
    setState(() => _loadingExisting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No auth token found');

      final response = await ApiService.getPortfolio(
        token: token,
        portfolioId: widget.portfolioId!,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _fullNameController.text = data['full_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _linkedinController.text = data['linkedin'] ?? '';

          final services = data['services'] as List<dynamic>? ?? [];
          _selectedServiceIds
            ..clear()
            ..addAll(services
                .map((s) => s['id'])
                .whereType<int>());

          final attachmentPath = data['attachment_path'] as String?;
          if (attachmentPath != null && attachmentPath.isNotEmpty) {
            _attachmentName = attachmentPath.split('/').last;
          }
        });
      } else {
        final error = response['error'] ?? 'Failed to load portfolio';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading portfolio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }
}

