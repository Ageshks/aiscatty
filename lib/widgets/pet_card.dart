import 'package:aiscatty/models/favourites/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_colors.dart';

class PetCard extends StatefulWidget {
  final String petId;
  final String mediaUrl;
  final String mediaType;
  final String name, breed, location;
  final VoidCallback? onTap;
  final bool compact;

  /// True when the listing belongs to the signed in user ("Your listing").
  final bool isMine;

  const PetCard({
    super.key,
    required this.petId,
    required this.mediaUrl,
    required this.mediaType,
    required this.name,
    required this.breed,
    required this.location,
    this.onTap,
    this.compact = false,
    this.isMine = false,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;

  /// Set when the video could not be loaded, so the card shows a fallback
  /// placeholder instead of an endless spinner.
  bool _videoFailed = false;

  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  // ✅ FIXED (use existing controller) — created on demand so the card can
  // never crash when the controller is not registered yet.
  late final FavoritesController favController =
      Get.isRegistered<FavoritesController>()
          ? Get.find<FavoritesController>()
          : Get.put(FavoritesController(), permanent: true);

  @override
  void initState() {
    super.initState();

    // 🎥 VIDEO INIT (only when a video was actually stored)
    if (widget.mediaType == "video" && widget.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.mediaUrl)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((Object e) {
          // A broken or removed video must never break the whole card.
          debugPrint('⚠️ Video preview failed: $e');
          _videoFailed = true;
          if (mounted) setState(() {});
        });
    }

    // ❤️ HEART ANIMATION
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void onFavoriteTap() {
    // ❤️ Animation trigger
    _heartController.forward(from: 0);

    favController.toggleFavorite(
      widget.petId,
      {
        "id": widget.petId, // ✅ IMPORTANT
        "name": widget.name,
        "breed": widget.breed,
        "location": widget.location,
        "mediaUrl": widget.mediaUrl,
        "mediaType": widget.mediaType,
      },
    );
  }

  /// Media area with a graceful placeholder for missing/deleted media.
  Widget _buildMedia(double mediaHeight) {
    // 1) Video
    if (widget.mediaType == "video" && widget.mediaUrl.isNotEmpty) {
      if (_videoFailed) {
        return _mediaPlaceholder(mediaHeight, Icons.videocam_off_outlined);
      }
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return SizedBox(
          height: mediaHeight,
          width: double.infinity,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          const Icon(Icons.play_circle, size: 50, color: Colors.white),
        ],
      );
    }

    // 2) Image — a listing without a photo (or with a deleted one) must still
    //    render instead of throwing.
    if (widget.mediaUrl.isEmpty) {
      return _mediaPlaceholder(mediaHeight, Icons.pets);
    }

    return Image.network(
      widget.mediaUrl,
      height: mediaHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: mediaHeight,
          width: double.infinity,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      // 🛡️ Safe handling for deleted / broken media URLs.
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ Image failed for ${widget.petId}: $error');
        return _mediaPlaceholder(mediaHeight, Icons.pets);
      },
    );
  }

  Widget _mediaPlaceholder(double mediaHeight, IconData icon) {
    return Container(
      height: mediaHeight,
      width: double.infinity,
      color: AppColors.lightGreen,
      child: Center(
        child: Icon(
          icon,
          size: widget.compact ? 28 : 40,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final mediaHeight = widget.compact ? 140.0 : 200.0;
    final nameSize = widget.compact ? 14.0 : 20.0;
    final breedSize = widget.compact ? 11.0 : 14.0;
    final locSize = widget.compact ? 10.0 : 12.0;
    final marginH = widget.compact ? 0.0 : 16.0;
    final marginV = widget.compact ? 0.0 : 10.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: marginH, vertical: marginV),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [

              /// 🔥 MEDIA (IMAGE / VIDEO)
              _buildMedia(mediaHeight),

              /// 🌫️ GRADIENT OVERLAY
              Container(
                height: mediaHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              /// 🏷️ "YOUR LISTING" BADGE (only for the owner's own pets)
              if (widget.isMine)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Your listing",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: widget.compact ? 9 : 11,
                      ),
                    ),
                  ),
                ),

              /// ❤️ FAVORITE BUTTON
              Positioned(
                top: 6,
                right: 6,
                child: Obx(() {
                  final isFav =
                      favController.isFavorite(widget.petId);

                  return GestureDetector(
                    onTap: onFavoriteTap,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFav
                              ? Colors.red
                              : Colors.black,
                          size: widget.compact ? 16 : 20,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              /// 🐾 PET DETAILS
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: nameSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.breed,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: breedSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.location,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: locSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}