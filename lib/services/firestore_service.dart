import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course/models/course.dart';
import 'package:course/models/lesson.dart';
import 'package:course/services/auth_service.dart';
import 'package:flutter/material.dart';

// --- Enrollment Details Model ---
class EnrollmentDetails {
  final String courseId;
  final DateTime enrolledAt;
  int completedLessons; // Made non-final to be updatable by markLessonAsCompleted logic if needed locally
  final int totalLessons;
  bool isCompleted; // Made non-final
  final List<String> completedLessonIds; // For robust tracking

  EnrollmentDetails({
    required this.courseId,
    required this.enrolledAt,
    required this.completedLessons,
    required this.totalLessons,
    required this.isCompleted,
    this.completedLessonIds = const [],
  });

  factory EnrollmentDetails.fromMap(String courseId, Map<String, dynamic> data) {
    return EnrollmentDetails(
      courseId: courseId,
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedLessons: data['completedLessons'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      completedLessonIds: List<String>.from(data['completedLessonIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() { // For potential local updates or new enrollments
    return {
      'courseId': courseId, // Not usually stored in the doc itself if docId is courseId
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'isCompleted': isCompleted,
      'completedLessonIds': completedLessonIds,
    };
  }

  double get progressPercentage {
    if (totalLessons == 0) return 0.0;
    // Use completedLessonIds.length if it's the source of truth for completed lessons
    if (completedLessonIds.isNotEmpty && completedLessonIds.length != completedLessons) {
      // This case indicates a potential mismatch if completedLessons isn't solely derived from completedLessonIds.length
      // For robustness, prefer completedLessonIds.length
      return completedLessonIds.length / totalLessons;
    }
    return completedLessons / totalLessons;
  }
}

// --- My Course Info Helper Class ---
class MyCourseInfo {
  final Course course;
  final EnrollmentDetails enrollmentDetails;
  MyCourseInfo(this.course, this.enrollmentDetails);
}


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // --- Course Functions ---
  Stream<List<Course>> getCourses() {
    return _db.collection('courses').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc =
      await _db.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return Course.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching course: $e");
    }
    return null;
  }

  // --- Enrollment Functions ---
  Future<void> enrollInCourse(String courseId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception("User not logged in to enroll.");
    }
    try {
      Course? course = await getCourseById(courseId);
      if (course == null) {
        throw Exception("Course not found.");
      }

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('enrolledCourses')
          .doc(courseId)
          .set({
        'enrolledAt': FieldValue.serverTimestamp(),
        'courseTitle': course.title, // Denormalized for easier display in "My Courses" if needed
        'completedLessons': 0,
        'totalLessons': course.lessons.length,
        'isCompleted': false,
        'completedLessonIds': [], // Initialize empty list for robust tracking
      });
      debugPrint("User ${user.uid} enrolled in course $courseId with ${course.lessons.length} total lessons.");
    } catch (e) {
      debugPrint("Error enrolling in course: $e");
      rethrow;
    }
  }

  Future<void> unenrollFromCourse(String courseId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception("User not logged in to unenroll.");
    }
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('enrolledCourses')
          .doc(courseId)
          .delete();
      debugPrint("User ${user.uid} unenrolled from course $courseId");
    } catch (e) {
      debugPrint("Error unenrolling from course: $e");
      rethrow;
    }
  }

  Stream<EnrollmentDetails?> getEnrollmentDetailsStream(String courseId) {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('enrolledCourses')
        .doc(courseId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return EnrollmentDetails.fromMap(courseId, snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> markLessonAsCompleted(String courseId, String lessonId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final enrollmentRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('enrolledCourses')
        .doc(courseId);

    try {
      await _db.runTransaction((transaction) async {
        DocumentSnapshot enrollmentSnap = await transaction.get(enrollmentRef);
        if (!enrollmentSnap.exists || enrollmentSnap.data() == null) {
          throw Exception("User not enrolled or enrollment data missing.");
        }

        Map<String, dynamic> enrollmentData = enrollmentSnap.data() as Map<String, dynamic>;
        List<String> completedLessonIds = List<String>.from(enrollmentData['completedLessonIds'] ?? []);
        int totalLessons = enrollmentData['totalLessons'] ?? 0;

        if (!completedLessonIds.contains(lessonId)) {
          completedLessonIds.add(lessonId);
        }

        int newCompletedLessonsCount = completedLessonIds.length;
        bool courseIsNowCompleted = (totalLessons > 0 && newCompletedLessonsCount >= totalLessons);

        transaction.update(enrollmentRef, {
          'completedLessonIds': completedLessonIds,
          'completedLessons': newCompletedLessonsCount, // Update this based on the list length
          'isCompleted': courseIsNowCompleted,
          'lastProgressTimestamp': FieldValue.serverTimestamp(),
        });
      });
      debugPrint("Lesson $lessonId for course $courseId marked complete for user ${user.uid}");
    } catch (e) {
      debugPrint("Error marking lesson complete: $e");
      rethrow;
    }
  }


  // --- My Courses Functions ---
  Stream<List<MyCourseInfo>> getMyCoursesWithProgress() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('enrolledCourses')
        .orderBy('enrolledAt', descending: true) // Optional: order by enrollment time
        .snapshots()
        .asyncMap((enrollmentSnapshot) async {
      List<MyCourseInfo> myCoursesList = [];
      for (var enrollmentDoc in enrollmentSnapshot.docs) {
        final courseId = enrollmentDoc.id;
        final enrollmentData = enrollmentDoc.data();

        Course? course = await getCourseById(courseId);

        if (course != null) {
          EnrollmentDetails details = EnrollmentDetails.fromMap(courseId, enrollmentData);
          myCoursesList.add(MyCourseInfo(course, details));
        } else {
          debugPrint("Course data not found for enrolled course ID: $courseId. User: ${user.uid}");
          // You might want to handle this case, e.g., by removing the orphaned enrollment record
          // or displaying a placeholder. For now, we just skip it.
        }
      }
      return myCoursesList;
    });
  }


  // --- Sample Data (ensure lesson IDs are unique) ---
  Future<void> addSampleCoursesWithLessons() async {
    final coursesCollection = _db.collection('courses');

    // A simple check to avoid adding if data might exist. Consider more robust checks.
    final QuerySnapshot existingCheck = await coursesCollection.limit(1).get();
    if (existingCheck.docs.isNotEmpty) {
      // Check if the existing course has lessons to prevent re-adding
      var firstCourseData = existingCheck.docs.first.data() as Map<String, dynamic>?;
      if (firstCourseData != null && (firstCourseData['lessons'] as List?)?.isNotEmpty == true) {
        debugPrint("Sample courses with lessons likely already exist.");
        return;
      }
    }


    final List<Course> sampleCourses = [
      Course(
        id: 'flutter_basics_001', // Using specific IDs for sample data
        title: 'Flutter for Absolute Beginners',
        description: 'Your first step into mobile app development with Flutter. Covers widgets, layouts, and state management basics.',
        instructorName: 'Ada Lovelace',
        imageUrl: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8Zmx1dHRlcnxlbnwwfHwwfHw%3D&auto=format&fit=crop&w=500&q=60', // Replace with a real placeholder
        lessons: [
          Lesson(id: 'fb_l1', title: 'Introduction to Flutter', videoUrl: 'YOUR_GCS_VIDEO_URL_1_HERE', order: 1, description: "What is Flutter and why use it?"),
          Lesson(id: 'fb_l2', title: 'Setting up Your Environment', videoUrl: 'YOUR_GCS_VIDEO_URL_2_HERE', order: 2, description: "Install Flutter and configure your IDE."),
          Lesson(id: 'fb_l3', title: 'Your First Flutter App', videoUrl: 'YOUR_GCS_VIDEO_URL_3_HERE', order: 3, description: "Hello World in Flutter: Understanding the main.dart file."),
          Lesson(id: 'fb_l4', title: 'Basic Widgets', videoUrl: 'YOUR_GCS_VIDEO_URL_4_HERE', order: 4, description: "Exploring Text, Container, Row, Column."),
        ],
      ),
      Course(
        id: 'dart_deep_dive_002',
        title: 'Advanced Dart Programming',
        description: 'Master the Dart language for powerful Flutter apps. Dive into asynchronous programming, streams, and more.',
        instructorName: 'Charles Babbage',
        imageUrl: 'https://images.unsplash.com/photo-1599507593499-a3f7d7d97667?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NXx8ZGFydCUyMHByb2dyYW1taW5nfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60', // Replace
        lessons: [
          Lesson(id: 'dd_l1', title: 'Asynchronous Programming: Futures', videoUrl: 'YOUR_GCS_VIDEO_URL_5_HERE', order: 1, description: "Understanding async, await, and Future objects."),
          Lesson(id: 'dd_l2', title: 'Streams in Dart', videoUrl: 'YOUR_GCS_VIDEO_URL_6_HERE', order: 2, description: "Handling sequences of asynchronous data."),
          Lesson(id: 'dd_l3', title: 'Error Handling in Dart', videoUrl: 'YOUR_GCS_VIDEO_URL_7_HERE', order: 3, description: "Try, catch, finally, and custom exceptions."),
        ],
      ),
    ];

    WriteBatch batch = _db.batch();
    for (var course in sampleCourses) {
      DocumentReference courseRef = coursesCollection.doc(course.id);
      batch.set(courseRef, course.toMap());
    }
    await batch.commit();
    debugPrint("Added/Updated sample courses with lessons to Firestore.");
  }
}
