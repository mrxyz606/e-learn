import 'package:course/models/course.dart';
import 'package:course/services/firestore_service.dart'; // For EnrollmentDetails
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart'; // If you want a progress bar

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final EnrollmentDetails? enrollmentDetails;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.enrollmentDetails,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("--- CourseCard BUILD for: ${course.title} (Enrollment: ${enrollmentDetails != null}) ---");

    bool isEnrolled = enrollmentDetails != null;
    bool isCompleted = enrollmentDetails?.isCompleted ?? false;
    double progressPercent = isEnrolled ? enrollmentDetails!.progressPercentage : 0.0;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).primaryColor.withAlpha(40),
        highlightColor: Theme.of(context).primaryColor.withAlpha(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch horizontally
          children: [
            // --- Course Image ---
            SizedBox(
              height: 160.0, // Adjust height as needed
              child: Hero( // Optional: For hero animations to CourseDetailScreen
                tag: 'courseImage_${course.id}',
                child: Image.network(
                  course.imageUrl.isNotEmpty ? course.imageUrl : 'https://via.placeholder.com/400x200?text=No+Image', // Fallback URL
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey[400], size: 50)),
                    );
                  },
                ),
              ),
            ),

            // --- Course Details Area ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title ---
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      // color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6.0),

                  // --- Instructor ---
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16.0, color: Colors.grey[600]),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          course.instructorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // --- Progress Bar and Completion ---
                  if (isEnrolled)
                    Row(
                      children: [
                        Expanded(
                          child: LinearPercentIndicator(
                            animation: true,
                            lineHeight: 8.0,
                            animationDuration: 500,
                            percent: progressPercent > 1.0 ? 1.0 : progressPercent, // Cap at 100%
                            center: Text(
                              isCompleted ? "Completed" : "${(progressPercent * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                  fontSize: progressPercent > 0.1 || isCompleted ? 7.0 : 0, // Hide if too small and not completed
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            barRadius: const Radius.circular(5),
                            progressColor: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        if (isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ),
                      ],
                    )
                  else // Not enrolled, maybe show a "View Course" or nothing
                    Text(
                      "Tap to view details",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
