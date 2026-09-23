import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';

/// "See [pet] in action" section for the Pet Details page.
///
/// Shows a thumbnail-style preview with play button and duration. The video
/// only loads/starts when the user taps play — never autoplayed with sound.
/// Tapping opens a dedicated player with pause/play and full-screen support.
class PetVideoSection extends StatefulWidget {
  const PetVideoSection({super.key, required this.videoUrl, required this.petName});
  final String videoUrl;
  final String petName;

  @override
  State<PetVideoSection> createState() => _PetVideoSectionState();
}

class _PetVideoSectionState extends State<PetVideoSection> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _initialized = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (_controller != null || _failed) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    setState(() => _controller = controller);
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.setVolume(0); // never autoplay with sound
      setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _openPlayer() {
    if (!_initialized || _controller == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _VideoPlayerPage(controller: _controller!, petName: widget.petName),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See ${widget.petName} in action 🐾',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'A short video from the owner',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _initialized ? _openPlayer : _loadPreview,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Video unavailable 😢', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        color: AppColors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
              const SizedBox(height: 8),
              Text(
                _controller == null ? 'Tap to load preview' : 'Loading…',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.15)),
        Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.9), size: 64),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatDuration(_controller!.value.duration),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Full-screen dedicated video player. Starts paused — the user taps play.
class _VideoPlayerPage extends StatefulWidget {
  const _VideoPlayerPage({required this.controller, required this.petName});
  final VideoPlayerController controller;
  final String petName;

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    widget.controller.pause();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${widget.petName} 🎥', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(c.value.volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white),
            onPressed: () => setState(() => c.setVolume(c.value.volume > 0 ? 0 : 1)),
          ),
        ],
      ),
      body: Center(
        child: c.value.isInitialized
            ? GestureDetector(
                onTap: () => setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                }),
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              )
            : const CircularProgressIndicator(color: AppColors.primary),
      ),
      bottomNavigationBar: c.value.isInitialized
          ? SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: Icon(c.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                        onPressed: () => setState(() {
                          c.value.isPlaying ? c.pause() : c.play();
                        }),
                      ),
                      IconButton(
                        iconSize: 32,
                        color: Colors.white,
                        icon: const Icon(Icons.fullscreen),
                        onPressed: () {
                          if (MediaQuery.of(context).orientation == Orientation.portrait) {
                            SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                          } else {
                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          : null,
    );
  }
}