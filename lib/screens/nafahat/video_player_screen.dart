import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/media_models.dart';
import '../../config/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaVideo video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  static const platform = MethodChannel('com.example.silkoul_ahzabou/pip');

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: false,
        forceHD: true,
        enableCaption: false,
      ),
    )..addListener(_listener);
    
    // Enable PiP capability when entering video screen
    platform.invokeMethod('enablePip');
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        // Refresh state if needed when exiting full screen
      });
    }
  }

  @override
  void deactivate() {
    // Don't pause video here regarding PiP support
    // _controller.pause(); 
    super.deactivate();
  }

  @override
  void dispose() {
    // Disable PiP capability when leaving video screen
    platform.invokeMethod('disablePip');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.tealPrimary,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        // Detect PiP or very small screen
        final isPipMode = MediaQuery.of(context).size.height < 300;

        return Scaffold(
          backgroundColor: Colors.black,
          // Hide AppBar in PiP
          appBar: isPipMode ? null : AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.video.title, 
              style: const TextStyle(color: Colors.white, fontSize: 16)
            ),
            actions: [
              // Allow manual PiP trigger
              IconButton(
                icon: const Icon(Icons.picture_in_picture_alt),
                onPressed: () {
                   platform.invokeMethod('enterPip');
                },
              )
            ],
          ),
          body: Center(
            child: isPipMode 
              ? player // Full screen player in PiP
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    player,
                    const SizedBox(height: 20),
                    if (widget.video.description != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.video.description!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
          ),
        );
      },
    );
  }
}
