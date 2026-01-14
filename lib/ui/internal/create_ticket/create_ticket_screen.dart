import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_ticket_repository.dart';
import 'package:helpdesk_mobile/states/internal/internal_ticket_provider.dart';
import 'package:helpdesk_mobile/ui/internal/create_ticket/create_ticket_form_fields.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/html_editor_field.dart';

// Provider for categories
final internalCategoryProvider =
    NotifierProvider<InternalCategoryNotifier, InternalCategoryState>(
      InternalCategoryNotifier.new,
    );

class InternalCategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  InternalCategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  InternalCategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? error,
  }) {
    return InternalCategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InternalCategoryNotifier extends Notifier<InternalCategoryState> {
  @override
  InternalCategoryState build() {
    return InternalCategoryState();
  }

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true);

    final repository = InternalTicketRepository();
    final response = await repository.getCategories();

    if (response.success && response.data != null) {
      state = state.copyWith(categories: response.data!, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }
}

// Provider for employees
final internalEmployeeProvider =
    NotifierProvider<InternalEmployeeNotifier, InternalEmployeeState>(
      InternalEmployeeNotifier.new,
    );

class InternalEmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;
  final String? error;

  InternalEmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  InternalEmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    String? error,
  }) {
    return InternalEmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InternalEmployeeNotifier extends Notifier<InternalEmployeeState> {
  @override
  InternalEmployeeState build() {
    return InternalEmployeeState();
  }

  Future<void> fetchEmployees() async {
    state = state.copyWith(isLoading: true);

    final repository = InternalTicketRepository();
    final response = await repository.getEmployees();

    if (response.success && response.data != null) {
      state = state.copyWith(employees: response.data!, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
    }
  }
}

class InternalCreateTicketScreen extends ConsumerStatefulWidget {
  const InternalCreateTicketScreen({super.key});

  @override
  ConsumerState<InternalCreateTicketScreen> createState() =>
      _InternalCreateTicketScreenState();
}

class _InternalCreateTicketScreenState
    extends ConsumerState<InternalCreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
  List<File> _selectedFiles = [];
  bool _isSubmitting = false;

  // Category extras state
  List<SubCategoryModel> _availableSubCategories = [];
  List<ProjectModel> _availableProjects = [];
  bool _envatoRequired = false;
  bool _loadingExtras = false;

  @override
  void initState() {
    super.initState();
    // Load categories and employees
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(internalCategoryProvider.notifier).fetchCategories();
      ref.read(internalEmployeeProvider.notifier).fetchEmployees();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _requestToOtherController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryExtras(int categoryId) async {
    setState(() => _loadingExtras = true);

    final repository = InternalTicketRepository();
    final response = await repository.getCategoryExtras(categoryId);

    setState(() {
      _loadingExtras = false;

      if (response.success && response.data != null) {
        _availableSubCategories = response.data!.subCategories;
        _availableProjects = response.data!.projects;
        _envatoRequired = response.data!.envatoRequired;
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
    final success = await ref
        .read(internalTicketProvider.notifier)
        .createTicket(
          email: _emailController.text.trim(),
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
    final categoryState = ref.watch(internalCategoryProvider);
    final employeeState = ref.watch(internalEmployeeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Ticket')),
      body: categoryState.isLoading || employeeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateTicketFormFields(
                      emailController: _emailController,
                      subjectController: _subjectController,
                      messageController: _messageController,
                      messageFieldKey: _messageFieldKey,
                      requestToOtherController: _requestToOtherController,
                      selectedCategory: _selectedCategory,
                      selectedSubCategory: _selectedSubCategory,
                      selectedProject: _selectedProject,
                      selectedEmployee: _selectedEmployee,
                      selectedEnvatoSupport: _selectedEnvatoSupport,
                      isRequestToOther: _isRequestToOther,
                      selectedFiles: _selectedFiles,
                      availableSubCategories: _availableSubCategories,
                      availableProjects: _availableProjects,
                      envatoRequired: _envatoRequired,
                      loadingExtras: _loadingExtras,
                      categories: categoryState.categories,
                      employees: employeeState.employees,
                      onCategoryChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedSubCategory = null;
                            _selectedProject = null;
                            _selectedEnvatoSupport = null;
                          });

                          await _fetchCategoryExtras(value.id);
                        } else {
                          setState(() {
                            _selectedCategory = null;
                            _selectedSubCategory = null;
                            _selectedProject = null;
                            _selectedEnvatoSupport = null;
                            _availableSubCategories = [];
                            _availableProjects = [];
                            _envatoRequired = false;
                          });
                        }
                      },
                      onSubCategoryChanged: (value) {
                        setState(() => _selectedSubCategory = value);
                      },
                      onProjectChanged: (value) {
                        setState(() => _selectedProject = value);
                      },
                      onEmployeeChanged: (value) {
                        setState(() {
                          _selectedEmployee = value;
                          _isRequestToOther = false;
                        });
                      },
                      onRequestToOtherChanged: (value) {
                        setState(() {
                          _isRequestToOther = value;
                          _selectedEmployee = null;
                        });
                      },
                      onEnvatoSupportChanged: (value) {
                        setState(() => _selectedEnvatoSupport = value);
                      },
                      onFilesPicked: (files) {
                        setState(() => _selectedFiles = files);
                      },
                      onFileRemoved: (index) {
                        setState(() => _selectedFiles.removeAt(index));
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
                              'Create Ticket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
