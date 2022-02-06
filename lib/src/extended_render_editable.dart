// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unnecessary_null_comparison, always_put_control_body_on_new_line

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui
    show
        TextBox,
        BoxHeightStyle,
        BoxWidthStyle,
        LineMetrics,
        PlaceholderAlignment;

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const EdgeInsets _kFloatingCaretSizeIncrease =
    EdgeInsets.symmetric(horizontal: 0.5, vertical: 1.0);

// The corner radius of the floating cursor in pixels.
const Radius _kFloatingCaretRadius = Radius.circular(1.0);

/// The consecutive sequence of [TextPosition]s that the caret should move to
/// when the user navigates the paragraph using the upward arrow key or the
/// downward arrow key.
///
/// {@template flutter.rendering.RenderEditable.verticalArrowKeyMovement}
/// When the user presses the upward arrow key or the downward arrow key, on
/// many platforms (macOS for instance), the caret will move to the previous
/// line or the next line, while maintaining its original horizontal location.
/// When it encounters a shorter line, the caret moves to the closest horizontal
/// location within that line, and restores the original horizontal location
/// when a long enough line is encountered.
///
/// Additionally, the caret will move to the beginning of the document if the
/// upward arrow key is pressed and the caret is already on the first line. If
/// the downward arrow key is pressed next, the caret will restore its original
/// horizontal location and move to the second line. Similarly the caret moves
/// to the end of the document if the downward arrow key is pressed when it's
/// already on the last line.
///
/// Consider a left-aligned paragraph:
///   aa|
///   a
///   aaa
/// where the caret was initially placed at the end of the first line. Pressing
/// the downward arrow key once will move the caret to the end of the second
/// line, and twice the arrow key moves to the third line after the second "a"
/// on that line. Pressing the downward arrow key again, the caret will move to
/// the end of the third line (the end of the document). Pressing the upward
/// arrow key in this state will result in the caret moving to the end of the
/// second line.
///
/// Vertical caret runs are typically interrupted when the layout of the text
/// changes (including when the text itself changes), or when the selection is
/// changed by other input events or programmatically (for example, when the
/// user pressed the left arrow key).
/// {@endtemplate}
///
/// The [movePrevious] method moves the caret location (which is
/// [VerticalCaretMovementRun.current]) to the previous line, and in case
/// the caret is already on the first line, the method does nothing and returns
/// false. Similarly the [moveNext] method moves the caret to the next line, and
/// returns false if the caret is already on the last line.
///
/// If the underlying paragraph's layout changes, [isValid] becomes false and
/// the [VerticalCaretMovementRun] must not be used. The [isValid] property must
/// be checked before calling [movePrevious] and [moveNext], or accessing
/// [current].
class VerticalCaretMovementRun extends BidirectionalIterator<TextPosition> {
  VerticalCaretMovementRun._(
    this._editable,
    this._lineMetrics,
    this._currentTextPosition,
    this._currentLine,
    this._currentOffset,
  );

  Offset _currentOffset;
  int _currentLine;
  TextPosition _currentTextPosition;

  final List<ui.LineMetrics> _lineMetrics;
  final ExtendedRenderEditable _editable;

  bool _isValid = true;

  /// Whether this [VerticalCaretMovementRun] can still continue.
  ///
  /// A [VerticalCaretMovementRun] run is valid if the underlying text layout
  /// hasn't changed.
  ///
  /// The [current] value and the [movePrevious] and [moveNext] methods must not
  /// be accessed when [isValid] is false.
  bool get isValid {
    if (!_isValid) {
      return false;
    }
    final List<ui.LineMetrics> newLineMetrics =
        _editable._textPainter.computeLineMetrics();
    // Use the implementation detail of the computeLineMetrics method to figure
    // out if the current text layout has been invalidated.
    if (!identical(newLineMetrics, _lineMetrics)) {
      _isValid = false;
    }
    return _isValid;
  }

  final Map<int, MapEntry<Offset, TextPosition>> _positionCache =
      <int, MapEntry<Offset, TextPosition>>{};

  MapEntry<Offset, TextPosition> _getTextPositionForLine(int lineNumber) {
    assert(isValid);
    assert(lineNumber >= 0);
    final MapEntry<Offset, TextPosition>? cachedPosition =
        _positionCache[lineNumber];
    if (cachedPosition != null) {
      return cachedPosition;
    }
    assert(lineNumber != _currentLine);

    final Offset newOffset =
        Offset(_currentOffset.dx, _lineMetrics[lineNumber].baseline);
    final TextPosition closestPosition =
        _editable._textPainter.getPositionForOffset(newOffset);
    final MapEntry<Offset, TextPosition> position =
        MapEntry<Offset, TextPosition>(newOffset, closestPosition);
    _positionCache[lineNumber] = position;
    return position;
  }

  @override
  TextPosition get current {
    assert(isValid);
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    assert(isValid);
    if (_currentLine + 1 >= _lineMetrics.length) {
      return false;
    }
    final MapEntry<Offset, TextPosition> position =
        _getTextPositionForLine(_currentLine + 1);
    _currentLine += 1;
    _currentOffset = position.key;
    _currentTextPosition = position.value;
    return true;
  }

  @override
  bool movePrevious() {
    assert(isValid);
    if (_currentLine <= 0) {
      return false;
    }
    final MapEntry<Offset, TextPosition> position =
        _getTextPositionForLine(_currentLine - 1);
    _currentLine -= 1;
    _currentOffset = position.key;
    _currentTextPosition = position.value;
    return true;
  }
}

