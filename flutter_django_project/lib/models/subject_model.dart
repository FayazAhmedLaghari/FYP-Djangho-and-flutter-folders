class Subject {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<SubjectNote> notes;
  final List<SubjectMaterial> materials;

  Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.notes = const [],
    this.materials = const [],
  });

  Subject copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<SubjectNote>? notes,
    List<SubjectMaterial>? materials,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      materials: materials ?? this.materials,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes.map((note) => note.toJson()).toList(),
      'materials': materials.map((material) => material.toJson()).toList(),
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      notes: (json['notes'] as List<dynamic>?)
          ?.map((note) => SubjectNote.fromJson(note))
          .toList() ?? [],
      materials: (json['materials'] as List<dynamic>?)
          ?.map((material) => SubjectMaterial.fromJson(material))
          .toList() ?? [],
    );
  }
}

class SubjectNote {
  final String id;
  final String title;
  final String content;
  final String type; // 'text', 'pdf', 'image'
  final String? filePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubjectNote({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.filePath,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SubjectNote.fromJson(Map<String, dynamic> json) {
    return SubjectNote(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

class SubjectMaterial {
  final String id;
  final String title;
  final String type; // 'pdf', 'image', 'video', 'document'
  final String filePath;
  final int fileSize;
  final DateTime uploadedAt;
  final bool isProcessed;

  SubjectMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.filePath,
    required this.fileSize,
    required this.uploadedAt,
    this.isProcessed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'filePath': filePath,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isProcessed': isProcessed,
    };
  }

  factory SubjectMaterial.fromJson(Map<String, dynamic> json) {
    return SubjectMaterial(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'document',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      isProcessed: json['isProcessed'] ?? false,
    );
  }
}
