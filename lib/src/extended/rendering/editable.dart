part of 'package:extended_text_field/src/extended/widgets/text_field.dart';

/// [RenderEditable]
class ExtendedRenderEditable extends _RenderEditable {
  ExtendedRenderEditable({
    super.text,
    required super.textDirection,
    super.textAlign = TextAlign.start,
    super.cursorColor,
    super.backgroundCursorColor,
    super.showCursor,
    super.hasFocus,
    required super.startHandleLayerLink,
    required super.endHandleLayerLink,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.strutStyle,
    super.selectionColor,
    super.textScaleFactor = 1.0,
    super.selection,
    required super.offset,
    super.onCaretChanged,
    super.ignorePointer = false,
    super.readOnly = false,
    super.forceLine = true,
    super.textHeightBehavior,
    super.textWidthBasis = TextWidthBasis.parent,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.locale,
    super.cursorWidth = 1.0,
    super.cursorHeight,
    super.cursorRadius,
    super.paintCursorAboveText = false,
    super.cursorOffset = Offset.zero,
    super.devicePixelRatio = 1.0,
    super.selectionHeightStyle = ui.BoxHeightStyle.tight,
    super.selectionWidthStyle = ui.BoxWidthStyle.tight,
    super.enableInteractiveSelection,
    super.floatingCursorAddedMargin = const EdgeInsets.fromLTRB(4, 4, 4, 5),
    super.promptRectRange,
    super.promptRectColor,
    super.clipBehavior = Clip.hardEdge,
    required super.textSelectionDelegate,
    super.painter,
    super.foregroundPainter,
    super.children,
    this.supportSpecialText = false,
  });

  bool _hasSpecialInlineSpanBase = false;
  bool supportSpecialText = false;

  bool get hasSpecialInlineSpanBase =>
      supportSpecialText && _hasSpecialInlineSpanBase;

  @override
  String get plainText {
    return ExtendedTextLibraryUtils.textSpanToActualText(_textPainter.text!);
  }

  @override
  void _extractPlaceholderSpans(InlineSpan? span) {
    _placeholderSpans = <PlaceholderSpan>[];
    span?.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        _placeholderSpans.add(span);
      }
      if (span is SpecialInlineSpanBase) {
        _hasSpecialInlineSpanBase = true;
      }
      return true;
    });
  }

  @override
  void selectWordEdge({required SelectionChangedCause cause}) {
    _computeTextMetricsIfNeeded();
    assert(_lastTapDownPosition != null);
    final TextPosition position = _textPainter.getPositionForOffset(
        globalToLocal(_lastTapDownPosition! - _paintOffset));
    final TextRange word = _textPainter.getWordBoundary(position);
    late TextSelection newSelection;
    if (position.offset <= word.start) {
      newSelection = TextSelection.collapsed(offset: word.start);
    } else {
      newSelection = TextSelection.collapsed(
          offset: word.end, affinity: TextAffinity.upstream);
    }

    /// zmtzawqlp
    newSelection = hasSpecialInlineSpanBase
        ? ExtendedTextLibraryUtils
            .convertTextPainterSelectionToTextInputSelection(
                text!, newSelection)
        : newSelection;
    _setSelection(newSelection, cause);
  }

  @override
  void selectPositionAt(
      {required Offset from,
      Offset? to,
      required SelectionChangedCause cause}) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    TextPosition fromPosition =
        _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
    TextPosition? toPosition = to == null
        ? null
        : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));
    //zmt
    if (hasSpecialInlineSpanBase) {
      fromPosition =
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
              text!, fromPosition)!;
      toPosition =
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
              text!, toPosition);
    }
    final int baseOffset = fromPosition.offset;
    final int extentOffset = toPosition?.offset ?? fromPosition.offset;

    final TextSelection newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );

    _setSelection(newSelection, cause);
  }

  @override
  TextSelection _getWordAtOffset(TextPosition position) {
    final TextSelection selection = super._getWordAtOffset(position);

    /// zmt
    return hasSpecialInlineSpanBase
        ? ExtendedTextLibraryUtils
            .convertTextPainterSelectionToTextInputSelection(text!, selection,
                selectWord: true)
        : selection;
  }

  @override
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    _computeTextMetricsIfNeeded();

    final Offset paintOffset = _paintOffset;

    // zmtzawqlp
    if (hasSpecialInlineSpanBase) {
      selection = ExtendedTextLibraryUtils
          .convertTextInputSelectionToTextPainterSelection(text!, selection);
    }

    final List<ui.TextBox> boxes = selection.isCollapsed
        ? <ui.TextBox>[]
        : _textPainter.getBoxesForSelection(selection,
            boxHeightStyle: selectionHeightStyle,
            boxWidthStyle: selectionWidthStyle);
    if (boxes.isEmpty) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.

      final Offset caretOffset =
          _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final Offset start =
          Offset(0.0, preferredLineHeight) + caretOffset + paintOffset;

      // zmtzawqlp
      // double? caretHeight;
      // final ValueChanged<double> caretHeightCallBack = (double value) {
      //   caretHeight = value;
      // };

      // final Offset caretOffset = ExtendedTextLibraryUtils.getCaretOffset(
      //   TextPosition(
      //       offset: selection.extentOffset,
      //       affinity: selection.extent.affinity),
      //   _textPainter,
      //   _placeholderSpans.isNotEmpty,
      //   caretHeightCallBack: caretHeightCallBack,
      //   effectiveOffset: _paintOffset,
      //   caretPrototype: _caretPrototype,
      // );

      // final Offset start =
      //     Offset(0.0, caretHeight ?? preferredLineHeight) + caretOffset;
      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final Offset start = Offset(
              clampDouble(boxes.first.start, 0, _textPainter.size.width),
              boxes.first.bottom) +
          paintOffset;
      final Offset end = Offset(
              clampDouble(boxes.last.end, 0, _textPainter.size.width),
              boxes.last.bottom) +
          paintOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }
  }

  @override
  set selection(TextSelection? value) {
    if (_selection == value) {
      return;
    }
    _selection = value;
    _selectionPainter.highlightedRange = getActualSelection();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setPromptRectRange(TextRange? newRange) {
    _autocorrectHighlightPainter.highlightedRange =
        getActualSelection(newRange: newRange);
  }

  TextSelection? getActualSelection({TextRange? newRange}) {
    TextSelection? value = selection;
    if (newRange != null) {
      value =
          TextSelection(baseOffset: newRange.start, extentOffset: newRange.end);
    }

    return hasSpecialInlineSpanBase
        ? ExtendedTextLibraryUtils
            .convertTextInputSelectionToTextPainterSelection(text!, value!)
        : value;
  }
}