/// Displays some text in a scrollable container with a potentially blinking
/// cursor and with gesture recognizers.
///
/// This is the renderer for an editable text field. It does not directly
/// provide affordances for editing the text, but it does handle text selection
/// and manipulation of the text cursor.
///
/// The [text] is displayed, scrolled by the given [offset], aligned according
/// to [textAlign]. The [maxLines] property controls whether the text displays
/// on one line or many. The [selection], if it is not collapsed, is painted in
/// the [selectionColor]. If it _is_ collapsed, then it represents the cursor
/// position. The cursor is shown while [showCursor] is true. It is painted in
/// the [cursorColor].
///
/// If, when the render object paints, the caret is found to have changed
/// location, [onCaretChanged] is called.
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
class ExtendedRenderEditable extends ExtendedTextSelectionRenderObject {
  /// Creates a render object that implements the visual aspects of a text field.
  ///
  /// The [textAlign] argument must not be null. It defaults to [TextAlign.start].
  ///
  /// The [textDirection] argument must not be null.
  ///
  /// If [showCursor] is not specified, then it defaults to hiding the cursor.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is 1, meaning this is a single-line
  /// text field. If it is not null, it must be greater than zero.
  ///
  /// The [offset] is required and must not be null. You can use [new
  /// ViewportOffset.zero] if you have no need for scrolling.
  ExtendedRenderEditable({
    required InlineSpan text,
    required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    Color? cursorColor,
    Color? backgroundCursorColor,
    ValueNotifier<bool>? showCursor,
    bool? hasFocus,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    StrutStyle? strutStyle,
    Color? selectionColor,
    double textScaleFactor = 1.0,
    TextSelection? selection,
    required ViewportOffset offset,
    this.onCaretChanged,
    this.ignorePointer = false,
    bool readOnly = false,
    bool forceLine = true,
    TextHeightBehavior? textHeightBehavior,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    String obscuringCharacter = '•',
    bool obscureText = false,
    Locale? locale,
    double cursorWidth = 1.0,
    double? cursorHeight,
    Radius? cursorRadius,
    bool paintCursorAboveText = false,
    Offset cursorOffset = Offset.zero,
    double devicePixelRatio = 1.0,
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    bool? enableInteractiveSelection,
    this.floatingCursorAddedMargin = const EdgeInsets.fromLTRB(4, 4, 4, 5),
    TextRange? promptRectRange,
    Color? promptRectColor,
    Clip clipBehavior = Clip.hardEdge,
    required this.textSelectionDelegate,
    ExtendedRenderEditablePainter? painter,
    ExtendedRenderEditablePainter? foregroundPainter,
    this.supportSpecialText = false,
    List<RenderBox>? children,
  })  : assert(textAlign != null),
        assert(textDirection != null,
            'RenderEditable created without a textDirection.'),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(startHandleLayerLink != null),
        assert(endHandleLayerLink != null),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(expands != null),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(textScaleFactor != null),
        assert(offset != null),
        assert(ignorePointer != null),
        assert(textWidthBasis != null),
        assert(paintCursorAboveText != null),
        assert(obscuringCharacter != null &&
            obscuringCharacter.characters.length == 1),
        assert(obscureText != null),
        assert(textSelectionDelegate != null),
        assert(cursorWidth != null && cursorWidth >= 0.0),
        assert(cursorHeight == null || cursorHeight >= 0.0),
        assert(readOnly != null),
        assert(forceLine != null),
        assert(devicePixelRatio != null),
        assert(selectionHeightStyle != null),
        assert(selectionWidthStyle != null),
        assert(clipBehavior != null),
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          locale: locale,
          strutStyle: strutStyle,
          textHeightBehavior: textHeightBehavior,
          textWidthBasis: textWidthBasis,
        ),
        _showCursor = showCursor ?? ValueNotifier<bool>(false),
        _maxLines = maxLines,
        _minLines = minLines,
        _expands = expands,
        _selection = selection,
        _offset = offset,
        _cursorWidth = cursorWidth,
        _cursorHeight = cursorHeight,
        _paintCursorOnTop = paintCursorAboveText,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio,
        _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink,
        _obscuringCharacter = obscuringCharacter,
        _obscureText = obscureText,
        _readOnly = readOnly,
        _forceLine = forceLine,
        _clipBehavior = clipBehavior {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);
    this.hasFocus = hasFocus ?? false;
    _selectionPainter.highlightColor = selectionColor;
    _selectionPainter.highlightedRange = selection;
    _selectionPainter.selectionHeightStyle = selectionHeightStyle;
    _selectionPainter.selectionWidthStyle = selectionWidthStyle;

    _autocorrectHighlightPainter.highlightColor = promptRectColor;
    _autocorrectHighlightPainter.highlightedRange = promptRectRange;

    _caretPainter.caretColor = cursorColor;
    _caretPainter.cursorRadius = cursorRadius;
    _caretPainter.cursorOffset = cursorOffset;
    _caretPainter.backgroundCursorColor = backgroundCursorColor;

    _updateForegroundPainter(foregroundPainter);
    _updatePainter(painter);
    addAll(children);
    extractPlaceholderSpans(text);
  }

  ///whether to support build SpecialText

  bool supportSpecialText = false;
  @override
  bool get hasSpecialInlineSpanBase =>
      supportSpecialText && super.hasSpecialInlineSpanBase;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData)
      child.parentData = TextParentData();
  }

  /// Child render objects
  _RenderEditableCustomPaint? _foregroundRenderObject;
  _RenderEditableCustomPaint? _backgroundRenderObject;

  @override
  void dispose() {
    _foregroundRenderObject?.dispose();
    _foregroundRenderObject = null;
    _backgroundRenderObject?.dispose();
    _backgroundRenderObject = null;
    _clipRectLayer.layer = null;
    _cachedBuiltInForegroundPainters?.dispose();
    _cachedBuiltInPainters?.dispose();
    super.dispose();
  }

  void _updateForegroundPainter(ExtendedRenderEditablePainter? newPainter) {
    final _CompositeRenderEditablePainter effectivePainter = newPainter == null
        ? _builtInForegroundPainters
        : _CompositeRenderEditablePainter(
            painters: <ExtendedRenderEditablePainter>[
                _builtInForegroundPainters,
                newPainter,
              ]);

    if (_foregroundRenderObject == null) {
      final _RenderEditableCustomPaint foregroundRenderObject =
          _RenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(foregroundRenderObject);
      _foregroundRenderObject = foregroundRenderObject;
    } else {
      _foregroundRenderObject?.painter = effectivePainter;
    }
    _foregroundPainter = newPainter;
  }

  /// The [ExtendedRenderEditablePainter] to use for painting above this
  /// [RenderEditable]'s text content.
  ///
  /// The new [ExtendedRenderEditablePainter] will replace the previously specified
  /// foreground painter, and schedule a repaint if the new painter's
  /// `shouldRepaint` method returns true.
  ExtendedRenderEditablePainter? get foregroundPainter => _foregroundPainter;
  ExtendedRenderEditablePainter? _foregroundPainter;
  set foregroundPainter(ExtendedRenderEditablePainter? newPainter) {
    if (newPainter == _foregroundPainter) return;
    _updateForegroundPainter(newPainter);
  }

  void _updatePainter(ExtendedRenderEditablePainter? newPainter) {
    final _CompositeRenderEditablePainter effectivePainter = newPainter == null
        ? _builtInPainters
        : _CompositeRenderEditablePainter(
            painters: <ExtendedRenderEditablePainter>[
                _builtInPainters,
                newPainter
              ]);

    if (_backgroundRenderObject == null) {
      final _RenderEditableCustomPaint backgroundRenderObject =
          _RenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(backgroundRenderObject);
      _backgroundRenderObject = backgroundRenderObject;
    } else {
      _backgroundRenderObject?.painter = effectivePainter;
    }
    _painter = newPainter;
  }

  /// Sets the [ExtendedRenderEditablePainter] to use for painting beneath this
  /// [RenderEditable]'s text content.
  ///
  /// The new [ExtendedRenderEditablePainter] will replace the previously specified
  /// painter, and schedule a repaint if the new painter's `shouldRepaint`
  /// method returns true.
  ExtendedRenderEditablePainter? get painter => _painter;
  ExtendedRenderEditablePainter? _painter;
  set painter(ExtendedRenderEditablePainter? newPainter) {
    if (newPainter == _painter) return;
    _updatePainter(newPainter);
  }

  // Caret Painters:
  // The floating painter. This painter paints the regular caret as well.
  late final _FloatingCursorPainter _caretPainter =
      _FloatingCursorPainter(_onCaretChanged);

  // Text Highlight painters:
  final TextHighlightPainter _selectionPainter = TextHighlightPainter();
  final TextHighlightPainter _autocorrectHighlightPainter =
      TextHighlightPainter();

  _CompositeRenderEditablePainter get _builtInForegroundPainters =>
      _cachedBuiltInForegroundPainters ??= _createBuiltInForegroundPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInForegroundPainters;
  _CompositeRenderEditablePainter _createBuiltInForegroundPainters() {
    return _CompositeRenderEditablePainter(
      painters: <ExtendedRenderEditablePainter>[
        if (paintCursorAboveText) _caretPainter,
      ],
    );
  }

  _CompositeRenderEditablePainter get _builtInPainters =>
      _cachedBuiltInPainters ??= _createBuiltInPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInPainters;
  _CompositeRenderEditablePainter _createBuiltInPainters() {
    return _CompositeRenderEditablePainter(
      painters: <ExtendedRenderEditablePainter>[
        _autocorrectHighlightPainter,
        _selectionPainter,
        if (!paintCursorAboveText) _caretPainter,
      ],
    );
  }

  Rect? _lastCaretRect;
  // TODO(LongCatIsLooong): currently EditableText uses this callback to keep
  // the text field visible. But we don't always paint the caret, for example
  // when the selection is not collapsed.
  /// Called during the paint phase when the caret location changes.
  CaretChangedHandler? onCaretChanged;
  void _onCaretChanged(Rect caretRect) {
    if (_lastCaretRect != caretRect) onCaretChanged?.call(caretRect);
    _lastCaretRect = onCaretChanged == null ? null : caretRect;
  }

  /// Whether the [handleEvent] will propagate pointer events to selection
  /// handlers.
  ///
  /// If this property is true, the [handleEvent] assumes that this renderer
  /// will be notified of input gestures via [handleTapDown], [handleTap],
  /// [handleDoubleTap], and [handleLongPress].
  ///
  /// If there are any gesture recognizers in the text span, the [handleEvent]
  /// will still propagate pointer events to those recognizers.
  ///
  /// The default value of this property is false.
  @override
  bool ignorePointer;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  TextHeightBehavior? get textHeightBehavior => _textPainter.textHeightBehavior;
  set textHeightBehavior(TextHeightBehavior? value) {
    if (_textPainter.textHeightBehavior == value) {
      return;
    }
    _textPainter.textHeightBehavior = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.text.DefaultTextStyle.textWidthBasis}
  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    if (_textPainter.textWidthBasis == value) {
      return;
    }
    _textPainter.textWidthBasis = value;
    markNeedsTextLayout();
  }

  /// The pixel ratio of the current device.
  ///
  /// Should be obtained by querying MediaQuery for the devicePixelRatio.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsTextLayout();
  }

  /// Character used for obscuring text if [obscureText] is true.
  ///
  /// Cannot be null, and must have a length of exactly one.
  String get obscuringCharacter => _obscuringCharacter;
  String _obscuringCharacter;
  set obscuringCharacter(String value) {
    if (_obscuringCharacter == value) {
      return;
    }
    assert(value != null && value.characters.length == 1);
    _obscuringCharacter = value;
    markNeedsLayout();
  }

  /// Whether to hide the text being edited (e.g., for passwords).
  @override
  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value) return;
    _obscureText = value;
    markNeedsSemanticsUpdate();
  }

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  @override
  ui.BoxHeightStyle get selectionHeightStyle =>
      _selectionPainter.selectionHeightStyle;
  set selectionHeightStyle(ui.BoxHeightStyle value) {
    _selectionPainter.selectionHeightStyle = value;
  }

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  @override
  ui.BoxWidthStyle get selectionWidthStyle =>
      _selectionPainter.selectionWidthStyle;
  set selectionWidthStyle(ui.BoxWidthStyle value) {
    _selectionPainter.selectionWidthStyle = value;
  }

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  @override
  TextSelectionDelegate textSelectionDelegate;

  /// Track whether position of the start of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "Hello", then scrolls so only "World" is visible, this will become false.
  /// If the user scrolls back so that the "H" is visible again, this will
  /// become true.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  @override
  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  /// Track whether position of the end of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "World", then scrolls so only "Hello" is visible, this will become
  /// 'false'. If the user scrolls back so that the "d" is visible again, this
  /// will become 'true'.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  @override
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(
      Offset effectiveOffset, TextSelection selection) {
    ///zmt
    ///caret may be less than 0, because it's bigger than text
    // ///
    // issue: #49
    // final Rect visibleRegion = Offset(0.0, _visibleRegionMinY) & size;
    final Rect visibleRegion = Offset.zero & size;

    //getCaretOffset ready has effectiveOffset
    final Offset startOffset = getCaretOffset(
      TextPosition(
        offset: selection.start,
        affinity: selection.affinity,
      ),
      effectiveOffset: effectiveOffset,
      caretPrototype: _caretPrototype,
    );
    // Check if the selection is visible with an approximation because a
    // difference between rounded and unrounded values causes the caret to be
    // reported as having a slightly (< 0.5) negative y offset. This rounding
    // happens in paragraph.cc's layout and TextPainer's
    // _applyFloatingPointHack. Ideally, the rounding mismatch will be fixed and
    // this can be changed to be a strict check instead of an approximation.
    const double visibleRegionSlop = 0.5;
    _selectionStartInViewport.value =
        visibleRegion.inflate(visibleRegionSlop).contains(startOffset);

    //getCaretOffset ready has effectiveOffset
    final Offset endOffset = getCaretOffset(
      TextPosition(offset: selection.end, affinity: selection.affinity),
      effectiveOffset: effectiveOffset,
      caretPrototype: _caretPrototype,
    );

    _selectionEndInViewport.value =
        visibleRegion.inflate(visibleRegionSlop).contains(endOffset);
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    // Tell the painers to repaint since text layout may have changed.
    _foregroundRenderObject?.markNeedsPaint();
    _backgroundRenderObject?.markNeedsPaint();
  }

  // Retuns a cached plain text version of the text in the painter.
  String? _cachedPlainText;
  @override
  String get plainText {
    _cachedPlainText ??= textSpanToActualText(_textPainter.text!);
    return _cachedPlainText!;
  }

  /// The text to display.
  @override
  InlineSpan? get text => _textPainter.text;
  final TextPainter _textPainter;
  AttributedString? _cachedAttributedValue;
  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;
  set text(InlineSpan? value) {
    if (_textPainter.text == value) {
      return;
    }
    _textPainter.text = value;
    _cachedPlainText = null;
    _cachedAttributedValue = null;
    _cachedCombinedSemanticsInfos = null;
    extractPlaceholderSpans(value);
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// How the text should be aligned horizontally.
  ///
  /// This must not be null.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    markNeedsTextLayout();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  // TextPainter.textDirection is nullable, but it is set to a
  // non-null value in the RenderEditable constructor and we refuse to
  // set it to null here, so _textPainter.textDirection cannot be null.
  @override
  TextDirection get textDirection => _textPainter.textDirection!;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value) return;
    _textPainter.textDirection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// Used by this renderer's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  ///
  /// If this value is null, a system-dependent algorithm is used to select
  /// the font.
  Locale? get locale => _textPainter.locale;
  set locale(Locale? value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    markNeedsTextLayout();
  }

  /// The [StrutStyle] used by the renderer's internal [TextPainter] to
  /// determine the strut to use.
  StrutStyle? get strutStyle => _textPainter.strutStyle;
  set strutStyle(StrutStyle? value) {
    if (_textPainter.strutStyle == value) return;
    _textPainter.strutStyle = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the cursor.
  Color? get cursorColor => _caretPainter.caretColor;
  set cursorColor(Color? value) {
    _caretPainter.caretColor = value;
  }

  /// The color to use when painting the cursor aligned to the text while
  /// rendering the floating cursor.
  ///
  /// The default is light grey.
  Color? get backgroundCursorColor => _caretPainter.backgroundCursorColor;
  set backgroundCursorColor(Color? value) {
    _caretPainter.backgroundCursorColor = value;
  }

  /// Whether to paint the cursor.
  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value) return;
    if (attached) _showCursor.removeListener(_showHideCursor);
    _showCursor = value;
    if (attached) {
      _showHideCursor();
      _showCursor.addListener(_showHideCursor);
    }
  }

  void _showHideCursor() {
    _caretPainter.shouldPaint = showCursor.value;
  }

  /// Whether this rendering object will take a full line regardless the text width.
  @override
  bool get forceLine => _forceLine;
  bool _forceLine = false;
  set forceLine(bool value) {
    assert(value != null);
    if (_forceLine == value) return;
    _forceLine = value;
    markNeedsLayout();
  }

  /// Whether this rendering object is read only.
  @override
  bool get readOnly => _readOnly;
  bool _readOnly = false;
  set readOnly(bool value) {
    assert(value != null);
    if (_readOnly == value) return;
    _readOnly = value;
    markNeedsSemanticsUpdate();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  ///
  /// If this is null, there is no limit to the number of lines.
  ///
  /// When this is not null, the intrinsic height of the render object is the
  /// height of one line of text multiplied by this value. In other words, this
  /// also controls the height of the actual editing widget.
  int? get maxLines => _maxLines;
  int? _maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (maxLines == value) return;
    _maxLines = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.editableText.minLines}
  int? get minLines => _minLines;
  int? _minLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set minLines(int? value) {
    assert(value == null || value > 0);
    if (minLines == value) return;
    _minLines = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.editableText.expands}
  bool get expands => _expands;
  bool _expands;
  set expands(bool value) {
    assert(value != null);
    if (expands == value) return;
    _expands = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the selection.
  @override
  Color? get selectionColor => _selectionPainter.highlightColor;
  @override
  set selectionColor(Color? value) {
    _selectionPainter.highlightColor = value;
  }

  /// The region of text that is selected, if any.
  ///
  /// The caret position is represented by a collapsed selection.
  ///
  /// If [selection] is null, there is no selection and attempts to
  /// manipulate the selection will throw.
  @override
  TextSelection? get selection => _selection;
  TextSelection? _selection;
  @override
  set selection(TextSelection? value) {
    if (_selection == value) return;
    _selection = value;
    _selectionPainter.highlightedRange = getActualSelection();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The offset at which the text should be painted.
  ///
  /// If the text content is larger than the editable line itself, the editable
  /// line clips the text. This property controls which part of the text is
  /// visible by shifting the text by the given offset before clipping.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (_offset == value) return;
    if (attached) _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  /// How thick the cursor will be.
  double get cursorWidth => _cursorWidth;
  double _cursorWidth = 1.0;
  set cursorWidth(double value) {
    if (_cursorWidth == value) return;
    _cursorWidth = value;
    markNeedsLayout();
  }

  /// How tall the cursor will be.
  ///
  /// This can be null, in which case the getter will actually return [preferredLineHeight].
  ///
  /// Setting this to itself fixes the value to the current [preferredLineHeight]. Setting
  /// this to null returns the behavior of deferring to [preferredLineHeight].
  // TODO(ianh): This is a confusing API. We should have a separate getter for the effective cursor height.
  double get cursorHeight => _cursorHeight ?? preferredLineHeight;
  double? _cursorHeight;
  set cursorHeight(double? value) {
    if (_cursorHeight == value) return;
    _cursorHeight = value;
    markNeedsLayout();
  }

  /// {@template flutter.rendering.RenderEditable.paintCursorAboveText}
  /// If the cursor should be painted on top of the text or underneath it.
  ///
  /// By default, the cursor should be painted on top for iOS platforms and
  /// underneath for Android platforms.
  /// {@endtemplate}
  bool get paintCursorAboveText => _paintCursorOnTop;
  bool _paintCursorOnTop;
  set paintCursorAboveText(bool value) {
    if (_paintCursorOnTop == value) return;
    _paintCursorOnTop = value;
    // Clear cached built-in painters and reconfigure painters.
    _cachedBuiltInForegroundPainters = null;
    _cachedBuiltInPainters = null;
    // Call update methods to rebuild and set the effective painters.
    _updateForegroundPainter(_foregroundPainter);
    _updatePainter(_painter);
  }

  /// {@template flutter.rendering.RenderEditable.cursorOffset}
  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  /// {@endtemplate}
  Offset get cursorOffset => _caretPainter.cursorOffset;
  set cursorOffset(Offset value) {
    _caretPainter.cursorOffset = value;
  }

  /// How rounded the corners of the cursor should be.
  ///
  /// A null value is the same as [Radius.zero].
  Radius? get cursorRadius => _caretPainter.cursorRadius;
  set cursorRadius(Radius? value) {
    _caretPainter.cursorRadius = value;
  }

  /// The [LayerLink] of start selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
  @override
  LayerLink get startHandleLayerLink => _startHandleLayerLink;
  LayerLink _startHandleLayerLink;
  @override
  set startHandleLayerLink(LayerLink? value) {
    if (_startHandleLayerLink == value) return;
    _startHandleLayerLink = value!;
    markNeedsPaint();
  }

  /// The [LayerLink] of end selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
  @override
  LayerLink get endHandleLayerLink => _endHandleLayerLink;
  LayerLink _endHandleLayerLink;
  @override
  set endHandleLayerLink(LayerLink? value) {
    if (_endHandleLayerLink == value) return;
    _endHandleLayerLink = value!;
    markNeedsPaint();
  }

  /// The padding applied to text field. Used to determine the bounds when
  /// moving the floating cursor.
  ///
  /// Defaults to a padding with left, top and right set to 4, bottom to 5.
  EdgeInsets floatingCursorAddedMargin;

  bool _floatingCursorOn = false;
  late TextPosition _floatingCursorTextPosition;

  /// Whether to allow the user to change the selection.
  ///
  /// Since [RenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// This field is used by [selectionEnabled] (which then controls
  /// the accessibility hints mentioned above). When null,
  /// [obscureText] is used to determine the value of
  /// [selectionEnabled] instead.
  bool? get enableInteractiveSelection => _enableInteractiveSelection;
  bool? _enableInteractiveSelection;
  set enableInteractiveSelection(bool? value) {
    if (_enableInteractiveSelection == value) return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// Whether interactive selection are enabled based on the values of
  /// [enableInteractiveSelection] and [obscureText].
  ///
  /// Since [RenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// By default, [enableInteractiveSelection] is null, [obscureText] is false,
  /// and this getter returns true.
  ///
  /// If [enableInteractiveSelection] is null and [obscureText] is true, then this
  /// getter returns false. This is the common case for password fields.
  ///
  /// If [enableInteractiveSelection] is non-null then its value is
  /// returned. An application might [enableInteractiveSelection] to
  /// true to enable interactive selection for a password field, or to
  /// false to unconditionally disable interactive selection.
  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

  /// The color used to paint the prompt rectangle.
  ///
  /// The prompt rectangle will only be requested on non-web iOS applications.
  // TODO(ianh): We should change the getter to return null when _promptRectRange is null
  // (otherwise, if you set it to null and then get it, you get back non-null).
  // Alternatively, we could stop supporting setting this to null.
  Color? get promptRectColor => _autocorrectHighlightPainter.highlightColor;
  set promptRectColor(Color? newValue) {
    _autocorrectHighlightPainter.highlightColor = newValue;
  }

  /// Dismisses the currently displayed prompt rectangle and displays a new prompt rectangle
  /// over [newRange] in the given color [promptRectColor].
  ///
  /// The prompt rectangle will only be requested on non-web iOS applications.
  ///
  /// When set to null, the currently displayed prompt rectangle (if any) will be dismissed.
  // ignore: use_setters_to_change_properties, (API predates enforcing the lint)
  void setPromptRectRange(TextRange? newRange) {
    _autocorrectHighlightPainter.highlightedRange =
        getActualSelection(newRange: newRange);
  }

  /// The maximum amount the text is allowed to scroll.
  ///
  /// This value is only valid after layout and can change as additional
  /// text is entered or removed in order to accommodate expanding when
  /// [expands] is set to true.
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent = 0;

  double get _caretMargin => _kCaretGap + cursorWidth;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode] and [_combineSemanticsInfo].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Queue<SemanticsNode>? _cachedChildNodes;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = _textPainter.text!.getSemanticsInformation();
    // TODO(chunhtai): the macOS does not provide a public API to support text
    // selections across multiple semantics nodes. Remove this platform check
    // once we can support it.
    // https://github.com/flutter/flutter/issues/77957
    if (_semanticsInfo!.any(
            (InlineSpanSemanticsInformation info) => info.recognizer != null) &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      // TODO(zmtzawqlp): error on ios simulator
      //assert(readOnly && !obscureText);
      // For Selectable rich text with recognizer, we need to create a semantics
      // node for each text fragment.
      config
        ..isSemanticBoundary = true
        ..explicitChildNodes = true;
      return;
    }
    if (_cachedAttributedValue == null) {
      if (obscureText) {
        _cachedAttributedValue =
            AttributedString(obscuringCharacter * plainText.length);
      } else {
        final StringBuffer buffer = StringBuffer();
        int offset = 0;
        final List<StringAttribute> attributes = <StringAttribute>[];
        for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
          final String label = info.semanticsLabel ?? info.text;
          for (final StringAttribute infoAttribute in info.stringAttributes) {
            final TextRange originalRange = infoAttribute.range;
            attributes.add(
              infoAttribute.copy(
                range: TextRange(
                    start: offset + originalRange.start,
                    end: offset + originalRange.end),
              ),
            );
          }
          buffer.write(label);
          offset += label.length;
        }
        _cachedAttributedValue =
            AttributedString(buffer.toString(), attributes: attributes);
      }
    }
    config
      ..attributedValue = _cachedAttributedValue!
      ..isObscured = obscureText
      ..isMultiline = _isMultiline
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true
      ..isReadOnly = readOnly;

    if (hasFocus && selectionEnabled)
      config.onSetSelection = handleSetSelection;

    if (hasFocus && !readOnly) config.onSetText = _handleSetText;

    if (selectionEnabled && selection?.isValid == true) {
      config.textSelection = selection;
      if (_textPainter.getOffsetBefore(selection!.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter =
              _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(selection!.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter =
              _handleMoveCursorForwardByCharacter;
      }
    }
  }

  void _handleSetText(String text) {
    textSelectionDelegate.userUpdateTextEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    double ordinal = 0.0;
    int start = 0;
    int placeholderIndex = 0;
    int childIndex = 0;
    RenderBox? child = firstChild;
    final Queue<SemanticsNode> newChildCache = Queue<SemanticsNode>();
    _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
    for (final InlineSpanSemanticsInformation info
        in _cachedCombinedSemanticsInfos!) {
      final TextSelection selection = TextSelection(
        baseOffset: start,
        extentOffset: start + info.text.length,
      );
      start += info.text.length;

      if (info.isPlaceholder) {
        // A placeholder span may have 0 to multiple semantics nodes, we need
        // to annotate all of the semantics nodes belong to this span.
        while (children.length > childIndex &&
            children
                .elementAt(childIndex)
                .isTagged(PlaceholderSpanIndexSemanticsTag(placeholderIndex))) {
          final SemanticsNode childNode = children.elementAt(childIndex);
          final TextParentData parentData =
              child!.parentData! as TextParentData;
          assert(parentData.scale != null);
          childNode.rect = Rect.fromLTWH(
            childNode.rect.left,
            childNode.rect.top,
            childNode.rect.width * parentData.scale!,
            childNode.rect.height * parentData.scale!,
          );
          newChildren.add(childNode);
          childIndex += 1;
        }
        child = childAfter(child!);
        placeholderIndex += 1;
      } else {
        final TextDirection initialDirection = currentDirection;
        final List<ui.TextBox> rects =
            _textPainter.getBoxesForSelection(selection);
        if (rects.isEmpty) {
          continue;
        }
        Rect rect = rects.first.toRect();
        currentDirection = rects.first.direction;
        for (final ui.TextBox textBox in rects.skip(1)) {
          rect = rect.expandToInclude(textBox.toRect());
          currentDirection = textBox.direction;
        }
        // Any of the text boxes may have had infinite dimensions.
        // We shouldn't pass infinite dimensions up to the bridges.
        rect = Rect.fromLTWH(
          math.max(0.0, rect.left),
          math.max(0.0, rect.top),
          math.min(rect.width, constraints.maxWidth),
          math.min(rect.height, constraints.maxHeight),
        );
        // Round the current rectangle to make this API testable and add some
        // padding so that the accessibility rects do not overlap with the text.
        currentRect = Rect.fromLTRB(
          rect.left.floorToDouble() - 4.0,
          rect.top.floorToDouble() - 4.0,
          rect.right.ceilToDouble() + 4.0,
          rect.bottom.ceilToDouble() + 4.0,
        );
        final SemanticsConfiguration configuration = SemanticsConfiguration()
          ..sortKey = OrdinalSortKey(ordinal++)
          ..textDirection = initialDirection
          ..attributedLabel = AttributedString(info.semanticsLabel ?? info.text,
              attributes: info.stringAttributes);
        final GestureRecognizer? recognizer = info.recognizer;
        if (recognizer != null) {
          if (recognizer is TapGestureRecognizer) {
            if (recognizer.onTap != null) {
              configuration.onTap = recognizer.onTap;
              configuration.isLink = true;
            }
          } else if (recognizer is DoubleTapGestureRecognizer) {
            if (recognizer.onDoubleTap != null) {
              configuration.onTap = recognizer.onDoubleTap;
              configuration.isLink = true;
            }
          } else if (recognizer is LongPressGestureRecognizer) {
            if (recognizer.onLongPress != null) {
              configuration.onLongPress = recognizer.onLongPress;
            }
          } else {
            assert(false, '${recognizer.runtimeType} is not supported.');
          }
        }
        final SemanticsNode newChild = (_cachedChildNodes?.isNotEmpty == true)
            ? _cachedChildNodes!.removeFirst()
            : SemanticsNode();
        newChild
          ..updateWith(config: configuration)
          ..rect = currentRect;
        newChildCache.addLast(newChild);
        newChildren.add(newChild);
      }
    }
    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  void _handleMoveCursorForwardByCharacter(bool extentSelection) {
    assert(selection != null);
    final int? extentOffset =
        _textPainter.getOffsetAfter(selection!.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : selection!.baseOffset;
    setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    assert(selection != null);
    final int? extentOffset =
        _textPainter.getOffsetBefore(selection!.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : selection!.baseOffset;
    setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extentSelection) {
    assert(selection != null);
    final TextRange currentWord =
        _textPainter.getWordBoundary(selection!.extent);
    final TextRange? nextWord = _getNextWord(currentWord.end);
    if (nextWord == null) return;
    final int baseOffset =
        extentSelection ? selection!.baseOffset : nextWord.start;
    setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extentSelection) {
    assert(selection != null);
    final TextRange currentWord =
        _textPainter.getWordBoundary(selection!.extent);
    final TextRange? previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null) return;
    final int baseOffset =
        extentSelection ? selection!.baseOffset : previousWord.start;
    setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  TextRange? _getNextWord(int offset) {
    while (true) {
      final TextRange range =
          _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.end;
    }
  }

  TextRange? _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range =
          _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // Includes newline characters from ASCII and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(zanderso): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text!.codeUnitAt(i)!;
      if (!TextLayoutMetrics.isWhitespace(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _foregroundRenderObject?.attach(owner);
    _backgroundRenderObject?.attach(owner);

    //_tap = TapGestureRecognizer(debugOwner: this)
    //  ..onTapDown = _handleTapDown
    //  ..onTap = _handleTap;
    //_longPress = LongPressGestureRecognizer(debugOwner: this)..onLongPress = _handleLongPress;
    _offset.addListener(markNeedsPaint);
    _showHideCursor();
    _showCursor.addListener(_showHideCursor);
  }

  @override
  void detach() {
    // _tap.dispose();
    // _longPress.dispose();
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(_showHideCursor);
    super.detach();
    _foregroundRenderObject?.detach();
    _backgroundRenderObject?.detach();
  }

  @override
  void redepthChildren() {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null) redepthChild(foregroundChild);
    if (backgroundChild != null) redepthChild(backgroundChild);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null) visitor(foregroundChild);
    if (backgroundChild != null) visitor(backgroundChild);
    super.visitChildren(visitor);
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  @override
  Offset get paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
    }
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
  }

  // We need to check the paint offset here because during animation, the start of
  // the text may position outside the visible region even when the text fits.
  bool get _hasVisualOverflow =>
      _maxScrollExtent > 0 || paintOffset != Offset.zero;

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the equivalent but for
  ///    a [TextPosition] rather than a [TextSelection].
  @override
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    computeTextMetricsIfNeeded();
    //final Offset paintOffset = _paintOffset;
    ///zmt
    final Offset effectiveOffset = _effectiveOffset;

    TextSelection textPainterSelection = selection;
    if (hasSpecialInlineSpanBase) {
      textPainterSelection =
          convertTextInputSelectionToTextPainterSelection(text!, selection);
    }
    if (selection.isCollapsed) {
      // todo(mpcomplete): This doesn't work well at an RTL/LTR boundary.

      double? caretHeight;
      final ValueChanged<double> caretHeightCallBack = (double value) {
        caretHeight = value;
      };

      final Offset caretOffset = getCaretOffset(
        TextPosition(
            offset: textPainterSelection.extentOffset,
            affinity: selection.extent.affinity),
        caretHeightCallBack: caretHeightCallBack,
        effectiveOffset: effectiveOffset,
        caretPrototype: _caretPrototype,
      );

      final Offset start =
          Offset(0.0, caretHeight ?? preferredLineHeight) + caretOffset;

      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(
        textPainterSelection,
        boxWidthStyle: selectionWidthStyle,
        boxHeightStyle: selectionHeightStyle,
      );
      final Offset start =
          Offset(boxes.first.start, boxes.first.bottom) + effectiveOffset;
      final Offset end =
          Offset(boxes.last.end, boxes.last.bottom) + effectiveOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }
  }

  /// Returns the position in the text for the given global coordinate.
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the reverse operation, taking
  ///    a [TextPosition] and returning a [Rect].
  ///  * [TextPainter.getPositionForOffset], which is the equivalent method
  ///    for a [TextPainter] object.
  @override
  TextPosition getPositionForPoint(Offset globalPosition) {
    computeTextMetricsIfNeeded();
    globalPosition += -paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  ///
  /// See also:
  ///
  ///  * [getPositionForPoint], which is the reverse operation, taking
  ///    an [Offset] in global coordinates and returning a [TextPosition].
  ///  * [getEndpointsForSelection], which is the equivalent but for
  ///    a selection rather than a particular text position.
  ///  * [TextPainter.getOffsetForCaret], the equivalent method for a
  ///    [TextPainter] object.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    computeTextMetricsIfNeeded();
    //  final  Offset caretOffset =
    //       _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);

    final Offset caretOffset = getCaretOffset(
      caretPosition,
      caretPrototype: _caretPrototype,
      // effectiveOffset: effectiveOffset,
    );

    // This rect is the same as _caretPrototype but without the vertical padding.
    Rect rect = Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight)
        .shift(caretOffset + paintOffset);
    // Add additional cursor offset (generally only if on iOS).
    if (cursorOffset != null) {
      rect = rect.shift(cursorOffset);
    }

    return rect.shift(_getPixelPerfectCursorOffset(rect));
  }

  /// An estimate of the height of a line in the text. See [TextPainter.preferredLineHeight].
  /// This does not required the layout to be updated.
  @override
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _preferredHeight(double width) {
    // Lock height to maxLines if needed.
    final bool lockedMax = maxLines != null && minLines == null;
    final bool lockedBoth = minLines != null && minLines == maxLines;
    final bool singleLine = maxLines == 1;
    if (singleLine || lockedMax || lockedBoth) {
      return preferredLineHeight * maxLines!;
    }

    // Clamp height to minLines or maxLines if needed.
    final bool minLimited = minLines != null && minLines! > 1;
    final bool maxLimited = maxLines != null;
    if (minLimited || maxLimited) {
      layoutText(maxWidth: width);
      if (minLimited && _textPainter.height < preferredLineHeight * minLines!) {
        return preferredLineHeight * minLines!;
      }
      if (maxLimited && _textPainter.height > preferredLineHeight * maxLines!) {
        return preferredLineHeight * maxLines!;
      }
    }

    // Set the height based on the content.
    if (width == double.infinity) {
      final String text = plainText;
      int lines = 1;
      for (int index = 0; index < text.length; index += 1) {
        if (text.codeUnitAt(index) == 0x0A) // count explicit line breaks
          lines += 1;
      }
      return preferredLineHeight * lines;
    }
    layoutText(maxWidth: width);
    return math.max(preferredLineHeight, _textPainter.height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    computeTextMetricsIfNeeded();
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  late TapGestureRecognizer _tap;
  late LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      assert(!debugNeedsLayout);

      if (!ignorePointer) {
        // Propagates the pointer event to selection handlers.
        _tap.addPointer(event);
        _longPress.addPointer(event);
      }
    }
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [DoubleTapGestureRecognizer.onDoubleTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to double
  /// tap events by calling this method.
  void handleDoubleTap() {
    selectWord(cause: SelectionChangedCause.doubleTap);
  }

  late Rect _caretPrototype;

  // TODO(garyq): This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  /// On iOS, the cursor is taller than the cursor on Android. The height
  /// of the cursor for iOS is approximate and obtained through an eyeball
  /// comparison.
  void _computeCaretPrototype() {
    assert(defaultTargetPlatform != null);
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _caretPrototype =
            Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight + 2);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _caretPrototype = Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth,
            cursorHeight - 2.0 * _kCaretHeightOffset);
        break;
    }
  }

  // Computes the offset to apply to the given [sourceOffset] so it perfectly
  // snaps to physical pixels.
  Offset _snapToPhysicalPixel(Offset sourceOffset) {
    final Offset globalOffset = localToGlobal(sourceOffset);
    final double pixelMultiple = 1.0 / _devicePixelRatio;
    return Offset(
      globalOffset.dx.isFinite
          ? (globalOffset.dx / pixelMultiple).round() * pixelMultiple -
              globalOffset.dx
          : 0,
      globalOffset.dy.isFinite
          ? (globalOffset.dy / pixelMultiple).round() * pixelMultiple -
              globalOffset.dy
          : 0,
    );
  }

  bool _canComputeDryLayout() {
    // Dry layout cannot be calculated without a full layout for
    // alignments that require the baseline (baseline, aboveBaseline,
    // belowBaseline).
    for (final PlaceholderSpan span in placeholderSpans) {
      switch (span.alignment) {
        case ui.PlaceholderAlignment.baseline:
        case ui.PlaceholderAlignment.aboveBaseline:
        case ui.PlaceholderAlignment.belowBaseline:
          return false;
        case ui.PlaceholderAlignment.top:
        case ui.PlaceholderAlignment.middle:
        case ui.PlaceholderAlignment.bottom:
          continue;
      }
    }
    return true;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!_canComputeDryLayout()) {
      assert(debugCannotComputeDryLayout(
        reason:
            'Dry layout not available for alignments that require baseline.',
      ));
      return Size.zero;
    }
    layoutChildren(constraints, dry: true);
    computeTextMetricsIfNeeded();
    final double width = forceLine
        ? constraints.maxWidth
        : constraints.constrainWidth(_textPainter.size.width + _caretMargin);
    return Size(width,
        constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
  }

  @override
  void performLayout() {
    layoutChildren(constraints);
    layoutText(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
        forceLayout: true);
    setParentData();
    _computeCaretPrototype();
    // We grab _textPainter.size here because assigning to `size` on the next
    // line will trigger us to validate our intrinsic sizes, which will change
    // _textPainter's layout because the intrinsic size calculations are
    // destructive, which would mean we would get different results if we later
    // used properties on _textPainter in this method.
    // Other _textPainter state like didExceedMaxLines will also be affected,
    // though we currently don't use those here.
    // See also RenderParagraph which has a similar issue.
    final Size textPainterSize = _textPainter.size;
    final double width = forceLine
        ? constraints.maxWidth
        : constraints.constrainWidth(_textPainter.size.width + _caretMargin);
    size = Size(width,
        constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize =
        Size(textPainterSize.width + _caretMargin, textPainterSize.height);

    final BoxConstraints painterConstraints = BoxConstraints.tight(contentSize);

    _foregroundRenderObject?.layout(painterConstraints);
    _backgroundRenderObject?.layout(painterConstraints);

    _maxScrollExtent = _getMaxScrollExtent(contentSize);
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  Offset _getPixelPerfectCursorOffset(Rect caretRect) {
    final Offset caretPosition = localToGlobal(caretRect.topLeft);
    final double pixelMultiple = 1.0 / _devicePixelRatio;
    final int quotientX = (caretPosition.dx / pixelMultiple).round();
    final int quotientY = (caretPosition.dy / pixelMultiple).round();
    final double pixelPerfectOffsetX =
        quotientX * pixelMultiple - caretPosition.dx;
    final double pixelPerfectOffsetY =
        quotientY * pixelMultiple - caretPosition.dy;
    return Offset(pixelPerfectOffsetX, pixelPerfectOffsetY);
  }

  /// Sets the screen position of the floating cursor and the text position
  /// closest to the cursor.
  void setFloatingCursor(FloatingCursorDragState state, Offset boundedOffset,
      TextPosition lastTextPosition,
      {double? resetLerpValue}) {
    assert(state != null);
    assert(boundedOffset != null);
    assert(lastTextPosition != null);
    if (state == FloatingCursorDragState.Start) {
      _relativeOrigin = Offset.zero;
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }
    _floatingCursorOn = state != FloatingCursorDragState.End;
    _resetFloatingCursorAnimationValue = resetLerpValue;
    if (_floatingCursorOn) {
      _floatingCursorTextPosition = lastTextPosition;
      final double? animationValue = _resetFloatingCursorAnimationValue;
      final EdgeInsets sizeAdjustment = animationValue != null
          ? EdgeInsets.lerp(
              _kFloatingCaretSizeIncrease, EdgeInsets.zero, animationValue)!
          : _kFloatingCaretSizeIncrease;
      _caretPainter.floatingCursorRect =
          sizeAdjustment.inflateRect(_caretPrototype).shift(boundedOffset);
    } else {
      _caretPainter.floatingCursorRect = null;
    }
    _caretPainter.showRegularCaret = _resetFloatingCursorAnimationValue == null;
  }

  // The relative origin in relation to the distance the user has theoretically
  // dragged the floating cursor offscreen. This value is used to account for the
  // difference in the rendering position and the raw offset value.
  Offset _relativeOrigin = Offset.zero;
  Offset? _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  double? _resetFloatingCursorAnimationValue;

  /// Returns the position within the text field closest to the raw cursor offset.
  Offset calculateBoundedFloatingCursorOffset(Offset rawCursorOffset) {
    Offset deltaPosition = Offset.zero;
    final double topBound = -floatingCursorAddedMargin.top;
    final double bottomBound = _textPainter.height -
        preferredLineHeight +
        floatingCursorAddedMargin.bottom;
    final double leftBound = -floatingCursorAddedMargin.left;
    final double rightBound =
        _textPainter.width + floatingCursorAddedMargin.right;

    if (_previousOffset != null)
      deltaPosition = rawCursorOffset - _previousOffset!;

    // If the raw cursor offset has gone off an edge, we want to reset the relative
    // origin of the dragging when the user drags back into the field.
    if (_resetOriginOnLeft && deltaPosition.dx > 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - leftBound, _relativeOrigin.dy);
      _resetOriginOnLeft = false;
    } else if (_resetOriginOnRight && deltaPosition.dx < 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - rightBound, _relativeOrigin.dy);
      _resetOriginOnRight = false;
    }
    if (_resetOriginOnTop && deltaPosition.dy > 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - topBound);
      _resetOriginOnTop = false;
    } else if (_resetOriginOnBottom && deltaPosition.dy < 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - bottomBound);
      _resetOriginOnBottom = false;
    }

    final double currentX = rawCursorOffset.dx - _relativeOrigin.dx;
    final double currentY = rawCursorOffset.dy - _relativeOrigin.dy;
    final double adjustedX =
        math.min(math.max(currentX, leftBound), rightBound);
    final double adjustedY =
        math.min(math.max(currentY, topBound), bottomBound);
    final Offset adjustedOffset = Offset(adjustedX, adjustedY);

    if (currentX < leftBound && deltaPosition.dx < 0)
      _resetOriginOnLeft = true;
    else if (currentX > rightBound && deltaPosition.dx > 0)
      _resetOriginOnRight = true;
    if (currentY < topBound && deltaPosition.dy < 0)
      _resetOriginOnTop = true;
    else if (currentY > bottomBound && deltaPosition.dy > 0)
      _resetOriginOnBottom = true;

    _previousOffset = rawCursorOffset;

    return adjustedOffset;
  }

  MapEntry<int, Offset> _lineNumberFor(
      TextPosition startPosition, List<ui.LineMetrics> metrics) {
    // TODO(LongCatIsLooong): include line boundaries information in
    // ui.LineMetrics, then we can get rid of this.
    final Offset offset =
        _textPainter.getOffsetForCaret(startPosition, Rect.zero);
    for (final ui.LineMetrics lineMetrics in metrics) {
      if (lineMetrics.baseline + lineMetrics.descent > offset.dy) {
        return MapEntry<int, Offset>(
            lineMetrics.lineNumber, Offset(offset.dx, lineMetrics.baseline));
      }
    }
    assert(startPosition.offset == 0,
        'unable to find the line for $startPosition');
    return MapEntry<int, Offset>(
      math.max(0, metrics.length - 1),
      Offset(
          offset.dx,
          metrics.isNotEmpty
              ? metrics.last.baseline + metrics.last.descent
              : 0.0),
    );
  }

  /// Starts a [VerticalCaretMovementRun] at the given location in the text, for
  /// handling consecutive vertical caret movements.
  ///
  /// This can be used to handle consecutive upward/downward arrow key movements
  /// in an input field.
  ///
  /// {@macro flutter.rendering.RenderEditable.verticalArrowKeyMovement}
  ///
  /// The [VerticalCaretMovementRun.isValid] property indicates whether the text
  /// layout has changed and the vertical caret run is invalidated.
  ///
  /// The caller should typically discard a [VerticalCaretMovementRun] when
  /// its [VerticalCaretMovementRun.isValid] becomes false, or on other
  /// occasions where the vertical caret run should be interrupted.
  VerticalCaretMovementRun startVerticalCaretMovement(
      TextPosition startPosition) {
    final List<ui.LineMetrics> metrics = _textPainter.computeLineMetrics();
    final MapEntry<int, Offset> currentLine =
        _lineNumberFor(startPosition, metrics);
    return VerticalCaretMovementRun._(
      this,
      metrics,
      startPosition,
      currentLine.key,
      currentLine.value,
    );
  }

  void _paintContents(PaintingContext context, Offset offset) {
    assert(
        textLayoutLastMaxWidth == constraints.maxWidth &&
            textLayoutLastMinWidth == constraints.minWidth,
        'Last width ($textLayoutLastMinWidth, $textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final Offset effectiveOffset = offset + paintOffset;

    // bool showSelection = false;
    // bool showCaret = false;

    ///zmt
    //final TextSelection? actualSelection = getActualSelection();

    if (_autocorrectHighlightPainter.highlightedRange != null &&
        !_floatingCursorOn) {
      _updateSelectionExtentsVisibility(effectiveOffset,
          _autocorrectHighlightPainter.highlightedRange as TextSelection);
      // if (actualSelection.isCollapsed &&
      //     _showCursor.value &&
      //     cursorColor != null)
      //   showCaret = true;
      // else if (!actualSelection.isCollapsed && _selectionColor != null)
      //   showSelection = true;
    }
    // if (showSelection) {
    //   _selectionRects ??= _textPainter.getBoxesForSelection(
    //     actualSelection!,
    //     boxWidthStyle: selectionWidthStyle,
    //     boxHeightStyle: selectionHeightStyle,
    //   );
    //   paintSelection(context.canvas, effectiveOffset);
    // }

    final RenderBox? foregroundChild = _foregroundRenderObject;
    final RenderBox? backgroundChild = _backgroundRenderObject;

    // The painters paint in the viewport's coordinate space, since the
    // textPainter's coordinate space is not known to high level widgets.
    if (backgroundChild != null) context.paintChild(backgroundChild, offset);

    _textPainter.paint(context.canvas, effectiveOffset);
    paintWidgets(context, effectiveOffset);

    ///zmt
    _paintSpecialText(context, effectiveOffset);

    if (foregroundChild != null) context.paintChild(foregroundChild, offset);
  }

  Offset? _initialOffset;
  Offset get _effectiveOffset => (_initialOffset ?? Offset.zero) + paintOffset;

  @override
  void paint(PaintingContext context, Offset offset) {
    ///zmt
    _initialOffset = offset;

    computeTextMetricsIfNeeded();
    if (_hasVisualOverflow)
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintContents,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    else {
      _clipRectLayer.layer = null;
      _paintContents(context, offset);
    }

    paintHandleLayers(context, super.paint);
  }

  void _paintSpecialText(PaintingContext context, Offset offset) {
    if (!hasSpecialInlineSpanBase) {
      return;
    }

    final Canvas canvas = context.canvas;

    canvas.save();

    ///move to extended text
    canvas.translate(offset.dx, offset.dy);

    ///we have move the canvas, so rect top left should be (0,0)
    final Rect rect = const Offset(0.0, 0.0) & size;
    _paintSpecialTextChildren(<InlineSpan?>[text], canvas, rect);
    canvas.restore();
  }

  void _paintSpecialTextChildren(
      List<InlineSpan?>? textSpans, Canvas canvas, Rect rect,
      {int textOffset = 0}) {
    if (textSpans == null) {
      return;
    }

    for (final InlineSpan? ts in textSpans) {
      final Offset topLeftOffset = getOffsetForCaret(
        TextPosition(offset: textOffset),
        rect,
      );
      //skip invalid or overflow
      if (textOffset != 0 && topLeftOffset == Offset.zero) {
        return;
      }

      if (ts is BackgroundTextSpan) {
        final TextPainter painter = ts.layout(_textPainter)!;
        final Rect textRect = topLeftOffset & painter.size;
        Offset? endOffset;
        if (textRect.right > rect.right) {
          final int endTextOffset = textOffset + ts.toPlainText().length;
          endOffset = _findEndOffset(rect, endTextOffset);
        }

        ts.paint(canvas, topLeftOffset, rect,
            endOffset: endOffset, wholeTextPainter: _textPainter);
      } else if (ts is TextSpan && ts.children != null) {
        _paintSpecialTextChildren(ts.children, canvas, rect,
            textOffset: textOffset);
      }
      textOffset += ts!.toPlainText().length;
    }
  }

  Offset _findEndOffset(Rect rect, int endTextOffset) {
    final Offset endOffset = getOffsetForCaret(
      TextPosition(offset: endTextOffset, affinity: TextAffinity.upstream),
      rect,
    );
    //overflow
    if (endTextOffset != 0 && endOffset == Offset.zero) {
      return _findEndOffset(rect, endTextOffset - 1);
    }
    return endOffset;
  }

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    return getCaretOffset(position, caretPrototype: caretPrototype);
    //return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('cursorColor', cursorColor));
    properties.add(
        DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    properties.add(IntProperty('maxLines', maxLines));
    properties.add(IntProperty('minLines', minLines));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(ColorProperty('selectionColor', selectionColor));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DiagnosticsProperty<TextSelection>('selection', selection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (text != null)
        text!.toDiagnosticsNode(
          name: 'text',
          style: DiagnosticsTreeStyle.transition,
        ),
    ];
  }

  @override
  double get caretMargin => _caretMargin;

  @override
  Rect get caretPrototype => _caretPrototype;

  @override
  Offset get effectiveOffset => _effectiveOffset;

  @override
  bool get isAttached => attached;

  @override
  bool get isMultiline => maxLines != 1;

  @override
  TextOverflow get overflow => TextOverflow.visible;

  @override
  Widget? get overflowWidget => null;

  @override
  List<ui.TextBox>? get selectionRects => null;

  @override
  bool get softWrap => false;

  @override
  TextPainter get textPainter => _textPainter;
}

