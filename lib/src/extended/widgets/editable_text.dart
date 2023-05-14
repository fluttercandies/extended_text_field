import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

part 'package:extended_text_field/src/official/widgets/editable_text.dart';
part 'package:extended_text_field/src/official/rendering/editable.dart';
part 'package:extended_text_field/src/extended/rendering/editable.dart';

/// Signature for a widget builder that builds a context menu for the given
/// [EditableTextState].
///
/// See also:
///
///  * [SelectableRegionContextMenuBuilder], which performs the same role for
///    [SelectableRegion].
typedef ExtendedEditableTextContextMenuBuilder = Widget Function(
  BuildContext context,
  ExtendedEditableTextState editableTextState,
);

/// [EditableText]
///
class ExtendedEditableText extends EditableText {
  ExtendedEditableText({
    super.key,
    required super.controller,
    required super.focusNode,
    super.readOnly = false,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.autocorrect = true,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions = true,
    required super.style,
    super.strutStyle,
    required super.cursorColor,
    required super.backgroundCursorColor,
    super.textAlign = TextAlign.start,
    super.textDirection,
    super.locale,
    super.textScaleFactor,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.forceLine = true,
    super.textHeightBehavior,
    super.textWidthBasis = TextWidthBasis.parent,
    super.autofocus = false,
    super.showCursor,
    super.showSelectionHandles = false,
    super.selectionColor,
    super.selectionControls,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization = TextCapitalization.none,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.onSelectionChanged,
    super.onSelectionHandleTapped,
    super.onTapOutside,
    super.inputFormatters,
    super.mouseCursor,
    super.rendererIgnoresPointer = false,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates = false,
    super.cursorOffset,
    super.paintCursorAboveText = false,
    super.selectionHeightStyle = ui.BoxHeightStyle.tight,
    super.selectionWidthStyle = ui.BoxWidthStyle.tight,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.keyboardAppearance = Brightness.light,
    super.dragStartBehavior = DragStartBehavior.start,
    super.enableInteractiveSelection,
    super.scrollController,
    super.scrollPhysics,
    super.autocorrectionTextRectColor,
    @Deprecated(
      'Use `contextMenuBuilder` instead. '
      'This feature was deprecated after v3.3.0-0.5.pre.',
    )
        ToolbarOptions? toolbarOptions,
    super.autofillHints = const <String>[],
    super.autofillClient,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scrollBehavior,
    super.scribbleEnabled = true,
    super.enableIMEPersonalizedLearning = true,
    super.contentInsertionConfiguration,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration = TextMagnifierConfiguration.disabled,
    super.undoController,
  });

  @override
  _EditableTextState createState() {
    return ExtendedEditableTextState();
  }
}

