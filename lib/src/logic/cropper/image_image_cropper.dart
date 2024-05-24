import 'dart:async';
import 'dart:math';

import 'dart:typed_data';

import 'dart:ui';

import 'package:crop_your_image/src/logic/cropper/errors.dart';
import 'package:crop_your_image/src/logic/cropper/image_cropper.dart';
import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/shape.dart';

import 'package:image/image.dart' as image;

/// an implementation of [ImageCropper] using image package
class ImageImageCropper extends ImageCropper<image.Image> {
  const ImageImageCropper();

  @override
  FutureOr<Uint8List> call({
    required image.Image original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat outputFormat = ImageFormat.jpeg,
    ImageShape shape = ImageShape.rectangle,
  }) {
    if (topLeft.dx.toInt().isNegative ||
        topLeft.dy.toInt().isNegative ||
        bottomRight.dx.toInt().isNegative ||
        bottomRight.dy.toInt().isNegative ||
        topLeft.dx.toInt() > original.width ||
        topLeft.dy.toInt() > original.height ||
        bottomRight.dx.toInt() > original.width ||
        bottomRight.dy.toInt() > original.height) {
      throw InvalidRectError(topLeft: topLeft, bottomRight: bottomRight);
    }
    if (topLeft.dx > bottomRight.dx || topLeft.dy > bottomRight.dy) {
      throw NegativeSizeError(topLeft: topLeft, bottomRight: bottomRight);
    }

    final function = switch (shape) {
      ImageShape.rectangle => _doCrop,
      ImageShape.circle => _doCropCircle,
    };

    return function(
      original,
      topLeft: topLeft,
      size: Size(
        bottomRight.dx - topLeft.dx,
        bottomRight.dy - topLeft.dy,
      ),
    );
  }
}

/// process cropping image.
/// this method is supposed to be called only via compute()
Uint8List _doCrop(
  image.Image original, {
  required Offset topLeft,
  required Size size,
}) {
  return Uint8List.fromList(
    image.encodePng(
      image.copyCrop(
        original,
        x: topLeft.dx.toInt(),
        y: topLeft.dy.toInt(),
        width: size.width.toInt(),
        height: size.height.toInt(),
      ),
    ),
  );
}

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
Uint8List _doCropCircle(
  image.Image original, {
  required Offset topLeft,
  required Size size,
}) {
  final center = image.Point(
    topLeft.dx + size.width / 2,
    topLeft.dy + size.height / 2,
  );
  return Uint8List.fromList(
    image.encodePng(
      image.copyCropCircle(
        original,
        centerX: center.xi,
        centerY: center.yi,
        radius: min(size.width, size.height) ~/ 2,
      ),
    ),
  );
}
