import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../widgets/custom_loading.dart';

extension IconPathEx on String {

  Widget asIcon({
    double? height,
    double? width,
    BoxFit fit = BoxFit.scaleDown,
    Color? color,
    Widget? placeholder,
  }) {
    final String path = this;

    // Empty path → fallback
    if (path.isEmpty) {
      return placeholder ??
          const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
    }

    // Network URL (check this FIRST)
    if (path.startsWith('http')) {
      // Network SVG
      if (path.endsWith('.svg')) {
        return SvgPicture.network(
          path,
          fit: fit,
          height: height?.h,
          width: width?.w,
          colorFilter: color != null
              ? ColorFilter.mode(color, BlendMode.srcIn)
              : null,
          placeholderBuilder: (_) =>
          placeholder ??CustomLoading.showLoadingView(),
        );
      }

      // Network image (png, jpg, etc.)
      return Image.network(
        path,
        fit: fit,
        height: height?.h,
        width: width?.w,
        color: color,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Center(
                child: SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
        },
        errorBuilder: (_, __, ___) =>
        placeholder ??
            const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
      );
    }

    // Local SVG asset
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: fit,
        height: height?.h,
        width: width?.w,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) =>
        placeholder ?? CustomLoading.showLoadingView(),
      );
    }

    // Lottie
    if (path.endsWith('.json')) {
      return Lottie.asset(
        path,
        fit: fit,
        height: height?.h,
        width: width?.w,
      );
    }

    // Local image asset (png, jpg, etc.)
    return Image.asset(
      path,
      fit: fit,
      height: height?.h,
      width: width?.w,
      color: color,
      errorBuilder: (_, __, ___) =>
      placeholder ??
          const Center(
            child: Icon(Icons.error, color: Colors.red),
          ),
    );
  }
}