part of 'package:extended_text_field/src/extended/widgets/text_field.dart';

/// [TextSelectionOverlay ]
class ExtendedTextFieldTextSelectionOverlay extends _TextSelectionOverlay {
  ExtendedTextFieldTextSelectionOverlay({
    required super.value,
    required super.context,
    super.debugRequiredFor,
    required super.toolbarLayerLink,
    required super.startHandleLayerLink,
    required super.endHandleLayerLink,
    required super.renderObject,
    super.selectionControls,
    super.handlesVisible = false,
    required super.selectionDelegate,
    super.dragStartBehavior = DragStartBehavior.start,
    super.onSelectionHandleTapped,
    super.clipboardStatus,
    super.contextMenuBuilder,
    required super.magnifierConfiguration,
  });
}
