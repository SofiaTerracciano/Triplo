// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $ImagesGen {
  const $ImagesGen();

  /// File path: images/Triplo.png
  AssetGenImage get triplo => const AssetGenImage('images/Triplo.png');

  /// File path: images/Triplo_def.png
  AssetGenImage get triploDef => const AssetGenImage('images/Triplo_def.png');

  /// File path: images/blank_tile.png
  AssetGenImage get blankTile => const AssetGenImage('images/blank_tile.png');

  /// File path: images/compass.png
  AssetGenImage get compass => const AssetGenImage('images/compass.png');

  /// File path: images/google_logo.png
  AssetGenImage get googleLogo => const AssetGenImage('images/google_logo.png');

  /// File path: images/logo.png
  AssetGenImage get logo => const AssetGenImage('images/logo.png');

  /// File path: images/offline_mode.png
  AssetGenImage get offlineMode =>
      const AssetGenImage('images/offline_mode.png');

  /// File path: images/prova.jpeg
  AssetGenImage get prova => const AssetGenImage('images/prova.jpeg');

  /// List of all assets
  List<AssetGenImage> get values => [
    triplo,
    triploDef,
    blankTile,
    compass,
    googleLogo,
    logo,
    offlineMode,
    prova,
  ];
}

class Assets {
  const Assets._();

  static const String aEnv = '.env';
  static const $ImagesGen images = $ImagesGen();
  static const String points = 'points.json';

  /// List of all assets
  static List<String> get values => [aEnv, points];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
