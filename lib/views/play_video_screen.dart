// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, file_names, prefer_const_constructors, prefer_final_fields, avoid_print, deprecated_member_use, use_build_context_synchronously, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_streaming/service/common_service.dart';
import 'package:video_streaming/service/video_timing_service.dart';

class PlayVideoScreen extends StatefulWidget {
  final String? videoName;

  PlayVideoScreen({super.key, this.videoName});

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen>
    with SingleTickerProviderStateMixin {
  final CommonService commonService = CommonService();
  VideoPlayerController? _controller;
  File? _videoFile;
  bool _isControllerInitialized = false;
  bool _isLoading = true;
  String? answerTime;
  final storage = FlutterSecureStorage();
  bool _isVideoComplted = false;

  late AnimationController _animationController;
  late Timer _timer;
  List<_Heart> _hearts = [];

  final List<IconData> _icons = [
    Icons.favorite, // Heart
    Icons.local_florist, // Flower
    Icons.star, // Star
    Icons.filter_vintage, // flower
    Icons.emoji_emotions, // Smile
    Icons.bubble_chart, // Bubbles
    Icons.filter_vintage_outlined, //flower
    Icons.favorite_border, //heart
    Icons.grass //grass
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          // Update the position of the hearts
          _hearts.removeWhere((_Heart heart) => heart.opacity <= 0);
          for (var heart in _hearts) {
            heart.update();
          }
        });
      });

    _animationController.repeat();
    _timer =
        Timer.periodic(Duration(milliseconds: 500), (_) => _generateHeart());

    _fetchAndInitializeVideo();
  }

  //Call to fetch the video from server and start the video streaming
  Future<void> _fetchAndInitializeVideo() async {
    Uint8List? videoData = await getVideo();
    if (videoData != null) {
      final tempDir = await getTemporaryDirectory();
      _videoFile =
          await File('${tempDir.path}/temp_video.mp4').writeAsBytes(videoData);

      _controller = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {
            _isControllerInitialized = true;
            _isLoading = false;
            answerTime = commonService.getCurrentDateTime();
          });
          _controller?.play();

          //Listen for the end of the video
          _controller?.addListener(() async {
            if (_controller!.value.position == _controller!.value.duration) {
              if (!_isVideoComplted) {
                _isVideoComplted = true;
                int videoTime = _formatDurationForAPI(
                    _controller?.value.position ?? Duration.zero);
                VideoTimingService.handleVideoCompletion(
                  answerTime,
                  videoTime,
                  "ANSWERED",
                  widget.videoName,
                  null,
                  null,
                  null,
                  null,
                );
              }
            }
          });
        });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //API call to fetch the video from server
  Future<Uint8List?> getVideo() async {
    final apiEndPoint = Uri.parse('');
    String? jwtToken = await storage.read(key: 'jwt_token');

    try {
      final response = await http.get(apiEndPoint, headers: {
        'Authorization': 'winw $jwtToken',
      });
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("API calling failed for getVideo() ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception caught for getVideo():- $e");
      return null;
    }
  }

  //Format the duration to show the tracking time, when video is playing
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours != '00' ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  //Calulate the billable seconds
  int _formatDurationForAPI(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return (hours * 3600) + (minutes * 60) + seconds;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Function to generate hearts
  void _generateHeart() {
    Random random = Random();
    setState(() {
      for (int i = 0; i < 2; i++) {
        // Generate 2 hearts/flowers at a time
        _hearts.add(
          _Heart(
            x: random.nextDouble() * MediaQuery.of(context).size.width,
            y: MediaQuery.of(context).size.height,
            size: random.nextDouble() * 20 + 30,
            color: Colors.primaries[random.nextInt(Colors.primaries.length)],
            opacity: 1,
            icon: _icons[random.nextInt(_icons.length)],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        int videoTime =
            _formatDurationForAPI(_controller?.value.position ?? Duration.zero);
        VideoTimingService.handleVideoCompletion(
            answerTime,
            videoTime,
            "ANSWERED",
            widget.videoName,
            null,
            null,
            null,
            null); //Exited from the app when user press android /app back-button in android
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : _isControllerInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      : Text('failed to load video streaming...',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            // Positioned widget to show the video timing
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isControllerInitialized)
                      ValueListenableBuilder(
                        valueListenable: _controller!,
                        builder: (context, VideoPlayerValue value, child) {
                          return Text(
                            _formatDuration(value.position),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 55,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    int videoTime = _formatDurationForAPI(
                        _controller?.value.position ?? Duration.zero);
                    VideoTimingService.handleVideoCompletion(
                        answerTime,
                        videoTime,
                        "ANSWERED",
                        widget.videoName,
                        null,
                        null,
                        null,
                        null); //Exited the app when user press on end video call button
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.all(20),
                    shape: CircleBorder(),
                  ),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Hearts Animation
            ..._hearts.map((heart) => Positioned(
                  left: heart.x,
                  top: heart.y,
                  child: Opacity(
                    opacity: heart.opacity,
                    child: Icon(
                      heart.icon, // Use the icon field
                      size: heart.size,
                      color: heart.color,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// Class to manage heart properties
class _Heart {
  double x; // Horizontal position
  double y; // Vertical position
  double size; // Size of the heart
  Color color; // Color of the heart
  double opacity; // Opacity of the heart
  IconData icon; // The icon to display (heart or flower)

  _Heart({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.opacity,
    required this.icon,
  });

  void update() {
    y -= 2; // Move upward
    opacity = (opacity - 0.01).clamp(0.0, 1.0); // Gradually fade
  }
}
