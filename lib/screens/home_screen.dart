import 'package:course/models/course.dart';
import 'package:course/screens/course_detail_screen.dart';
import 'package:course/screens/my_courses_screen.dart';
import 'package:course/screens/settings_screen.dart';
import 'package:course/services/auth_service.dart';
import 'package:course/services/firestore_service.dart';
import 'package:course/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // For Debouncer

// Debouncer class (keep as is)
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  dispose() {
    _timer?.cancel();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // To manage focus
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  String _searchQuery = "";
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  Map<String, EnrollmentDetails> _enrolledDetailsMap = {};
  StreamSubscription? _enrollmentSubscription;
  bool _isLoadingCourses = true;
  bool _isSearching = false; // NEW: To toggle search UI state

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllCourses();
    _listenToEnrollments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer.dispose();
    _enrollmentSubscription?.cancel();
    super.dispose();
  }

  void _loadAllCourses() async {
    // ... (keep _loadAllCourses as is)
    setState(() {
      _isLoadingCourses = true;
    });
    _firestoreService.getCourses().first.then((courses) {
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _isLoadingCourses = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
        debugPrint("Error loading all courses: $error");
      }
    });
  }

  void _listenToEnrollments() {
    // ... (keep _listenToEnrollments as is)
    if (_authService.currentUser != null) {
      _enrollmentSubscription = _firestoreService.getMyCoursesWithProgress().listen((myCourseInfoList) {
        if (mounted) {
          Map<String, EnrollmentDetails> tempMap = {};
          for (var info in myCourseInfoList) {
            tempMap[info.course.id] = info.enrollmentDetails;
          }
          setState(() {
            _enrolledDetailsMap = tempMap;
          });
        }
      });
    } else {
      if (mounted && _enrolledDetailsMap.isNotEmpty) {
        setState(() {
          _enrolledDetailsMap.clear();
        });
      }
    }
  }

  void _onSearchChanged() {
    // ... (keep _onSearchChanged as is)
    _debouncer.run(() {
      if (mounted) {
        final query = _searchController.text.toLowerCase().trim();
        if (query != _searchQuery) {
          setState(() {
            _searchQuery = query;
            _filterCourses();
          });
        } else if (query.isEmpty && _searchQuery.isNotEmpty) {
          setState(() {
            _searchQuery = "";
            _filterCourses();
          });
        }
      }
    });
  }

  void _filterCourses() {
    // ... (keep _filterCourses as is)
    if (_searchQuery.isEmpty) {
      _filteredCourses = List.from(_allCourses);
    } else {
      _filteredCourses = _allCourses.where((course) {
        final titleMatch = course.title.toLowerCase().contains(_searchQuery);
        final instructorMatch = course.instructorName.toLowerCase().contains(_searchQuery);
        // final keywordMatch = course.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery));
        return titleMatch || instructorMatch /* || keywordMatch */;
      }).toList();
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    // Request focus for the TextField when search starts
    // Use a small delay to ensure the TextField is built before requesting focus
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear(); // Clears text and triggers _onSearchChanged -> _filterCourses
      // _searchQuery = ""; // Already handled by _searchController.clear() listener
      // _filterCourses(); // Already handled by _searchController.clear() listener
    });
    _searchFocusNode.unfocus(); // Remove focus
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true, // Focus when it appears
      decoration: InputDecoration(
        hintText: 'Search courses...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.8)),
      ),
      style: TextStyle(
        color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _stopSearch,
          tooltip: "Close Search",
        ),
        title: _buildSearchField(),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: "Clear Search",
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      );
    } else {
      return AppBar(
        title: const Text('e-learn'), // Your App Name
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search Courses",
            onPressed: _startSearch,
          ),
          IconButton(
            icon: const Icon(Icons.cast_for_education_outlined),
            tooltip: "My Learning",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCoursesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("--- HomeScreen BUILD METHOD CALLED --- (Query: $_searchQuery, IsSearching: $_isSearching)");
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(), // _buildBody remains the same
      // floatingActionButton: _isSearching ? null : FloatingActionButton.extended( // Hide FAB when searching
      //   onPressed: () async {
      //     await _firestoreService.addSampleCoursesWithLessons();
      //     if (mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Attempted to add/update sample courses.')),
      //       );
      //     }
      //   },
      //   label: const Text('Sample Data'),
      //   icon: const Icon(Icons.data_exploration_outlined),
      // ),
    );
  }

  Widget _buildBody() {
    // ... (keep _buildBody as is, it already uses _filteredCourses)
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator(key: Key("all_courses_loading")));
    }

    if (_allCourses.isEmpty && !_isLoadingCourses) {
      return const Center(child: Text('No courses available. Try adding sample data.'));
    }

    if (_searchQuery.isNotEmpty && _filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No courses found for "$_searchQuery".', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Try a different search term.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return CourseCard(
          course: course,
          enrollmentDetails: _enrolledDetailsMap[course.id],
          onTap: () {
            FocusScope.of(context).unfocus(); // Hide keyboard
            if (_isSearching) _stopSearch(); // Optionally close search on tap
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CourseDetailScreen(courseId: course.id)),
            );
          },
        );
      },
    );
  }
}
