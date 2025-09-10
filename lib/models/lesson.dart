class Lesson {
  final String id; // Could be a unique ID generated or derived
  final String title;
  final String description; // Optional: a brief description of the lesson
  final String videoUrl;
  final int order; // To maintain lesson sequence

  Lesson({
    required this.id,
    required this.title,
    this.description = '',
    required this.videoUrl,
    required this.order,
  });

  // From map for Firestore
  factory Lesson.fromMap(Map<String, dynamic> map, String id) {
    return Lesson(
      id: id, // Or use map['id'] if you store it explicitly in the lesson map
      title: map['title'] ?? 'Untitled Lesson',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  // To map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'order': order,
    };
  }
}
