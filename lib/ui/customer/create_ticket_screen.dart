import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/states/customer/customer_category_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_employee_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';

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

  CategoryModel? _selectedCategory;
  SubCategoryModel? _selectedSubCategory;
  ProjectModel? _selectedProject;
  EmployeeModel? _selectedEmployee;
  String? _selectedEnvatoSupport;
  bool _isRequestToOther = false;
  List<File> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load categories and employees
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerCategoryProvider.notifier).fetchCategories();
      ref.read(customerEmployeeProvider.notifier).fetchEmployees();
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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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

    final success = await ref.read(customerTicketProvider.notifier).createTicket(
          subject: _subjectController.text.trim(),
          categoryId: _selectedCategory!.id,
          message: _messageController.text.trim(),
          requestToUserId: _isRequestToOther
              ? 'other'
              : (_selectedEmployee?.id.toString() ?? 'other'),
          requestToOther: _isRequestToOther
              ? _requestToOtherController.text.trim()
              : null,
          project: _selectedProject?.name,
          subCategory: _selectedSubCategory?.id,
          envatoSupport: _selectedEnvatoSupport,
          files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop with true to indicate success
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create ticket'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(customerCategoryProvider);
    final employeeState = ref.watch(customerEmployeeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ticket'),
      ),
      body: categoryState.isLoading || employeeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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

                    // Category
                    DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categoryState.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        print('\n===== CATEGORY SELECTED =====');
                        print('Category: ${value?.name}');
                        print('Category ID: ${value?.id}');
                        print('SubCategories data: ${value?.subCategories}');
                        print('Projects data: ${value?.projects}');
                        print('hasSubCategories getter: ${value?.hasSubCategories}');
                        print('hasProjects getter: ${value?.hasProjects}');
                        if (value?.subCategories != null) {
                          print('SubCategories length: ${value!.subCategories!.length}');
                          print('SubCategories items: ${value.subCategories!.map((e) => e.name).toList()}');
                        }
                        if (value?.projects != null) {
                          print('Projects length: ${value!.projects!.length}');
                          print('Projects items: ${value.projects!.map((e) => e.name).toList()}');
                        }
                        print('==============================\n');
                        
                        setState(() {
                          _selectedCategory = value;
                          _selectedSubCategory = null;
                          _selectedProject = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Category is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SubCategory (conditional)
                    if (_selectedCategory != null && _selectedCategory!.hasSubCategories)
                      DropdownButtonFormField<SubCategoryModel>(
                        value: _selectedSubCategory,
                        decoration: const InputDecoration(
                          labelText: 'Sub Category *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _selectedCategory!.subCategories!.map((sub) {
                          return DropdownMenuItem(
                            value: sub,
                            child: Text(sub.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubCategory = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedCategory!.hasSubCategories && value == null) {
                            return 'Sub category is required';
                          }
                          return null;
                        },
                      ),
                    if (_selectedCategory != null && _selectedCategory!.hasSubCategories)
                      const SizedBox(height: 16),

                    // Project (conditional)
                    if (_selectedCategory != null && _selectedCategory!.hasProjects)
                      DropdownButtonFormField<ProjectModel>(
                        value: _selectedProject,
                        decoration: const InputDecoration(
                          labelText: 'Project *',
                          prefixIcon: Icon(Icons.work),
                        ),
                        items: _selectedCategory!.projects!.map((project) {
                          return DropdownMenuItem(
                            value: project,
                            child: Text(project.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProject = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedCategory!.hasProjects && value == null) {
                            return 'Project is required';
                          }
                          return null;
                        },
                      ),
                    if (_selectedCategory != null && _selectedCategory!.hasProjects)
                      const SizedBox(height: 16),

                    // Message
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        hintText: 'Describe your issue',
                        prefixIcon: Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Request To
                    DropdownButtonFormField<String>(
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Request To *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        ...employeeState.employees.map((employee) {
                          return DropdownMenuItem(
                            value: employee.id.toString(),
                            child: Text(employee.name),
                          );
                        }),
                        const DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _isRequestToOther = value == 'other';
                          if (value != 'other') {
                            _selectedEmployee = employeeState.employees
                                .firstWhere((e) => e.id.toString() == value);
                          }
                        });
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

                    // Envato Support
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEnvatoSupport,
                      decoration: const InputDecoration(
                        labelText: 'Envato Support',
                        prefixIcon: Icon(Icons.support),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Not Applicable'),
                        ),
                        DropdownMenuItem(
                          value: 'Supported',
                          child: Text('Supported'),
                        ),
                        DropdownMenuItem(
                          value: 'Not Supported',
                          child: Text('Not Supported'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEnvatoSupport = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // File Picker
                    OutlinedButton.icon(
                      onPressed: _selectedFiles.length < 5 ? _pickFiles : null,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        'Attach Files (${_selectedFiles.length}/5)',
                        style: const TextStyle(fontSize: 14),
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
                    const SizedBox(height: 32),

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
