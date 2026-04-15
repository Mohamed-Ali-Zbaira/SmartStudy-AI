class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? university;
  final String? fieldOfStudy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.university,
    this.fieldOfStudy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id:           map['id'] as String,
      email:        map['email'] as String,
      fullName:     map['full_name'] as String,
      avatarUrl:    map['avatar_url'] as String?,
      university:   map['university'] as String?,
      fieldOfStudy: map['field_of_study'] as String?,
      createdAt:    DateTime.parse(map['created_at'] as String),
      updatedAt:    DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':             id,
    'email':          email,
    'full_name':      fullName,
    'avatar_url':     avatarUrl,
    'university':     university,
    'field_of_study': fieldOfStudy,
  };
}