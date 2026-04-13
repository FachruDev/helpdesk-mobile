import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/models/employee_lookup_model.dart';
import 'package:helpdesk_mobile/states/customer/customer_employee_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/searchable_dropdown.dart';

// Helper class for Request To dropdown
class RequestToOption {
  final String id;
  final String name;
  final bool isOther;

  RequestToOption({required this.id, required this.name, this.isOther = false});

  factory RequestToOption.fromEmployee(EmployeeModel employee) {
    return RequestToOption(
      id: employee.id.toString(),
      name: employee.effectiveName,
      isOther: false,
    );
  }

  factory RequestToOption.other() {
    return RequestToOption(id: 'other', name: 'Other', isOther: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestToOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CustomerCreateTicketScreen extends ConsumerStatefulWidget {
  const CustomerCreateTicketScreen({super.key});

  @override
  ConsumerState<CustomerCreateTicketScreen> createState() =>
      _CustomerCreateTicketScreenState();
}

class _CustomerCreateTicketScreenState
    extends ConsumerState<CustomerCreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _requestToOtherController = TextEditingController();

  EmployeeModel? _selectedEmployee;
  String _selectedSubjectCategory = 'technical_support';
  bool _isRequestToOther = false;
  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;

  // Request To helper
  RequestToOption? _selectedRequestTo;

  @override
  void initState() {
    super.initState();
    // Load employees
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(customerEmployeeProvider.notifier)
          .fetchEmployees(subjectCategory: _selectedSubjectCategory);
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _requestToOtherController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    if (_selectedFiles.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 files allowed'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      final newFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      final remainingSlots = 5 - _selectedFiles.length;

      setState(() {
        _selectedFiles.addAll(newFiles.take(remainingSlots));
      });

      if (newFiles.length > remainingSlots && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $remainingSlots files added (max 5 total)'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedFiles.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 files allowed'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _selectedFiles.add(File(photo.path));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRequestToOther && _requestToOtherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify Request To'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

  final messageText = _messageController.text.trim();
    final response = await ref
        .read(customerTicketProvider.notifier)
        .createTicket(
          subject: _subjectController.text.trim(),
          subjectCategory: _selectedSubjectCategory,
      message: messageText,
          requestToUserId: _isRequestToOther
              ? 'other'
              : (_selectedEmployee?.id.toString() ?? 'other'),
          requestToOther: _isRequestToOther
              ? _requestToOtherController.text.trim()
              : null,
          files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop with true to indicate success
        Navigator.pop(context, true);
      } else {
        final errorText = response.message ?? 'Failed to create ticket';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(customerEmployeeProvider);
    final subjectCategoryOptions = employeeState.subjectCategoryOptions.isNotEmpty
        ? employeeState.subjectCategoryOptions
        : EmployeeLookupModel.defaultSubjectCategoryOptions;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Ticket')),
      body: employeeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        hintText: 'Enter ticket subject',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subject is required';
                        }
                        return null;
                      },
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectCategory,
                      decoration: const InputDecoration(
                        labelText: 'Subject Category *',
                        prefixIcon: Icon(Icons.topic_outlined),
                      ),
                      items: subjectCategoryOptions.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null || value == _selectedSubjectCategory) {
                          return;
                        }

                        setState(() {
                          _selectedSubjectCategory = value;
                          _selectedEmployee = null;
                          _selectedRequestTo = null;
                          _isRequestToOther = false;
                          _requestToOtherController.clear();
                        });

                        await ref
                            .read(customerEmployeeProvider.notifier)
                            .fetchEmployees(subjectCategory: value);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subject category is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Message
                    TextFormField(
                      controller: _messageController,
                      minLines: 6,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        hintText: 'Describe your issue',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Request To - Searchable
                    Builder(
                      builder: (context) {
                        final requestToItems = [
                          ...employeeState.employees.map((e) {
                            print(
                              '👤 [UI] Mapping employee: ${e.name} (ID: ${e.id})',
                            );
                            return RequestToOption.fromEmployee(e);
                          }),
                          RequestToOption.other(),
                        ];
                        print(
                          '📝 [UI] Total Request To items: ${requestToItems.length}',
                        );

                        return SearchableDropdown<RequestToOption>(
                          labelText: 'Request To *',
                          prefixIcon: Icons.person,
                          selectedItem: _selectedRequestTo,
                          items: requestToItems,
                          itemAsString: (option) {
                            print('🏷️ [UI] itemAsString for: ${option.name}');
                            return option.name;
                          },
                          searchHint: 'Search employee...',
                          onChanged: (value) {
                            print(
                              '🔄 [UI] Request To changed to: ${value?.name}',
                            );
                            setState(() {
                              _selectedRequestTo = value;
                              _isRequestToOther = value?.isOther ?? false;
                              if (value != null && !value.isOther) {
                                _selectedEmployee = employeeState.employees
                                    .firstWhere(
                                      (e) => e.id.toString() == value.id,
                                    );
                              } else {
                                _selectedEmployee = null;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) return 'Request to is required';
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Request To Other (conditional)
                    if (_isRequestToOther)
                      TextFormField(
                        controller: _requestToOtherController,
                        decoration: const InputDecoration(
                          labelText: 'Specify Request To *',
                          hintText: 'Enter name or department',
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (_isRequestToOther &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please specify request to';
                          }
                          return null;
                        },
                      ),
                    if (_isRequestToOther) const SizedBox(height: 16),

                    // Attachment Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedFiles.length < 5
                                ? _takePhoto
                                : null,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedFiles.length < 5
                                ? _pickFiles
                                : null,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Files'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_selectedFiles.length}/5 files selected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Selected Files List
                    if (_selectedFiles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Files:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_selectedFiles.length, (index) {
                              final file = _selectedFiles[index];
                              final fileName = file.path.split('/').last;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.insert_drive_file,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _removeFile(index),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 16
                          : 32,
                    ),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                'Create Ticket',
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
}
