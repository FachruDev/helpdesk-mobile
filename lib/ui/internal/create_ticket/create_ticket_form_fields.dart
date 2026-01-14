import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/html_editor_field.dart';
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
      name: employee.name,
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

class CreateTicketFormFields extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController subjectController;
  final HtmlEditorController messageController;
  final GlobalKey<HtmlEditorFieldState> messageFieldKey;
  final TextEditingController requestToOtherController;

  final CategoryModel? selectedCategory;
  final SubCategoryModel? selectedSubCategory;
  final ProjectModel? selectedProject;
  final EmployeeModel? selectedEmployee;
  final String? selectedEnvatoSupport;
  final bool isRequestToOther;
  final List<File> selectedFiles;

  final List<SubCategoryModel> availableSubCategories;
  final List<ProjectModel> availableProjects;
  final bool envatoRequired;
  final bool loadingExtras;

  final List<CategoryModel> categories;
  final List<EmployeeModel> employees;

  final ValueChanged<CategoryModel?> onCategoryChanged;
  final ValueChanged<SubCategoryModel?> onSubCategoryChanged;
  final ValueChanged<ProjectModel?> onProjectChanged;
  final ValueChanged<EmployeeModel?> onEmployeeChanged;
  final ValueChanged<bool> onRequestToOtherChanged;
  final ValueChanged<String?> onEnvatoSupportChanged;
  final ValueChanged<List<File>> onFilesPicked;
  final ValueChanged<int> onFileRemoved;

  const CreateTicketFormFields({
    super.key,
    required this.emailController,
    required this.subjectController,
    required this.messageController,
    required this.messageFieldKey,
    required this.requestToOtherController,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.selectedProject,
    required this.selectedEmployee,
    required this.selectedEnvatoSupport,
    required this.isRequestToOther,
    required this.selectedFiles,
    required this.availableSubCategories,
    required this.availableProjects,
    required this.envatoRequired,
    required this.loadingExtras,
    required this.categories,
    required this.employees,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onProjectChanged,
    required this.onEmployeeChanged,
    required this.onRequestToOtherChanged,
    required this.onEnvatoSupportChanged,
    required this.onFilesPicked,
    required this.onFileRemoved,
  });

  RequestToOption? get _selectedRequestTo {
    if (isRequestToOther) {
      return RequestToOption.other();
    } else if (selectedEmployee != null) {
      return RequestToOption.fromEmployee(selectedEmployee!);
    }
    return null;
  }

  Future<void> _pickFiles(BuildContext context) async {
    if (selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 files allowed'),
          backgroundColor: AppColors.warning,
        ),
      );
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

      final remainingSlots = 5 - selectedFiles.length;
      final updatedFiles = [...selectedFiles, ...newFiles.take(remainingSlots)];

      onFilesPicked(updatedFiles);

      if (newFiles.length > remainingSlots && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $remainingSlots files added (max 5 total)'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field (NEW for internal)
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Customer Email *',
            hintText: 'Enter customer email address',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            // Basic email validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Subject
        TextFormField(
          controller: subjectController,
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
          selectedItem: selectedCategory,
          items: categories,
          itemAsString: (category) => category.name,
          searchHint: 'Search category...',
          onChanged: onCategoryChanged,
          validator: (value) {
            if (value == null) return 'Category is required';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Loading indicator for extras
        if (loadingExtras)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),

        // SubCategory (conditional)
        if (!loadingExtras && availableSubCategories.isNotEmpty)
          SearchableDropdown<SubCategoryModel>(
            labelText: 'Sub Category *',
            prefixIcon: Icons.category_outlined,
            selectedItem: selectedSubCategory,
            items: availableSubCategories,
            itemAsString: (sub) => sub.name,
            searchHint: 'Search sub category...',
            onChanged: onSubCategoryChanged,
            validator: (value) {
              if (availableSubCategories.isNotEmpty && value == null) {
                return 'Sub category is required';
              }
              return null;
            },
          ),
        if (!loadingExtras && availableSubCategories.isNotEmpty)
          const SizedBox(height: 16),

        // Project (conditional)
        if (!loadingExtras && availableProjects.isNotEmpty)
          SearchableDropdown<ProjectModel>(
            labelText: 'Project *',
            prefixIcon: Icons.work,
            selectedItem: selectedProject,
            items: availableProjects,
            itemAsString: (project) => project.name,
            searchHint: 'Search project...',
            onChanged: onProjectChanged,
            validator: (value) {
              if (availableProjects.isNotEmpty && value == null) {
                return 'Project is required';
              }
              return null;
            },
          ),
        if (!loadingExtras && availableProjects.isNotEmpty)
          const SizedBox(height: 16),

        // Message
        HtmlEditorField(
          key: messageFieldKey,
          controller: messageController,
          labelText: 'Message *',
          hintText: 'Describe the issue',
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
            ...employees.map((e) => RequestToOption.fromEmployee(e)),
            RequestToOption.other(),
          ],
          itemAsString: (option) => option.name,
          searchHint: 'Search employee...',
          onChanged: (value) {
            if (value != null) {
              onRequestToOtherChanged(value.isOther);
              if (!value.isOther) {
                final emp = employees.firstWhere(
                  (e) => e.id.toString() == value.id,
                );
                onEmployeeChanged(emp);
              } else {
                onEmployeeChanged(null);
              }
            }
          },
          validator: (value) {
            if (value == null) return 'Request to is required';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Request To Other (conditional)
        if (isRequestToOther)
          TextFormField(
            controller: requestToOtherController,
            decoration: const InputDecoration(
              labelText: 'Specify Request To *',
              hintText: 'Enter name or department',
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (isRequestToOther && (value == null || value.trim().isEmpty)) {
                return 'Please specify request to';
              }
              return null;
            },
          ),
        if (isRequestToOther) const SizedBox(height: 16),

        // Envato Support (conditional based on category)
        if (envatoRequired)
          DropdownButtonFormField<String>(
            initialValue: selectedEnvatoSupport,
            decoration: const InputDecoration(
              labelText: 'Envato Support *',
              prefixIcon: Icon(Icons.support),
            ),
            items: const [
              DropdownMenuItem(value: 'Supported', child: Text('Supported')),
              DropdownMenuItem(
                value: 'Not Supported',
                child: Text('Not Supported'),
              ),
            ],
            onChanged: onEnvatoSupportChanged,
            validator: (value) {
              if (envatoRequired && value == null) {
                return 'Envato support is required';
              }
              return null;
            },
          ),
        if (envatoRequired) const SizedBox(height: 16),

        // File Picker
        OutlinedButton.icon(
          onPressed: selectedFiles.length < 5
              ? () => _pickFiles(context)
              : null,
          icon: const Icon(Icons.attach_file),
          label: Text(
            'Attach Files (${selectedFiles.length}/5)',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Selected Files List
        if (selectedFiles.isNotEmpty)
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
                ...List.generate(selectedFiles.length, (index) {
                  final file = selectedFiles[index];
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
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: () => onFileRemoved(index),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
