// widgets/cached_image_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lyrics/Service/image_cache_service.dart';

class CachedImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    Key? key,
    this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  final ProactiveImageCacheManager _imageCacheManager =
      ProactiveImageCacheManager.instance;
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // First check if image is cached
      final cachedFile = await _imageCacheManager.getCachedImage(
        widget.imageUrl!,
      );

      if (cachedFile != null && await cachedFile.exists()) {
        setState(() {
          _cachedFile = cachedFile;
          _isLoading = false;
          _hasError = false;
        });
        return;
      }

      // If not cached and online, try to download and cache
      try {
        final downloadedFile = await _imageCacheManager.downloadAndCacheImage(
          widget.imageUrl!,
        );
        if (downloadedFile != null && await downloadedFile.exists()) {
          setState(() {
            _cachedFile = downloadedFile;
            _isLoading = false;
            _hasError = false;
          });
          return;
        }
      } catch (e) {
        // Download failed, will show network image or error
        print('Failed to cache image: $e');
      }

      // If caching failed, try network image directly
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_isLoading) {
      imageWidget = widget.placeholder ?? _buildDefaultPlaceholder();
    } else if (_hasError) {
      imageWidget = widget.errorWidget ?? _buildDefaultErrorWidget();
    } else if (_cachedFile != null) {
      // Use cached file
      imageWidget = Image.file(
        _cachedFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    } else {
      // Use network image as fallback
      imageWidget = Image.network(
        widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: Icon(
        Icons.image,
        color: Colors.white54,
        size: widget.width > 100 ? 40 : 24,
      ),
    );
  }
}
