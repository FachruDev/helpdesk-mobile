import 'package:helpdesk_mobile/data/models/employee_model.dart';

class EmployeeLookupModel {
  final List<EmployeeModel> employees;
  final String? subjectCategory;
  final Map<String, String> subjectCategoryOptions;

  const EmployeeLookupModel({
    required this.employees,
    this.subjectCategory,
    required this.subjectCategoryOptions,
  });

  static const Map<String, String> defaultSubjectCategoryOptions = {
    'technical_support': 'Technical Support',
    'administration': 'Administration',
  };

  factory EmployeeLookupModel.fromApiResponse(Map<String, dynamic> json) {
    final employeesData = json['data'] ?? json['employees'] ?? const [];
    final employees = (employeesData as List)
        .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>?;
    final options = _parseSubjectCategoryOptions(meta?['subject_category_options']);

    return EmployeeLookupModel(
      employees: employees,
      subjectCategory: meta?['subject_category']?.toString(),
      subjectCategoryOptions:
          options.isEmpty ? defaultSubjectCategoryOptions : options,
    );
  }

  static Map<String, String> _parseSubjectCategoryOptions(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    if (raw is List) {
      final parsed = <String, String>{};
      for (final item in raw) {
        if (item is Map) {
          final value = item['value']?.toString();
          final label = item['label']?.toString();
          if (value != null && value.isNotEmpty && label != null && label.isNotEmpty) {
            parsed[value] = label;
          }
        }
      }
      return parsed;
    }

    return {};
  }
}