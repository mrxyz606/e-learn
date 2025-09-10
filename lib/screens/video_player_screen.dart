import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String lessonTitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.lessonTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showControls = true; // Initially show controls

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Ensure the first frame is shown after the video is initialized,
      // and play the video.
      setState(() {}); // Update UI once initialized
      _controller.play();
    }).catchError((error) {
      // Handle initialization error
      debugPrint("Error initializing video player: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: ${error.toString()}')),
      );
    });

    _controller.addListener(() {
      // Hide controls when video starts playing, show when paused or ended
      if (_controller.value.isPlaying && _showControls) {
        // Optional: auto-hide controls after a delay when playing
        // Future.delayed(const Duration(seconds: 3), () {
        //   if (mounted && _controller.value.isPlaying) {
        //     setState(() {
        //       _showControls = false;
        //     });
        //   }
        // });
      } else if (!_controller.value.isPlaying && !_showControls) {
        if (mounted) {
          setState(() {
            _showControls = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
      ),
      body: Center(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && !_controller.value.hasError) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Use a Stack to overlay controls on top of the video
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _toggleControls, // Toggle controls on tap
                      child: VideoPlayer(_controller),
                    ),
                    if (_showControls) _buildControlsOverlay(),
                  ],
                ),
              );
            } else if (snapshot.hasError || (_controller.value.hasError && snapshot.connectionState == ConnectionState.done)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      'Could not load video.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (snapshot.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              );
            } else {
              // If the VideoPlayerController is still initializing, show a
              // loading spinner.
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      // Optional FloatingActionButton for play/pause if not using overlay controls primarily
      // floatingActionButton: _controller.value.isInitialized
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           setState(() {
      //             _controller.value.isPlaying
      //                 ? _controller.pause()
      //                 : _controller.play();
      //           });
      //         },
      //         child: Icon(
      //           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //         ),
      //       )
      //     : null,
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: <Widget>[
          // Gradient for better visibility of controls
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black38,
                  Colors.black54,
                ],
              ),
            ),
          ),
          // Play/Pause button
          Align(
            alignment: Alignment.center,
            child: IconButton(
              iconSize: 64.0,
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              ),
            ),
          ),
          // Progress bar
          Align(
            alignment: Alignment.bottomCenter,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              colors: VideoProgressColors(
                playedColor: Theme.of(context).primaryColor,
                bufferedColor: Colors.grey.shade600,
                backgroundColor: Colors.grey.shade400,
              ),
            ),
          ),
          // Fullscreen button (example, actual fullscreen needs more platform-specific code or another package)
          // Align(
          //   alignment: Alignment.bottomRight,
          //   child: IconButton(
          //     color: Colors.white,
          //     icon: const Icon(Icons.fullscreen),
          //     onPressed: () {
          //       // Implement fullscreen toggle
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
