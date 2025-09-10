import 'package:course/models/lesson.dart';
import 'package:flutter/cupertino.dart'; // Import the new Lesson model

class Course {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String imageUrl;
  final List<Lesson> lessons; // Add this line

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.imageUrl,
    this.lessons = const [], // Initialize with an empty list
  });

  factory Course.fromMap(Map<String, dynamic> data, String documentId) {
    // Deserialize lessons from Firestore
    try {
      // ... your existing parsing logic ...
      var lessonsData = data['lessons'] as List<dynamic>? ?? [];
      List<Lesson> parsedLessons = lessonsData.asMap().entries.map((entry) {
        return Lesson.fromMap(entry.value as Map<String, dynamic>, entry.key.toString());
      }).toList();
      parsedLessons.sort((a, b) => a.order.compareTo(b.order));

      return Course(
        id: documentId,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        instructorName: data['instructorName'] ?? '',
        imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
        lessons: parsedLessons,
      );
    } catch (e, stackTrace) {
      debugPrint("Error in Course.fromMap for doc ID $documentId: $e");
      debugPrint("Course.fromMap StackTrace: $stackTrace");
      debugPrint("Problematic Course Data: $data"); // Print the data that caused the error
      // Return a 'dummy' course or rethrow to see where it's caught
      rethrow; // Or handle more gracefully
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructorName': instructorName,
      'imageUrl': imageUrl,
      // Serialize lessons to a list of maps
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }
}