class ExtendedEditableTextState extends _EditableTextState {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final TextSelectionControls? controls = widget.selectionControls;
    return _CompositionCallback(
      compositeCallback: _compositeCallback,
      enabled: _hasInputConnection,
      child: TextFieldTapRegion(
        onTapOutside: widget.onTapOutside ?? _defaultOnTapOutside,
        debugLabel: kReleaseMode ? null : 'EditableText',
        child: MouseRegion(
          cursor: widget.mouseCursor ?? SystemMouseCursors.text,
          child: Actions(
            actions: _actions,
            child: UndoHistory<TextEditingValue>(
              value: widget.controller,
              onTriggered: (TextEditingValue value) {
                userUpdateTextEditingValue(
                    value, SelectionChangedCause.keyboard);
              },
              shouldChangeUndoStack:
                  (TextEditingValue? oldValue, TextEditingValue newValue) {
                if (!newValue.selection.isValid) {
                  return false;
                }

                if (oldValue == null) {
                  return true;
                }

                switch (defaultTargetPlatform) {
                  case TargetPlatform.iOS:
                  case TargetPlatform.macOS:
                  case TargetPlatform.fuchsia:
                  case TargetPlatform.linux:
                  case TargetPlatform.windows:
                    // Composing text is not counted in history coalescing.
                    if (!widget.controller.value.composing.isCollapsed) {
                      return false;
                    }
                    break;
                  case TargetPlatform.android:
                    // Gboard on Android puts non-CJK words in composing regions. Coalesce
                    // composing text in order to allow the saving of partial words in that
                    // case.
                    break;
                }

                return oldValue.text != newValue.text ||
                    oldValue.composing != newValue.composing;
              },
              focusNode: widget.focusNode,
              controller: widget.undoController,
              child: Focus(
                focusNode: widget.focusNode,
                includeSemantics: false,
                debugLabel: kReleaseMode ? null : 'EditableText',
                child: Scrollable(
                  key: _scrollableKey,
                  excludeFromSemantics: true,
                  axisDirection:
                      _isMultiline ? AxisDirection.down : AxisDirection.right,
                  controller: _scrollController,
                  physics: widget.scrollPhysics,
                  dragStartBehavior: widget.dragStartBehavior,
                  restorationId: widget.restorationId,
                  // If a ScrollBehavior is not provided, only apply scrollbars when
                  // multiline. The overscroll indicator should not be applied in
                  // either case, glowing or stretching.
                  scrollBehavior: widget.scrollBehavior ??
                      ScrollConfiguration.of(context).copyWith(
                        scrollbars: _isMultiline,
                        overscroll: false,
                      ),
                  viewportBuilder:
                      (BuildContext context, ViewportOffset offset) {
                    return CompositedTransformTarget(
                      link: _toolbarLayerLink,
                      child: Semantics(
                        onCopy: _semanticsOnCopy(controls),
                        onCut: _semanticsOnCut(controls),
                        onPaste: _semanticsOnPaste(controls),
                        child: _ScribbleFocusable(
                          focusNode: widget.focusNode,
                          editableKey: _editableKey,
                          enabled: widget.scribbleEnabled,
                          updateSelectionRects: () {
                            _openInputConnection();
                            _updateSelectionRects(force: true);
                          },
                          child: _ExtendedEditable(
                            key: _editableKey,
                            startHandleLayerLink: _startHandleLayerLink,
                            endHandleLayerLink: _endHandleLayerLink,
                            inlineSpan: buildTextSpan(),
                            value: _value,
                            cursorColor: _cursorColor,
                            backgroundCursorColor: widget.backgroundCursorColor,
                            showCursor: _EditableText.debugDeterministicCursor
                                ? ValueNotifier<bool>(widget.showCursor)
                                : _cursorVisibilityNotifier,
                            forceLine: widget.forceLine,
                            readOnly: widget.readOnly,
                            hasFocus: _hasFocus,
                            maxLines: widget.maxLines,
                            minLines: widget.minLines,
                            expands: widget.expands,
                            strutStyle: widget.strutStyle,
                            selectionColor:
                                _selectionOverlay?.spellCheckToolbarIsVisible ??
                                        false
                                    ? _spellCheckConfiguration
                                            .misspelledSelectionColor ??
                                        widget.selectionColor
                                    : widget.selectionColor,
                            textScaleFactor: widget.textScaleFactor ??
                                MediaQuery.textScaleFactorOf(context),
                            textAlign: widget.textAlign,
                            textDirection: _textDirection,
                            locale: widget.locale,
                            textHeightBehavior: widget.textHeightBehavior ??
                                DefaultTextHeightBehavior.maybeOf(context),
                            textWidthBasis: widget.textWidthBasis,
                            obscuringCharacter: widget.obscuringCharacter,
                            obscureText: widget.obscureText,
                            offset: offset,
                            onCaretChanged: _handleCaretChanged,
                            rendererIgnoresPointer:
                                widget.rendererIgnoresPointer,
                            cursorWidth: widget.cursorWidth,
                            cursorHeight: widget.cursorHeight,
                            cursorRadius: widget.cursorRadius,
                            cursorOffset: widget.cursorOffset ?? Offset.zero,
                            selectionHeightStyle: widget.selectionHeightStyle,
                            selectionWidthStyle: widget.selectionWidthStyle,
                            paintCursorAboveText: widget.paintCursorAboveText,
                            enableInteractiveSelection: _userSelectionEnabled,
                            textSelectionDelegate: this,
                            devicePixelRatio: _devicePixelRatio,
                            promptRectRange: _currentPromptRectRange,
                            promptRectColor: widget.autocorrectionTextRectColor,
                            clipBehavior: widget.clipBehavior,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtendedEditable extends _Editable {
  _ExtendedEditable({
    super.key,
    required super.inlineSpan,
    required super.value,
    required super.startHandleLayerLink,
    required super.endHandleLayerLink,
    super.cursorColor,
    super.backgroundCursorColor,
    required super.showCursor,
    required super.forceLine,
    required super.readOnly,
    super.textHeightBehavior,
    required super.textWidthBasis,
    required super.hasFocus,
    required super.maxLines,
    super.minLines,
    required super.expands,
    super.strutStyle,
    super.selectionColor,
    required super.textScaleFactor,
    required super.textAlign,
    required super.textDirection,
    super.locale,
    required super.obscuringCharacter,
    required super.obscureText,
    required super.offset,
    super.onCaretChanged,
    super.rendererIgnoresPointer = false,
    required super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    required super.cursorOffset,
    required super.paintCursorAboveText,
    super.selectionHeightStyle = ui.BoxHeightStyle.tight,
    super.selectionWidthStyle = ui.BoxWidthStyle.tight,
    super.enableInteractiveSelection = true,
    required super.textSelectionDelegate,
    required super.devicePixelRatio,
    super.promptRectRange,
    super.promptRectColor,
    required super.clipBehavior,
  });

  @override
  ExtendedRenderEditable createRenderObject(BuildContext context) {
    return ExtendedRenderEditable(
      text: inlineSpan,
      cursorColor: cursorColor,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      backgroundCursorColor: backgroundCursorColor,
      showCursor: showCursor,
      forceLine: forceLine,
      readOnly: readOnly,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      strutStyle: strutStyle,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      selection: value.selection,
      offset: offset,
      onCaretChanged: onCaretChanged,
      ignorePointer: rendererIgnoresPointer,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
      promptRectRange: promptRectRange,
      promptRectColor: promptRectColor,
      clipBehavior: clipBehavior,
    );
  }
}
