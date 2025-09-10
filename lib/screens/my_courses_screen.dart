// lib/screens/my_courses_screen.dart (New File)
import 'package:course/models/course.dart';
import 'package:course/screens/course_detail_screen.dart';
import 'package:course/services/auth_service.dart';
import 'package:course/services/firestore_service.dart';
import 'package:course/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService(); // Or get from Provider

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<User?>(context); // Example if using Provider for user
    final user = _authService.currentUser;


    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Courses')),
        body: const Center(
          child: Text('Please log in to see your courses.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
      ),
      body: StreamBuilder<List<MyCourseInfo>>(
        stream: _firestoreService.getMyCoursesWithProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('You are not enrolled in any courses yet.', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Explore available courses and start learning!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final myCoursesInfo = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: myCoursesInfo.length,
            itemBuilder: (context, index) {
              final courseInfo = myCoursesInfo[index];
              return CourseCard(
                course: courseInfo.course,
                enrollmentDetails: courseInfo.enrollmentDetails, // Pass details here
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(courseId: courseInfo.course.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
