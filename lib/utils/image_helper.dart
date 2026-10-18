import 'dart:convert';
import 'package:flutter/material.dart';

class SmartImageHelper {
  /// Renders image from either Network URL (http/https) or Base64 data URI (data:image/...)
  static Widget buildImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (url.isEmpty) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.withOpacity(0.15),
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          );
    }

    if (url.startsWith('data:image/') && url.contains(',')) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder ?? Container(
            width: width,
            height: height,
            color: Colors.grey.withOpacity(0.15),
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      } catch (_) {}
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey.withOpacity(0.15),
        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
      ),
    );
  }

  /// Returns an ImageProvider from Network URL or Base64 string for CircleAvatar / BoxDecoration
  static ImageProvider getProvider(String url) {
    if (url.startsWith('data:image/') && url.contains(',')) {
      try {
        final base64String = url.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {}
    }
    return NetworkImage(
      url.isNotEmpty ? url : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    );
  }
}
