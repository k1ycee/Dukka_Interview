import 'package:image_editor/image_editor.dart';

String loremPicsumImageLink(String id) =>
    'https://picsum.photos/id/23$id/200/300';

List<Option> editOptions = [
  ColorOption(
      matrix: [2, 0, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0, 1, 0]),
  ColorOption(
      matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 0]),
  const RotateOption(180),
  const ScaleOption(
    100,
    100,
  ),
  ColorOption(matrix: [
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ])
];
