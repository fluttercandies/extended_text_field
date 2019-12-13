import 'dart:async';

///
///  create by zmtzawqlp on 2019/4/25
///  base on flutter sdk 1.7.8
///

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show TextBox, lerpDouble;

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

const double _kCaretGap = 1.0; // pixels
///
///Make Ios/Android caret the same height
///https://github.com/fluttercandies/extended_text_field/issues/14
///https://github.com/fluttercandies/extended_text_field/issues/19
///https://github.com/fluttercandies/extended_text_field/issues/10
//const double _kCaretHeightOffset = 2.0; // pixels
const double _kCaretHeightOffset = 0.0; // pixels

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const Offset _kFloatingCaretSizeIncrease = Offset(0.5, 1.0);

// The corner radius of the floating cursor in pixels.
const double _kFloatingCaretRadius = 1.0;

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [ExtendedRenderEditable.onSelectionChanged].
typedef ExtendedSelectionChangedHandler = void Function(TextSelection selection,
    ExtendedRenderEditable renderObject, SelectionChangedCause cause);

/// Signature for the callback that reports when the caret location changes.
///
/// Used by [ExtendedRenderEditable.onCaretChanged].
typedef ExtendedCaretChangedHandler = void Function(Rect caretRect);

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
/// The user may interact with the render object by tapping or long-pressing.
/// When the user does so, the selection is updated, and [onSelectionChanged] is
/// called.
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
class ExtendedRenderEditable extends ExtendedTextRenderBox
    with ExtendedTextSelectionRenderObject {
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
    InlineSpan text,
    @required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    Color cursorColor,
    Color backgroundCursorColor,
    ValueNotifier<bool> showCursor,
    bool hasFocus,
    int maxLines = 1,
    int minLines,
    bool expands = false,
    StrutStyle strutStyle,
    Color selectionColor,
    double textScaleFactor = 1.0,
    TextSelection selection,
    @required ViewportOffset offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.ignorePointer = false,
    bool obscureText = false,
    Locale locale,
    double cursorWidth = 1.0,
    Radius cursorRadius,
    bool paintCursorAboveText = false,
    Offset cursorOffset,
    double devicePixelRatio = 1.0,
    bool enableInteractiveSelection,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
    @required this.textSelectionDelegate,
    this.supportSpecialText,
    List<RenderBox> children,
  })  : assert(textAlign != null),
        assert(textDirection != null,
            'RenderEditable created without a textDirection.'),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          'minLines can\'t be greater than maxLines',
        ),
        assert(expands != null),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(textScaleFactor != null),
        assert(offset != null),
        assert(ignorePointer != null),
        assert(paintCursorAboveText != null),
        assert(obscureText != null),
        assert(textSelectionDelegate != null),
        assert(cursorWidth != null && cursorWidth >= 0.0),
        assert(devicePixelRatio != null),
        _handleSpecialText = hasSpecialText(text),
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          locale: locale,
          strutStyle: strutStyle,
