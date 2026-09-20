import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

/// Native in-app playback for an artwork's short video. Controllers are
/// paused whenever the media page is no longer active, and disposed on exit.
class ArtworkVideoSurface extends StatefulWidget {
  const ArtworkVideoSurface({
    super.key,
    required this.url,
    required this.active,
  });

  final String url;
  final bool active;

  @override
  State<ArtworkVideoSurface> createState() => _ArtworkVideoSurfaceState();
}

class _ArtworkVideoSurfaceState extends State<ArtworkVideoSurface>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openVideo();
  }

  Future<void> _openVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.setLooping(false);
      if (!mounted || _controller != controller) return;
      setState(() => _loading = false);
    } catch (_) {
      if (mounted && _controller == controller) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ArtworkVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      final previous = _controller;
      _controller = null;
      if (previous != null) {
        previous.dispose();
      }
      _loading = true;
      _failed = false;
      _openVideo();
    } else if (!widget.active && oldWidget.active) {
      _controller?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: AppColors.primary),
      );
    }
    if (_loading || controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            Center(
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return IconButton(
                    key: const Key('artwork_video_play_pause'),
                    iconSize: 48,
                    color: Colors.white,
                    onPressed: !widget.active
                        ? null
                        : () async {
                            if (controller.value.isPlaying) {
                              await controller.pause();
                            } else {
                              if (controller.value.position >=
                                  controller.value.duration) {
                                await controller.seekTo(Duration.zero);
                              }
                              await controller.play();
                            }
                          },
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
