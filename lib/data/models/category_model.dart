class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final List<SubCategoryModel>? subCategories;
  final List<ProjectModel>? projects;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.subCategories,
    this.projects,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      subCategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((e) => SubCategoryModel.fromJson(e))
              .toList()
          : null,
      projects: json['projects'] != null
          ? (json['projects'] as List)
              .map((e) => ProjectModel.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subcategories': subCategories?.map((e) => e.toJson()).toList(),
      'projects': projects?.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasSubCategories => 
      subCategories != null && subCategories!.isNotEmpty;
  
  bool get hasProjects => 
      projects != null && projects!.isNotEmpty;
}

class SubCategoryModel {
  final int id;
  final String name;

  SubCategoryModel({
    required this.id,
    required this.name,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ProjectModel {
  final int? id;
  final String name;

  ProjectModel({
    this.id,
    required this.name,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
