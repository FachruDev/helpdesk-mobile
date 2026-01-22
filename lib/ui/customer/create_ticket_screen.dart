import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';
import 'package:helpdesk_mobile/states/customer/customer_category_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_employee_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/html_editor_field.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/searchable_dropdown.dart';

// Helper class for Request To dropdown
class RequestToOption {
  final String id;
  final String name;
  final bool isOther;

  RequestToOption({
    required this.id,
    required this.name,
    this.isOther = false,
  });

  factory RequestToOption.fromEmployee(EmployeeModel employee) {
    return RequestToOption(
      id: employee.id.toString(),
      name: employee.name,
      isOther: false,
    );
  }

  factory RequestToOption.other() {
    return RequestToOption(
      id: 'other',
      name: 'Other',
      isOther: true,
    );
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
  final _messageController = HtmlEditorController();
  final _messageFieldKey = GlobalKey<HtmlEditorFieldState>();
  final _requestToOtherController = TextEditingController();

  CategoryModel? _selectedCategory;
  SubCategoryModel? _selectedSubCategory;
  ProjectModel? _selectedProject;
  EmployeeModel? _selectedEmployee;
  String? _selectedEnvatoSupport;
  bool _isRequestToOther = false;
  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  
  // Category extras state
  List<SubCategoryModel> _availableSubCategories = [];
  List<ProjectModel> _availableProjects = [];
  bool _envatoRequired = false;
  bool _loadingExtras = false;
  
  // Request To helper
  RequestToOption? _selectedRequestTo;

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

  Future<void> _fetchCategoryExtras(int categoryId) async {
    setState(() => _loadingExtras = true);

    final repository = CustomerTicketRepository();
    final response = await repository.getCategoryExtras(categoryId);

    setState(() {
      _loadingExtras = false;
      
      if (response.success && response.data != null) {
        _availableSubCategories = response.data!.subCategories;
        _availableProjects = response.data!.projects;
        _envatoRequired = response.data!.envatoRequired;
        
        print('===== EXTRAS LOADED =====');
        print('SubCategories: ${_availableSubCategories.length}');
        print('Projects: ${_availableProjects.length}');
        print('Envato Required: $_envatoRequired');
        print('========================');
      } else {
        _availableSubCategories = [];
        _availableProjects = [];
        _envatoRequired = false;
      }
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate HTML editor
    final messageValid = await _messageFieldKey.currentState?.validate() ?? false;
    if (!messageValid) return;

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

    final messageHtml = await _messageController.getText();
    final success = await ref.read(customerTicketProvider.notifier).createTicket(
          subject: _subjectController.text.trim(),
          categoryId: _selectedCategory!.id,
          message: messageHtml,
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

                    // Category - Searchable
                    SearchableDropdown<CategoryModel>(
                      labelText: 'Category *',
                      prefixIcon: Icons.category,
                      selectedItem: _selectedCategory,
                      items: categoryState.categories,
                      itemAsString: (category) => category.name,
                      searchHint: 'Search category...',
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedSubCategory = null;
                            _selectedProject = null;
                            _selectedEnvatoSupport = null;
                          });
                          
                          // Fetch category extras
                          await _fetchCategoryExtras(value.id);
                        } else {
                          setState(() {
                            _selectedCategory = null;
                            _selectedSubCategory = null;
                            _selectedProject = null;
                            _availableSubCategories = [];
                            _availableProjects = [];
                            _envatoRequired = false;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Category is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Loading indicator for extras
                    if (_loadingExtras)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // SubCategory (conditional)
                    if (!_loadingExtras && _availableSubCategories.isNotEmpty)
                      SearchableDropdown<SubCategoryModel>(
                        labelText: 'Sub Category *',
                        prefixIcon: Icons.category_outlined,
                        selectedItem: _selectedSubCategory,
                        items: _availableSubCategories,
                        itemAsString: (sub) => sub.name,
                        searchHint: 'Search sub category...',
                        onChanged: (value) {
                          setState(() {
                            _selectedSubCategory = value;
                          });
                        },
                        validator: (value) {
                          if (_availableSubCategories.isNotEmpty && value == null) {
                            return 'Sub category is required';
                          }
                          return null;
                        },
                      ),
                    if (!_loadingExtras && _availableSubCategories.isNotEmpty)
                      const SizedBox(height: 16),

                    // Project (conditional)
                    if (!_loadingExtras && _availableProjects.isNotEmpty)
                      SearchableDropdown<ProjectModel>(
                        labelText: 'Project *',
                        prefixIcon: Icons.work,
                        selectedItem: _selectedProject,
                        items: _availableProjects,
                        itemAsString: (project) => project.name,
                        searchHint: 'Search project...',
                        onChanged: (value) {
                          setState(() {
                            _selectedProject = value;
                          });
                        },
                        validator: (value) {
                          if (_availableProjects.isNotEmpty && value == null) {
                            return 'Project is required';
                          }
                          return null;
                        },
                      ),
                    if (!_loadingExtras && _availableProjects.isNotEmpty)
                      const SizedBox(height: 16),

                    // Message
                    HtmlEditorField(
                      key: _messageFieldKey,
                      controller: _messageController,
                      labelText: 'Message *',
                      hintText: 'Describe your issue',
                      height: 300,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty || value == '<p></p>' || value == '<p><br></p>') {
                          return 'Message is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Request To - Searchable
                    SearchableDropdown<RequestToOption>(
                      labelText: 'Request To *',
                      prefixIcon: Icons.person,
                      selectedItem: _selectedRequestTo,
                      items: [
                        ...employeeState.employees.map((e) => 
                          RequestToOption.fromEmployee(e)
                        ),
                        RequestToOption.other(),
                      ],
                      itemAsString: (option) => option.name,
                      searchHint: 'Search employee...',
                      onChanged: (value) {
                        setState(() {
                          _selectedRequestTo = value;
                          _isRequestToOther = value?.isOther ?? false;
                          if (value != null && !value.isOther) {
                            _selectedEmployee = employeeState.employees
                                .firstWhere((e) => e.id.toString() == value.id);
                          } else {
                            _selectedEmployee = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Request to is required';
                        return null;
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

                    // Envato Support (conditional based on category)
                    if (_envatoRequired)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEnvatoSupport,
                        decoration: const InputDecoration(
                          labelText: 'Envato Support *',
                          prefixIcon: Icon(Icons.support),
                        ),
                        items: const [
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
                        validator: (value) {
                          if (_envatoRequired && value == null) {
                            return 'Envato support is required';
                          }
                          return null;
                        },
                      ),
                    if (_envatoRequired) const SizedBox(height: 16),

                    // Attachment Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedFiles.length < 5 ? _takePhoto : null,
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
                            onPressed: _selectedFiles.length < 5 ? _pickFiles : null,
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