class _RenderEditableCustomPaint extends RenderBox {
  _RenderEditableCustomPaint({
    ExtendedRenderEditablePainter? painter,
  })  : _painter = painter,
        super();

  @override
  ExtendedRenderEditable? get parent => super.parent as ExtendedRenderEditable?;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  ExtendedRenderEditablePainter? get painter => _painter;
  ExtendedRenderEditablePainter? _painter;
  set painter(ExtendedRenderEditablePainter? newValue) {
    if (newValue == painter) return;

    final ExtendedRenderEditablePainter? oldPainter = painter;
    _painter = newValue;

    if (newValue?.shouldRepaint(oldPainter) ?? true) markNeedsPaint();

    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newValue?.addListener(markNeedsPaint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final ExtendedRenderEditable? parent = this.parent;
    assert(parent != null);
    final ExtendedRenderEditablePainter? painter = this.painter;
    if (painter != null && parent != null) {
      parent.computeTextMetricsIfNeeded();
      painter.paint(context.canvas, size, parent);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}

class _FloatingCursorPainter extends ExtendedRenderEditablePainter {
  _FloatingCursorPainter(this.caretPaintCallback);

  bool get shouldPaint => _shouldPaint;
  bool _shouldPaint = true;
  set shouldPaint(bool value) {
    if (shouldPaint == value) return;
    _shouldPaint = value;
    notifyListeners();
  }

  CaretChangedHandler caretPaintCallback;

  bool showRegularCaret = false;

  final Paint caretPaint = Paint();
  late final Paint floatingCursorPaint = Paint();

  Color? get caretColor => _caretColor;
  Color? _caretColor;
  set caretColor(Color? value) {
    if (caretColor?.value == value?.value) return;

    _caretColor = value;
    notifyListeners();
  }

  Radius? get cursorRadius => _cursorRadius;
  Radius? _cursorRadius;
  set cursorRadius(Radius? value) {
    if (_cursorRadius == value) return;
    _cursorRadius = value;
    notifyListeners();
  }

  Offset get cursorOffset => _cursorOffset;
  Offset _cursorOffset = Offset.zero;
  set cursorOffset(Offset value) {
    if (_cursorOffset == value) return;
    _cursorOffset = value;
    notifyListeners();
  }

  Color? get backgroundCursorColor => _backgroundCursorColor;
  Color? _backgroundCursorColor;
  set backgroundCursorColor(Color? value) {
    if (backgroundCursorColor?.value == value?.value) return;

    _backgroundCursorColor = value;
    if (showRegularCaret) notifyListeners();
  }

  Rect? get floatingCursorRect => _floatingCursorRect;
  Rect? _floatingCursorRect;
  set floatingCursorRect(Rect? value) {
    if (_floatingCursorRect == value) return;
    _floatingCursorRect = value;
    notifyListeners();
  }

  void paintRegularCursor(Canvas canvas, ExtendedRenderEditable renderEditable,
      Color caretColor, TextPosition textPosition) {
    final Rect caretPrototype = renderEditable._caretPrototype;
    final Offset caretOffset =
        renderEditable.getOffsetForCaret(textPosition, caretPrototype);
    Rect caretRect = caretPrototype.shift(caretOffset + cursorOffset);

    final double? caretHeight = renderEditable._textPainter
        .getFullHeightForCaret(textPosition, caretPrototype);
    if (caretHeight != null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          final double heightDiff = caretHeight - caretRect.height;
          // Center the caret vertically along the text.
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top + heightDiff / 2,
            caretRect.width,
            caretRect.height,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Override the height to take the full height of the glyph at the TextPosition
          // when not on iOS. iOS has special handling that creates a taller caret.
          // TODO(garyq): See the TODO for _computeCaretPrototype().
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top - _kCaretHeightOffset,
            caretRect.width,
            caretHeight,
          );
          break;
      }
    }

    caretRect = caretRect.shift(renderEditable.paintOffset);
    final Rect integralRect =
        caretRect.shift(renderEditable._snapToPhysicalPixel(caretRect.topLeft));

    if (shouldPaint) {
      final Radius? radius = cursorRadius;
      caretPaint.color = caretColor;
      if (radius == null) {
        canvas.drawRect(integralRect, caretPaint);
      } else {
        final RRect caretRRect = RRect.fromRectAndRadius(integralRect, radius);
        canvas.drawRRect(caretRRect, caretPaint);
      }
    }
    caretPaintCallback(integralRect);
  }

  @override
  void paint(Canvas canvas, Size size,
      ExtendedTextSelectionRenderObject renderEditable) {
    // Compute the caret location even when `shouldPaint` is false.
    renderEditable = renderEditable as ExtendedRenderEditable;
    assert(renderEditable != null);
    final TextSelection? selection = renderEditable.getActualSelection();

    // TODO(LongCatIsLooong): skip painting the caret when the selection is
    // (-1, -1).
    if (selection == null || !selection.isCollapsed) return;

    final Rect? floatingCursorRect = this.floatingCursorRect;

    final Color? caretColor = floatingCursorRect == null
        ? this.caretColor
        : showRegularCaret
            ? backgroundCursorColor
            : null;
    final TextPosition caretTextPosition = floatingCursorRect == null
        ? selection.extent
        : renderEditable._floatingCursorTextPosition;

    if (caretColor != null) {
      paintRegularCursor(canvas, renderEditable, caretColor, caretTextPosition);
    }

    final Color? floatingCursorColor = this.caretColor?.withOpacity(0.75);
    // Floating Cursor.
    if (floatingCursorRect == null ||
        floatingCursorColor == null ||
        !shouldPaint) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          floatingCursorRect.shift(renderEditable.paintOffset),
          _kFloatingCaretRadius),
      floatingCursorPaint..color = floatingCursorColor,
    );
  }

  @override
  bool shouldRepaint(ExtendedRenderEditablePainter? oldDelegate) {
    if (identical(this, oldDelegate)) return false;

    if (oldDelegate == null) return shouldPaint;
    return oldDelegate is! _FloatingCursorPainter ||
        oldDelegate.shouldPaint != shouldPaint ||
        oldDelegate.showRegularCaret != showRegularCaret ||
        oldDelegate.caretColor != caretColor ||
        oldDelegate.cursorRadius != cursorRadius ||
        oldDelegate.cursorOffset != cursorOffset ||
        oldDelegate.backgroundCursorColor != backgroundCursorColor ||
        oldDelegate.floatingCursorRect != floatingCursorRect;
  }
}

class _CompositeRenderEditablePainter extends ExtendedRenderEditablePainter {
  _CompositeRenderEditablePainter({required this.painters});

  final List<ExtendedRenderEditablePainter> painters;

  @override
  void addListener(VoidCallback listener) {
    for (final ExtendedRenderEditablePainter painter in painters)
      painter.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final ExtendedRenderEditablePainter painter in painters)
      painter.removeListener(listener);
  }

  @override
  void paint(Canvas canvas, Size size,
      ExtendedTextSelectionRenderObject renderEditable) {
    for (final ExtendedRenderEditablePainter painter in painters)
      painter.paint(canvas, size, renderEditable);
  }

  @override
  bool shouldRepaint(ExtendedRenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this)) return false;
    if (oldDelegate is! _CompositeRenderEditablePainter ||
        oldDelegate.painters.length != painters.length) return true;

    final Iterator<ExtendedRenderEditablePainter> oldPainters =
        oldDelegate.painters.iterator;
    final Iterator<ExtendedRenderEditablePainter> newPainters =
        painters.iterator;
    while (oldPainters.moveNext() && newPainters.moveNext())
      if (newPainters.current.shouldRepaint(oldPainters.current)) return true;

    return false;
  }
}