//              supportSpecialText && hasSpecialText(text) ? null : strutStyle,
        ),
        _cursorColor = cursorColor,
        _backgroundCursorColor = backgroundCursorColor,
        _showCursor = showCursor ?? ValueNotifier<bool>(false),
        _maxLines = maxLines,
        _minLines = minLines,
        _expands = expands,
        _selectionColor = selectionColor,
        _selection = selection,
        _offset = offset,
        _cursorWidth = cursorWidth,
        _cursorRadius = cursorRadius,
        _paintCursorOnTop = paintCursorAboveText,
        _cursorOffset = cursorOffset,
        _floatingCursorAddedMargin = floatingCursorAddedMargin,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio,
        _obscureText = obscureText {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);
    this.hasFocus = hasFocus ?? false;
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
    addAll(children);
    extractPlaceholderSpans(text);
  }

  ///whether to support build SpecialText

  bool supportSpecialText = false;
  bool _handleSpecialText = false;
  bool get handleSpecialText => supportSpecialText && _handleSpecialText;

  /// Character used to obscure text if [obscureText] is true.
  static const String obscuringCharacter = '•';

  /// Called when the selection changes.
  ExtendedSelectionChangedHandler onSelectionChanged;

  double _textLayoutLastWidth;

  /// Called during the paint phase when the caret location changes.
  ExtendedCaretChangedHandler onCaretChanged;

  /// If true [handleEvent] does nothing and it's assumed that this
  /// renderer will be notified of input gestures via [handleTapDown],
  /// [handleTap], [handleDoubleTap], and [handleLongPress].
  ///
  /// The default value of this property is false.
  bool ignorePointer;

  /// Whether text is composed.
  ///
  /// Text is composed when user selects it for editing. The [TextSpan] will have
  /// children with composing effect and leave text property to be null.
  @visibleForTesting
  bool get isComposingText => textSpanToActualText(text) == null;

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

  /// Whether to hide the text being edited (e.g., for passwords).
  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value) return;
    _obscureText = value;
    markNeedsSemanticsUpdate();
  }

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate textSelectionDelegate;

  Rect _lastCaretRect;

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
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(
      Offset effectiveOffset, TextSelection selection) {
    ///final Rect visibleRegion = Offset.zero & size;

    ///zmt
    ///caret may be less than 0, because it's bigger than text
    ///

    final Rect visibleRegion = Offset(0.0, _visibleRegionMinY) & size;

    final Offset startOffset = getCaretOffset(
      TextPosition(
        offset: selection.start,
        affinity: selection.affinity,
      ),
      effectiveOffset: effectiveOffset,
      caretPrototype: _caretPrototype,
      handleSpecialText: handleSpecialText,
    );

    // TODO(justinmc): https://github.com/flutter/flutter/issues/31495
    // Check if the selection is visible with an approximation because a
    // difference between rounded and unrounded values causes the caret to be
    // reported as having a slightly (< 0.5) negative y offset. This rounding
    // happens in paragraph.cc's layout and TextPainer's
    // _applyFloatingPointHack. Ideally, the rounding mismatch will be fixed and
    // this can be changed to be a strict check instead of an approximation.
    const double visibleRegionSlop = 0.5;
    _selectionStartInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(startOffset + effectiveOffset);

    final Offset endOffset = getCaretOffset(
      TextPosition(offset: selection.end, affinity: selection.affinity),
      effectiveOffset: effectiveOffset,
      caretPrototype: _caretPrototype,
      handleSpecialText: handleSpecialText,
    );

    _selectionEndInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(endOffset + effectiveOffset);
  }

  ///some times _visibleRegionMinY will lower than 0.0;
  ///that the _selectionStartInViewport and _selectionEndInViewport will not right.
  ///
  double _visibleRegionMinY = -_kCaretHeightOffset;

  ///zmt
  void _updateVisibleRegionMinY() {
//    if (textSelectionDelegate.textEditingValue == null ||
//        textSelectionDelegate.textEditingValue.text == null ||
//        textSelectionDelegate.textEditingValue.selection == null ||
//        _textPainter.text == null) return;
//    List<TextBox> boxs = _textPainter.getBoxesForSelection(
//        textSelectionDelegate.textEditingValue.selection.copyWith(
//            baseOffset: 0,
//            extentOffset: _textPainter.text.toPlainText().length));
//    boxs.forEach((f) {
//      _visibleRegionMinY = math.min(f.top, _visibleRegionMinY);
//    });
  }

  static const int _kLeftArrowCode = 21;
  static const int _kRightArrowCode = 22;
  static const int _kUpArrowCode = 19;
  static const int _kDownArrowCode = 20;
  static const int _kXKeyCode = 52;
  static const int _kCKeyCode = 31;
  static const int _kVKeyCode = 50;
  static const int _kAKeyCode = 29;
  static const int _kDelKeyCode = 112;

  // The extent offset of the current selection
  int _extentOffset = -1;

  // The base offset of the current selection
  int _baseOffset = -1;

  // Holds the last location the user selected in the case that he selects all
  // the way to the end or beginning of the field.
  int _previousCursorLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // selects all the way to the end or the beginning of a field.
  bool _resetCursor = false;

  static const int _kShiftMask =
      1; // https://developer.android.com/reference/android/view/KeyEvent.html#META_SHIFT_ON
  static const int _kControlMask = 1 <<
      12; // https://developer.android.com/reference/android/view/KeyEvent.html#META_CTRL_ON

  // Call through to onSelectionChanged only if the given nextSelection is
  // different from the existing selection.
  void _handlePotentialSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    if (nextSelection == selection) {
      return;
    }
    onSelectionChanged(nextSelection, this, cause);
  }

  // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
  void _handleKeyEvent(RawKeyEvent keyEvent) {
    // Only handle key events on Android.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return;
    }
    

    if (keyEvent is RawKeyUpEvent) return;

    final RawKeyEventDataAndroid rawAndroidEvent = keyEvent.data;
    final int pressedKeyCode = rawAndroidEvent.keyCode;
    final int pressedKeyMetaState = rawAndroidEvent.metaState;

    if (selection.isCollapsed) {
      _extentOffset = selection.extentOffset;
      _baseOffset = selection.baseOffset;
    }

    // Update current key states
    final bool shift = pressedKeyMetaState & _kShiftMask > 0;
    final bool ctrl = pressedKeyMetaState & _kControlMask > 0;

    final bool rightArrow = pressedKeyCode == _kRightArrowCode;
    final bool leftArrow = pressedKeyCode == _kLeftArrowCode;
    final bool upArrow = pressedKeyCode == _kUpArrowCode;
    final bool downArrow = pressedKeyCode == _kDownArrowCode;
    final bool arrow = leftArrow || rightArrow || upArrow || downArrow;
    final bool aKey = pressedKeyCode == _kAKeyCode;
    final bool xKey = pressedKeyCode == _kXKeyCode;
    final bool vKey = pressedKeyCode == _kVKeyCode;
    final bool cKey = pressedKeyCode == _kCKeyCode;
    final bool del = pressedKeyCode == _kDelKeyCode;

    // We will only move select or more the caret if an arrow is pressed
    if (arrow) {
      int newOffset = _extentOffset;

      // Because the user can use multiple keys to change how he selects
      // the new offset variable is threaded through these four functions
      // and potentially changes after each one.
      if (ctrl)
        newOffset = _handleControl(rightArrow, leftArrow, ctrl, newOffset);
      newOffset =
          _handleHorizontalArrows(rightArrow, leftArrow, shift, newOffset);
      if (downArrow || upArrow)
        newOffset = _handleVerticalArrows(upArrow, downArrow, shift, newOffset);
      newOffset = _handleShift(rightArrow, leftArrow, shift, newOffset);

      _extentOffset = newOffset;
    } else if (ctrl && (xKey || vKey || cKey || aKey)) {
      // _handleShortcuts depends on being started in the same stack invocation as the _handleKeyEvent method
      _handleShortcuts(pressedKeyCode);
    }
    if (del) _handleDelete();
  }

  // Handles full word traversal using control.
  int _handleControl(
      bool rightArrow, bool leftArrow, bool ctrl, int newOffset) {
    // If control is pressed, we will decide which way to look for a word
    // based on which arrow is pressed.
    if (leftArrow && _extentOffset > 2) {
      final TextSelection textSelection =
          _selectWordAtOffset(TextPosition(offset: _extentOffset - 2));
      newOffset = textSelection.baseOffset + 1;
    } else if (rightArrow &&
        _extentOffset < textSpanToActualText(text).length - 2) {
      final TextSelection textSelection =
          _selectWordAtOffset(TextPosition(offset: _extentOffset + 1));
      newOffset = textSelection.extentOffset - 1;
    }
    return newOffset;
  }

  int _handleHorizontalArrows(
      bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    // Set the new offset to be +/- 1 depending on which arrow is pressed
    // If shift is down, we also want to update the previous cursor location
    if (rightArrow && _extentOffset < textSpanToActualText(text).length) {
      newOffset += 1;
      if (shift) _previousCursorLocation += 1;
    }
    if (leftArrow && _extentOffset > 0) {
      newOffset -= 1;
      if (shift) _previousCursorLocation -= 1;
    }
    return newOffset;
  }

  // Handles moving the cursor vertically as well as taking care of the
  // case where the user moves the cursor to the end or beginning of the text
  // and then back up or down.
  int _handleVerticalArrows(
      bool upArrow, bool downArrow, bool shift, int newOffset) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double plh = _textPainter.preferredLineHeight;
    final double verticalOffset = upArrow ? -0.5 * plh : 1.5 * plh;

    final Offset caretOffset = _textPainter.getOffsetForCaret(
        TextPosition(offset: _extentOffset), _caretPrototype);
    final Offset caretOffsetTranslated =
        caretOffset.translate(0.0, verticalOffset);
    final TextPosition position =
        _textPainter.getPositionForOffset(caretOffsetTranslated);

    // To account for the possibility where the user vertically highlights
    // all the way to the top or bottom of the text, we hold the previous
    // cursor location. This allows us to restore to this position in the
    // case that the user wants to unhighlight some text.
    if (position.offset == _extentOffset) {
      if (downArrow)
        newOffset = textSpanToActualText(text).length;
      else if (upArrow) newOffset = 0;
      _resetCursor = shift;
    } else if (_resetCursor && shift) {
      newOffset = _previousCursorLocation;
      _resetCursor = false;
    } else {
      newOffset = position.offset;
      _previousCursorLocation = newOffset;
    }
    return newOffset;
  }

  // Handles the selection of text or removal of the selection and placing
  // of the caret.
  int _handleShift(bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    if (onSelectionChanged == null) return newOffset;
    // In the text_selection class, a TextSelection is defined such that the
    // base offset is always less than the extent offset.
    if (shift) {
      if (_baseOffset < newOffset) {
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: _baseOffset,
            extentOffset: newOffset,
          ),
          SelectionChangedCause.keyboard,
        );
      } else {
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: newOffset,
            extentOffset: _baseOffset,
          ),
          SelectionChangedCause.keyboard,
        );
      }
    } else {
      // We want to put the cursor at the correct location depending on which
      // arrow is used while there is a selection.
      if (!selection.isCollapsed) {
        if (leftArrow)
          newOffset = _baseOffset < _extentOffset ? _baseOffset : _extentOffset;
        else if (rightArrow)
          newOffset = _baseOffset > _extentOffset ? _baseOffset : _extentOffset;
      }
      _handlePotentialSelectionChange(
        TextSelection.fromPosition(TextPosition(offset: newOffset)),
        SelectionChangedCause.keyboard,
      );
    }
    return newOffset;
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control + (X, C, V, A).
  Future<void> _handleShortcuts(int pressedKeyCode) async {
    switch (pressedKeyCode) {
      case _kCKeyCode:
        if (!selection.isCollapsed) {
          Clipboard.setData(ClipboardData(
              text: selection.textInside(textSpanToActualText(text))));
        }
        break;
      case _kXKeyCode:
        if (!selection.isCollapsed) {
          var actualText = textSpanToActualText(text);
          Clipboard.setData(
              ClipboardData(text: selection.textInside(actualText)));
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: selection.textBefore(actualText) +
                selection.textAfter(actualText),
            selection: TextSelection.collapsed(offset: selection.start),
          );
        }
        break;
      case _kVKeyCode:
        // Snapshot the input before using `await`.
        // See https://github.com/flutter/flutter/issues/11427
        final TextEditingValue value = textSelectionDelegate.textEditingValue;
        final ClipboardData data =
            await Clipboard.getData(Clipboard.kTextPlain);
        if (data != null) {
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: value.selection.textBefore(value.text) +
                data.text +
                value.selection.textAfter(value.text),
            selection: TextSelection.collapsed(
                offset: value.selection.start + data.text.length),
          );
        }
        break;
      case _kAKeyCode:
        _baseOffset = 0;
        _extentOffset = textSelectionDelegate.textEditingValue.text.length;
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: 0,
            extentOffset: textSelectionDelegate.textEditingValue.text.length,
          ),
          SelectionChangedCause.keyboard,
        );
        break;
      default:
        assert(false);
    }
  }

  void _handleDelete() {
    var actualText = textSpanToActualText(text);

    if (selection.textAfter(actualText).isNotEmpty) {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(actualText) +
            selection.textAfter(actualText).substring(1),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(actualText),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    _textLayoutLastWidth = null;
    markNeedsLayout();
  }

  /// The text to display.
  InlineSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(InlineSpan value) {
    if (_textPainter.text == value) return;
    _textPainter.text = value;
    extractPlaceholderSpans(value);
    _handleSpecialText = hasSpecialText(value);
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
    markNeedsPaint();
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
  TextDirection get textDirection => _textPainter.textDirection;
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
  Locale get locale => _textPainter.locale;
  set locale(Locale value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    markNeedsTextLayout();
  }

  /// The [StrutStyle] used by the renderer's internal [TextPainter] to
  /// determine the strut to use.
  StrutStyle get strutStyle => _textPainter.strutStyle;
  set strutStyle(StrutStyle value) {
    if (_textPainter.strutStyle == value) return;
    _textPainter.strutStyle = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the cursor.
  Color get cursorColor => _cursorColor;
  Color _cursorColor;
  set cursorColor(Color value) {
    if (_cursorColor == value) return;
    _cursorColor = value;
    markNeedsPaint();
  }

  /// The color to use when painting the cursor aligned to the text while
  /// rendering the floating cursor.
  ///
  /// The default is light grey.
  Color get backgroundCursorColor => _backgroundCursorColor;
  Color _backgroundCursorColor;
  set backgroundCursorColor(Color value) {
    if (backgroundCursorColor == value) return;
    _backgroundCursorColor = value;
    markNeedsPaint();
  }

  /// Whether to paint the cursor.
  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value) return;
    if (attached) _showCursor.removeListener(markNeedsPaint);
    _showCursor = value;
    if (attached) _showCursor.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  bool _listenerAttached = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value) return;
    _hasFocus = value;
    if (_hasFocus) {
      assert(!_listenerAttached);
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    } else {
      assert(_listenerAttached);
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }
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
  int get maxLines => _maxLines;
  int _maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int value) {
    assert(value == null || value > 0);
    if (maxLines == value) return;
    _maxLines = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.editableText.minLines}
  int get minLines => _minLines;
  int _minLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set minLines(int value) {
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
  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    markNeedsTextLayout();
  }

  List<ui.TextBox> _selectionRects;

  /// The region of text that is selected, if any.
  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value) return;
    _selection = value;
    _selectionRects = null;
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

  /// {@template flutter.rendering.editable.paintCursorOnTop}
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
    markNeedsLayout();
  }

  /// {@template flutter.rendering.editable.cursorOffset}
  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  /// {@endtemplate}
  Offset get cursorOffset => _cursorOffset;
  Offset _cursorOffset;
  set cursorOffset(Offset value) {
    if (_cursorOffset == value) return;
    _cursorOffset = value;
    markNeedsLayout();
  }

  /// How rounded the corners of the cursor should be.
  Radius get cursorRadius => _cursorRadius;
  Radius _cursorRadius;
  set cursorRadius(Radius value) {
    if (_cursorRadius == value) return;
    _cursorRadius = value;
    markNeedsPaint();
  }

  /// The padding applied to text field. Used to determine the bounds when
  /// moving the floating cursor.
  ///
  /// Defaults to a padding with left, top and right set to 4, bottom to 5.
  EdgeInsets get floatingCursorAddedMargin => _floatingCursorAddedMargin;
  EdgeInsets _floatingCursorAddedMargin;
  set floatingCursorAddedMargin(EdgeInsets value) {
    if (_floatingCursorAddedMargin == value) return;
    _floatingCursorAddedMargin = value;
    markNeedsPaint();
  }

  bool _floatingCursorOn = false;
  Offset _floatingCursorOffset;
  TextPosition _floatingCursorTextPosition;

  /// If false, [describeSemanticsConfiguration] will not set the
  /// configuration's cursor motion or set selection callbacks.
  ///
  /// True by default.
  bool get enableInteractiveSelection => _enableInteractiveSelection;
  bool _enableInteractiveSelection;
  set enableInteractiveSelection(bool value) {
    if (_enableInteractiveSelection == value) return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// {@template flutter.rendering.editable.selectionEnabled}
  /// True if interactive selection is enabled based on the values of
  /// [enableInteractiveSelection] and [obscureText].
  ///
  /// By default [enableInteractiveSelection] is null, obscureText is false,
  /// and this method returns true.
  /// If [enableInteractiveSelection] is null and obscureText is true, then this
  /// method returns false. This is the common case for password fields.
  /// If [enableInteractiveSelection] is non-null then its value is returned. An
  /// app might set it to true to enable interactive selection for a password
  /// field, or to false to unconditionally disable interactive selection.
  /// {@endtemplate}
  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config
      ..value = obscureText
          ? obscuringCharacter * text.toPlainText().length
          : text.toPlainText()
      ..isObscured = obscureText
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true;

    if (hasFocus && selectionEnabled)
      config.onSetSelection = _handleSetSelection;

    if (selectionEnabled && _selection?.isValid == true) {
      config.textSelection = _selection;
      if (_textPainter.getOffsetBefore(_selection.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter =
              _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(_selection.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter =
              _handleMoveCursorForwardByCharacter;
      }
    }
  }

  void _handleSetSelection(TextSelection selection) {
    _handlePotentialSelectionChange(selection, SelectionChangedCause.keyboard);
  }

  void _handleMoveCursorForwardByCharacter(bool extentSelection) {
    final int extentOffset =
        _textPainter.getOffsetAfter(_selection.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : _selection.baseOffset;
    _handlePotentialSelectionChange(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    final int extentOffset =
        _textPainter.getOffsetBefore(_selection.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : _selection.baseOffset;
    _handlePotentialSelectionChange(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extentSelection) {
    final TextRange currentWord =
        _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null) return;
    final TextRange nextWord = _getNextWord(currentWord.end);
    if (nextWord == null) return;
    final int baseOffset =
        extentSelection ? _selection.baseOffset : nextWord.start;
    _handlePotentialSelectionChange(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extentSelection) {
    final TextRange currentWord =
        _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null) return;
    final TextRange previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null) return;
    final int baseOffset =
        extentSelection ? _selection.baseOffset : previousWord.start;
    onSelectionChanged(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      this,
      SelectionChangedCause.keyboard,
    );
  }

  TextRange _getNextWord(int offset) {
    while (true) {
      final TextRange range =
          _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.end;
    }
  }

  TextRange _getPreviousWord(int offset) {
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
  // newline characters from ascii and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(jonahwilliams): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text.codeUnitAt(i);
      switch (codeUnit) {
        case 0x9: // horizontal tab
        case 0xA: // line feed
        case 0xB: // vertical tab
        case 0xC: // form feed
        case 0xD: // carriage return
        case 0x1C: // file separator
        case 0x1D: // group separator
        case 0x1E: // record separator
        case 0x1F: // unit separator
        case 0x20: // space
        case 0xA0: // no-break space
        case 0x1680: // ogham space mark
        case 0x2000: // en quad
        case 0x2001: // em quad
        case 0x2002: // en space
        case 0x2003: // em space
        case 0x2004: // three-per-em space
        case 0x2005: // four-er-em space
        case 0x2006: // six-per-em space
        case 0x2007: // figure space
        case 0x2008: // punctuation space
        case 0x2009: // thin space
        case 0x200A: // hair space
        case 0x202F: // narrow no-break space
        case 0x205F: // medium mathematical space
        case 0x3000: // ideographic space
          break;
        default:
          return false;
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
    _showCursor.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(markNeedsPaint);
    if (_listenerAttached) RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.detach();
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
    }
    return null;
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
    return null;
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
    return null;
  }

  double _maxScrollExtent = 0;

  // We need to check the paint offset here because during animation, the start of
  // the text may position outside the visible region even when the text fits.
  bool get _hasVisualOverflow =>
      _maxScrollExtent > 0 || _paintOffset != Offset.zero;

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
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutText(constraints.maxWidth);

    //final Offset paintOffset = _paintOffset;
    ///zmt
    final Offset effectiveOffset = _effectiveOffset;

    TextSelection textPainterSelection = selection;
    if (handleSpecialText) {
      textPainterSelection =
          convertTextInputSelectionToTextPainterSelection(text, selection);
    }
    if (selection.isCollapsed) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.

      double caretHeight;
      ValueChanged<double> caretHeightCallBack = (value) {
        caretHeight = value;
      };
      final Offset caretOffset = getCaretOffset(
        TextPosition(
            offset: textPainterSelection.extentOffset,
            affinity: selection.affinity),
        caretHeightCallBack: caretHeightCallBack,
        effectiveOffset: effectiveOffset,
        caretPrototype: _caretPrototype,
        handleSpecialText: handleSpecialText,
      );

      final Offset start =
          Offset(0.0, caretHeight ?? preferredLineHeight) + caretOffset;

      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final List<ui.TextBox> boxes =
          _textPainter.getBoxesForSelection(textPainterSelection);
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
  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutText(constraints.maxWidth);
    globalPosition += -_paintOffset;
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
    _layoutText(constraints.maxWidth);
    final Offset caretOffset =
        _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the vertical padding.
    Rect rect = Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight)
        .shift(caretOffset + _paintOffset);
    // Add additional cursor offset (generally only if on iOS).
    if (_cursorOffset != null) rect = rect.shift(_cursorOffset);

    return rect.shift(_getPixelPerfectCursorOffset(rect));
  }

  /// An estimate of the height of a line in the text. See [TextPainter.preferredLineHeight].
  /// This does not required the layout to be updated.
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _preferredHeight(double width) {
    // Lock height to maxLines if needed
    final bool lockedMax = maxLines != null && minLines == null;
    final bool lockedBoth = minLines != null && minLines == maxLines;
    final bool singleLine = maxLines == 1;
    if (singleLine || lockedMax || lockedBoth) {
      return preferredLineHeight * maxLines;
    }

    // Clamp height to minLines or maxLines if needed
    final bool minLimited = minLines != null && minLines > 1;
    final bool maxLimited = maxLines != null;
    if (minLimited || maxLimited) {
      _layoutText(width);
      if (minLimited && _textPainter.height < preferredLineHeight * minLines) {
        return preferredLineHeight * minLines;
      }
      if (maxLimited && _textPainter.height > preferredLineHeight * maxLines) {
        return preferredLineHeight * maxLines;
      }
    }

    // Set the height based on the content
    if (width == double.infinity) {
      final String text = _textPainter.text.toPlainText();
      int lines = 1;
      for (int index = 0; index < text.length; index += 1) {
        if (text.codeUnitAt(index) == 0x0A) // count explicit line breaks
          lines += 1;
      }
      return preferredLineHeight * lines;
    }
    _layoutText(width);
    return math.max(preferredLineHeight, _textPainter.height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(constraints.maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    RenderBox child = firstChild;
    int childIndex = 0;
    while (child != null &&
        childIndex < _textPainter.inlinePlaceholderBoxes.length) {
      final TextParentData textParentData = child.parentData;
      final Matrix4 transform = Matrix4.translationValues(
          textParentData.offset.dx + _effectiveOffset.dx,
          textParentData.offset.dy + _effectiveOffset.dy,
          0.0)
        ..scale(
            textParentData.scale, textParentData.scale, textParentData.scale);
      final bool isHit = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(() {
            final Offset manualPosition =
                (position - textParentData.offset - _effectiveOffset) /
                    textParentData.scale;
            return (transformed.dx - manualPosition.dx).abs() <
                    precisionErrorTolerance &&
                (transformed.dy - manualPosition.dy).abs() <
                    precisionErrorTolerance;
          }());
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childAfter(child);
      childIndex += 1;
    }
    return false;
  }

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (ignorePointer) return;
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onSelectionChanged != null) {
      _tap.addPointer(event);
      _longPress.addPointer(event);
    }
  }

  Offset _lastTapDownPosition;

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// events by calling this method.
  void handleTap() {
    selectPosition(cause: SelectionChangedCause.tap);
  }

  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
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

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressGestureRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }

  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  /// Move selection to the location of the last tap down.
  ///
  /// {@template flutter.rendering.editable.select}
  /// This method is mainly used to translatef user inputs in global positions
  /// into a [TextSelection]. When used in conjunction with a [EditableText],
  /// the selection change is fed back into [TextEditingController.selection].
  ///
  /// If you have a [TextEditingController], it's generally easier to
  /// programmatically manipulate its `value` or `selection` directly.
  /// {@endtemplate}
  void selectPosition({@required SelectionChangedCause cause}) {
    selectPositionAt(from: _lastTapDownPosition, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  void selectPositionAt(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutText(constraints.maxWidth);
    if (onSelectionChanged != null) {
      TextPosition fromPosition =
          _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
      TextPosition toPosition = to == null
          ? null
          : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));

      //zmt
      if (handleSpecialText) {
        fromPosition =
            convertTextPainterPostionToTextInputPostion(text, fromPosition);
        toPosition =
            convertTextPainterPostionToTextInputPostion(text, toPosition);
      }

      int baseOffset = fromPosition.offset;
      int extentOffset = fromPosition.offset;

      if (toPosition != null) {
        baseOffset = math.min(fromPosition.offset, toPosition.offset);
        extentOffset = math.max(fromPosition.offset, toPosition.offset);
      }

      final TextSelection newSelection = TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        affinity: fromPosition.affinity,
      );
      // Call [onSelectionChanged] only when the selection actually changed.
      if (newSelection != _selection) {
        _handlePotentialSelectionChange(newSelection, cause);
      }
    }
  }

  /// Select a word around the location of the last tap down.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWord({@required SelectionChangedCause cause}) {
    selectWordsInRange(from: _lastTapDownPosition, cause: cause);
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordsInRange(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutText(constraints.maxWidth);
    if (onSelectionChanged != null) {
      final TextPosition firstPosition =
          _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
      final TextSelection firstWord = _selectWordAtOffset(firstPosition);
      final TextSelection lastWord = to == null
          ? firstWord
          : _selectWordAtOffset(_textPainter
              .getPositionForOffset(globalToLocal(to - _paintOffset)));

      _handlePotentialSelectionChange(
        TextSelection(
          baseOffset: firstWord.base.offset,
          extentOffset: lastWord.extent.offset,
          affinity: firstWord.affinity,
        ),
        cause,
      );
    }
  }

  /// Move the selection to the beginning or end of a word.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordEdge({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(
          globalToLocal(_lastTapDownPosition - _paintOffset));

      final TextRange word = _textPainter.getWordBoundary(position);
      TextSelection selection;

      ///zmt
      if (position.offset - word.start <= 1) {
        selection = handleSpecialText
            ? convertTextPainterSelectionToTextInputSelection(
                text,
                TextSelection.collapsed(
                    offset: word.start, affinity: TextAffinity.downstream))
            : TextSelection.collapsed(
                offset: word.start, affinity: TextAffinity.downstream);
      } else {
        selection = handleSpecialText
            ? convertTextPainterSelectionToTextInputSelection(
                text,
                TextSelection.collapsed(
                    offset: word.end, affinity: TextAffinity.upstream))
            : TextSelection.collapsed(
                offset: word.end, affinity: TextAffinity.upstream);
      }
      _handlePotentialSelectionChange(
        selection,
        cause,
      );
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    assert(_textLayoutLastWidth == constraints.maxWidth);

    ///zmt
    final TextRange word = _textPainter.getWordBoundary(position);
    TextSelection selection;
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      selection = TextSelection.fromPosition(position);
    } else {
      selection = TextSelection(baseOffset: word.start, extentOffset: word.end);
    }

    return handleSpecialText
        ? convertTextPainterSelectionToTextInputSelection(text, selection,
            selectWord: true)
        : selection;
  }

  Rect _caretPrototype;

  @override
  void layoutText(
      {double minWidth = 0.0,
      double maxWidth = double.infinity,
      double constraintWidth = double.infinity}) {
    _layoutText(constraintWidth);
  }

  void _layoutText(double constraintWidth, {bool forceLayout: false}) {
    assert(constraintWidth != null);
    if (_textLayoutLastWidth == constraintWidth && !forceLayout) return;
    final double caretMargin = _kCaretGap + cursorWidth;
    final double availableWidth = math.max(0.0, constraintWidth - caretMargin);
    final double maxWidth = _isMultiline ? availableWidth : double.infinity;
    _textPainter.layout(minWidth: availableWidth, maxWidth: maxWidth);
    _textLayoutLastWidth = constraintWidth;
    _updateVisibleRegionMinY();
  }

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
  Rect get _getCaretPrototype {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight + 2);
      default:
        return Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth,
            preferredLineHeight - 2.0 * _kCaretHeightOffset);
    }
  }

  @override
  void performLayout() {
    layoutChildren(constraints);
    _layoutText(constraints.maxWidth, forceLayout: true);
    setParentData();
    _caretPrototype = _getCaretPrototype;
    _selectionRects = null;
    // We grab _textPainter.size here because assigning to `size` on the next
    // line will trigger us to validate our intrinsic sizes, which will change
    // _textPainter's layout because the intrinsic size calculations are
    // destructive, which would mean we would get different results if we later
    // used properties on _textPainter in this method.
    // Other _textPainter state like didExceedMaxLines will also be affected,
    // though we currently don't use those here.
    // See also RenderParagraph which has a similar issue.
    final Size textPainterSize = _textPainter.size;
    size = Size(constraints.maxWidth,
        constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize = Size(
        textPainterSize.width + _kCaretGap + cursorWidth,
        textPainterSize.height);
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

  void _paintCaret(Canvas canvas, Offset effectiveOffset,
      TextPosition textPosition, TextPosition textInputPosition) {
    assert(_textLayoutLastWidth == constraints.maxWidth);

    // If the floating cursor is enabled, the text cursor's color is [backgroundCursorColor] while
    // the floating cursor's color is _cursorColor;
    final Paint paint = Paint()
      ..color = _floatingCursorOn ? backgroundCursorColor : _cursorColor;

    double caretHeight;
    ValueChanged<double> caretHeightCallBack = (value) {
      caretHeight = value;
    };
    final Offset caretOffset = getCaretOffset(
      textPosition,
      caretHeightCallBack: caretHeightCallBack,
      effectiveOffset: effectiveOffset,
      caretPrototype: _caretPrototype,
      handleSpecialText: handleSpecialText,
    );

    Rect caretRect = _caretPrototype.shift(caretOffset);
    if (_cursorOffset != null) caretRect = caretRect.shift(_cursorOffset);

    var fullHeight =
        _textPainter.getFullHeightForCaret(textPosition, _caretPrototype) ??
            caretHeight;
    if (fullHeight != null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          {
//            final double heightDiff = fullHeight - caretRect.height;
//            // Center the caret vertically along the text.
//            caretRect = Rect.fromLTWH(
//              caretRect.left,
//              caretRect.top + heightDiff / 2,
//              caretRect.width,
//              caretRect.height,
//            );
            caretRect = Rect.fromLTWH(
              caretRect.left,
              caretRect.top,
              caretRect.width,
              fullHeight,
            );
            break;
          }
        default:
          {
            // Override the height to take the full height of the glyph at the TextPosition
            // when not on iOS. iOS has special handling that creates a taller caret.
            // TODO(garyq): See the TODO for _getCaretPrototype.
            caretRect = Rect.fromLTWH(
              caretRect.left,
              caretRect.top - _kCaretHeightOffset,
              caretRect.width,
              fullHeight,
            );
            break;
          }
      }
    }

    caretRect = caretRect.shift(_getPixelPerfectCursorOffset(caretRect));

    if (cursorRadius == null) {
      canvas.drawRect(caretRect, paint);
    } else {
      final RRect caretRRect = RRect.fromRectAndRadius(caretRect, cursorRadius);
      canvas.drawRRect(caretRRect, paint);
    }

    if (caretRect != _lastCaretRect) {
      _lastCaretRect = caretRect;
      if (onCaretChanged != null) onCaretChanged(caretRect);
    }
  }

  /// Sets the screen position of the floating cursor and the text position
  /// closest to the cursor.
  void setFloatingCursor(FloatingCursorDragState state, Offset boundedOffset,
      TextPosition lastTextPosition,
      {double resetLerpValue}) {
    assert(state != null);
    assert(boundedOffset != null);
    assert(lastTextPosition != null);

    if (state == FloatingCursorDragState.Start) {
      _relativeOrigin = const Offset(0, 0);
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }
    _floatingCursorOn = state != FloatingCursorDragState.End;
    _resetFloatingCursorAnimationValue = resetLerpValue;
    if (_floatingCursorOn) {
      _floatingCursorOffset = boundedOffset;
      _floatingCursorTextPosition = lastTextPosition;
    }
    markNeedsPaint();
  }

  void _paintFloatingCaret(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    assert(_floatingCursorOn);

    // We always want the floating cursor to render at full opacity.
    final Paint paint = Paint()..color = _cursorColor.withOpacity(0.75);
    double sizeAdjustmentX = _kFloatingCaretSizeIncrease.dx;
    double sizeAdjustmentY = _kFloatingCaretSizeIncrease.dy;

    if (_resetFloatingCursorAnimationValue != null) {
      sizeAdjustmentX =
          ui.lerpDouble(sizeAdjustmentX, 0, _resetFloatingCursorAnimationValue);
      sizeAdjustmentY =
          ui.lerpDouble(sizeAdjustmentY, 0, _resetFloatingCursorAnimationValue);
    }

    final Rect floatingCaretPrototype = Rect.fromLTRB(
      _caretPrototype.left - sizeAdjustmentX,
      _caretPrototype.top - sizeAdjustmentY,
      _caretPrototype.right + sizeAdjustmentX,
      _caretPrototype.bottom + sizeAdjustmentY,
    );

    final Rect caretRect = floatingCaretPrototype.shift(effectiveOffset);
    const Radius floatingCursorRadius = Radius.circular(_kFloatingCaretRadius);
    final RRect caretRRect =
        RRect.fromRectAndRadius(caretRect, floatingCursorRadius);
    canvas.drawRRect(caretRRect, paint);
  }

  // The relative origin in relation to the distance the user has theoretically
  // dragged the floating cursor offscreen. This value is used to account for the
  // difference in the rendering position and the raw offset value.
  Offset _relativeOrigin = const Offset(0, 0);
  Offset _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  double _resetFloatingCursorAnimationValue;

  /// Returns the position within the text field closest to the raw cursor offset.
  Offset calculateBoundedFloatingCursorOffset(Offset rawCursorOffset) {
    Offset deltaPosition = const Offset(0, 0);
    final double topBound = -floatingCursorAddedMargin.top;
    final double bottomBound = _textPainter.height -
        preferredLineHeight +
        floatingCursorAddedMargin.bottom;
    final double leftBound = -floatingCursorAddedMargin.left;
    final double rightBound =
        _textPainter.width + floatingCursorAddedMargin.right;

    if (_previousOffset != null)
      deltaPosition = rawCursorOffset - _previousOffset;

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

  void _paintContents(PaintingContext context, Offset offset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final Offset effectiveOffset = offset + _paintOffset;

    bool showSelection = false;
    bool showCaret = false;

    ///zmt
    var actualSelection = handleSpecialText
        ? convertTextInputSelectionToTextPainterSelection(text, _selection)
        : _selection;

    if (actualSelection != null && !_floatingCursorOn) {
      if (actualSelection.isCollapsed &&
          _showCursor.value &&
          cursorColor != null)
        showCaret = true;
      else if (!actualSelection.isCollapsed && _selectionColor != null)
        showSelection = true;
      _updateSelectionExtentsVisibility(effectiveOffset, actualSelection);
    }
    if (showSelection) {
      _selectionRects ??= _textPainter.getBoxesForSelection(actualSelection);
      _paintSelection(context.canvas, effectiveOffset);
    }

    paintWidgets(context, effectiveOffset);

    ///zmt
    _paintSpecialText(context, effectiveOffset);

    // On iOS, the cursor is painted over the text, on Android, it's painted
    // under it.
    if (paintCursorAboveText)
      _textPainter.paint(context.canvas, effectiveOffset);

    if (showCaret)
      _paintCaret(context.canvas, effectiveOffset, actualSelection.extent,
          _selection.extent);

    if (!paintCursorAboveText)
      _textPainter.paint(context.canvas, effectiveOffset);

    if (_floatingCursorOn) {
      if (_resetFloatingCursorAnimationValue == null) {
        _paintCaret(
            context.canvas,
            effectiveOffset,
            convertTextInputPostionToTextPainterPostion(
                text, _floatingCursorTextPosition),
            _floatingCursorTextPosition);
      }
      _paintFloatingCaret(context.canvas, _floatingCursorOffset);
    }
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');
    assert(_selectionRects != null);
    final Paint paint = Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
  }

  Offset _initialOffset;
  Offset get _effectiveOffset => (_initialOffset ?? Offset.zero) + _paintOffset;

  @override
  void paint(PaintingContext context, Offset offset) {
    ///zmt
    _initialOffset = offset;

    _layoutText(constraints.maxWidth);
    if (_hasVisualOverflow)
      context.pushClipRect(
          needsCompositing, offset, Offset.zero & size, _paintContents);
    else
      _paintContents(context, offset);
  }

  void _paintSpecialText(PaintingContext context, Offset offset) {
    if (!handleSpecialText) return;

    final Canvas canvas = context.canvas;

    canvas.save();

    ///move to extended text
    canvas.translate(offset.dx, offset.dy);

    ///we have move the canvas, so rect top left should be (0,0)
    final Rect rect = Offset(0.0, 0.0) & size;
    _paintSpecialTextChildren(<InlineSpan>[text], canvas, rect);
    canvas.restore();
  }

  void _paintSpecialTextChildren(
      List<InlineSpan> textSpans, Canvas canvas, Rect rect,
      {int textOffset: 0}) {
    if (textSpans == null) return;

    for (InlineSpan ts in textSpans) {
      Offset topLeftOffset = getOffsetForCaret(
        TextPosition(offset: textOffset),
        rect,
      );
      //skip invalid or overflow
      if (topLeftOffset == null ||
          (textOffset != 0 && topLeftOffset == Offset.zero)) {
        return;
      }

      if (ts is BackgroundTextSpan) {
        var painter = ts.layout(_textPainter);
        Rect textRect = topLeftOffset & painter.size;
        Offset endOffset;
        if (textRect.right > rect.right) {
          int endTextOffset = textOffset + ts.toPlainText().length;
          endOffset = _findEndOffset(rect, endTextOffset);
        }

        ts.paint(canvas, topLeftOffset, rect,
            endOffset: endOffset, wholeTextPainter: _textPainter);
      } else if (ts is TextSpan && ts.children != null) {
        _paintSpecialTextChildren(ts.children, canvas, rect,
            textOffset: textOffset);
      }
      textOffset += ts.toPlainText().length;
    }
  }

  Offset _findEndOffset(Rect rect, int endTextOffset) {
    Offset endOffset = getOffsetForCaret(
      TextPosition(offset: endTextOffset, affinity: TextAffinity.upstream),
      rect,
    );
    //overflow
    if (endOffset == null || (endTextOffset != 0 && endOffset == Offset.zero)) {
      return _findEndOffset(rect, endTextOffset - 1);
    }
    return endOffset;
  }

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    _layoutText(constraints.maxWidth);
    return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
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
      text.toDiagnosticsNode(
        name: 'text',
        style: DiagnosticsTreeStyle.transition,
      ),
    ];
  }

//  double _computeIntrinsicHeight(double width) {
//    if (!_canComputeIntrinsics()) {
//      return 0.0;
//    }
//    _computeChildrenHeightWithMinIntrinsics(width);
//    _layoutText(width);
//    return _textPainter.height;
//  }

  @override
  Size getSize() {
    return this.size;
  }

  @override
  bool get isAttached => attached;

  @override
  Offset getlocalToGlobal(Offset point, {RenderObject ancestor}) {
    return localToGlobal(point, ancestor: ancestor);
  }

  TextOverflow get overflow => TextOverflow.visible;

  @override
  bool get softWrap => false;

  @override
  TextPainter get textPainter => _textPainter;
}
