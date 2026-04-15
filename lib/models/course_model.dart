class CourseModel {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String pdfUrl;
  final String pdfText;
  final int fileSize;
  final int pageCount;
  final int preparationScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.pdfUrl,
    required this.pdfText,
    required this.fileSize,
    required this.pageCount,
    required this.preparationScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      subject: map['subject'] as String,
      pdfUrl: map['pdf_url'] as String,
      pdfText: map['pdf_text'] as String,
      fileSize: map['file_size'] as int,
      pageCount: map['page_count'] as int,
      preparationScore: map['preparation_score'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}