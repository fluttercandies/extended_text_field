// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:extended_text_field/src/extended_render_editable.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// The time the cursor is static in opacity before animating to become
// transparent.
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

// Number of cursor ticks during which the most recently entered character
// is shown in an obscured text field.
const int _kObscureShowLatestCharCursorTicks = 3;

/// A basic text input field.
///
/// This widget interacts with the [TextInput] service to let the user edit the
/// text it contains. It also provides scrolling, selection, and cursor
/// movement. This widget does not provide any focus management (e.g.,
/// tap-to-focus).
///
/// ## Input Actions
///
/// A [TextInputAction] can be provided to customize the appearance of the
/// action button on the soft keyboard for Android and iOS. The default action
/// is [TextInputAction.done].
///
/// Many [TextInputAction]s are common between Android and iOS. However, if an
/// [inputAction] is provided that is not supported by the current
/// platform in debug mode, an error will be thrown when the corresponding
/// EditableText receives focus. For example, providing iOS's "emergencyCall"
/// action when running on an Android device will result in an error when in
/// debug mode. In release mode, incompatible [TextInputAction]s are replaced
/// either with "unspecified" on Android, or "default" on iOS. Appropriate
/// [inputAction]s can be chosen by checking the current platform and then
/// selecting the appropriate action.
///
/// ## Lifecycle
///
/// Upon completion of editing, like pressing the "done" button on the keyboard,
/// two actions take place:
///
///   1st: Editing is finalized. The default behavior of this step includes
///   an invocation of [onChanged]. That default behavior can be overridden.
///   See [onEditingComplete] for details.
///
///   2nd: [onSubmitted] is invoked with the user's input value.
///
/// [onSubmitted] can be used to manually move focus to another input widget
/// when a user finishes with the currently focused input widget.
///
/// Rather than using this widget directly, consider using [TextField], which
/// is a full-featured, material-design text input field with placeholder text,
/// labels, and [Form] integration.
///
/// ## Gesture Events Handling
///
/// This widget provides rudimentary, platform-agnostic gesture handling for
/// user actions such as tapping, long-pressing and scrolling when
/// [rendererIgnoresPointer] is false (false by default). To tightly conform
/// to the platform behavior with respect to input gestures in text fields, use
/// [TextField] or [CupertinoTextField]. For custom selection behavior, call
/// methods such as [RenderEditable.selectPosition],
/// [RenderEditable.selectWord], etc. programmatically.
///
/// See also:
///
///  * [TextField], which is a full-featured, material-design text input field
///    with placeholder text, labels, and [Form] integration.
class ExtendedEditableText extends StatefulWidget {
  /// Creates a basic text input control.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must be null or greater than zero.
  ///
  /// If [keyboardType] is not set or is null, its value will be inferred from
  /// [autofillHints], if [autofillHints] is not empty. Otherwise it defaults to
  /// [TextInputType.text] if [maxLines] is exactly one, and
  /// [TextInputType.multiline] if [maxLines] is null or greater than one.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  ///
  /// The [controller], [focusNode], [obscureText], [autocorrect], [autofocus],
  /// [showSelectionHandles], [enableInteractiveSelection], [forceLine],
  /// [style], [cursorColor], [cursorOpacityAnimates],[backgroundCursorColor],
  /// [enableSuggestions], [paintCursorAboveText], [selectionHeightStyle],
  /// [selectionWidthStyle], [textAlign], [dragStartBehavior], [scrollPadding],
  /// [dragStartBehavior], [toolbarOptions], [rendererIgnoresPointer], and
  /// [readOnly] arguments must not be null.
  ExtendedEditableText({
    Key? key,
    this.specialTextSpanBuilder,
    required this.controller,
    required this.focusNode,
    this.readOnly = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.enableSuggestions = true,
    required this.style,
    StrutStyle? strutStyle,
    required this.cursorColor,
    required this.backgroundCursorColor,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.forceLine = true,
    this.textHeightBehavior,
    this.textWidthBasis = TextWidthBasis.parent,
    this.autofocus = false,
    bool? showCursor,
    this.showSelectionHandles = false,
    this.selectionColor,
    this.selectionControls,
    TextInputType? keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.onSelectionChanged,
    this.onSelectionHandleTapped,
    List<TextInputFormatter>? inputFormatters,
    this.mouseCursor,
    this.rendererIgnoresPointer = false,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates = false,
    this.cursorOffset,
    this.paintCursorAboveText = false,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.scrollController,
    this.scrollPhysics,
    this.autocorrectionTextRectColor,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
    this.autofillHints,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
  })  : assert(obscuringCharacter.length == 1),
        smartDashesType = smartDashesType ??
            (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
        smartQuotesType = smartQuotesType ??
            (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(!obscureText || maxLines == 1,
            'Obscured fields cannot be multiline.'),
        _strutStyle = strutStyle,
        keyboardType = keyboardType ??
            _inferKeyboardType(
                autofillHints: autofillHints, maxLines: maxLines),
        inputFormatters = maxLines == 1
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.singleLineFormatter,
                ...inputFormatters ??
                    const Iterable<TextInputFormatter>.empty(),
              ]
            : inputFormatters,
        showCursor = showCursor ?? !readOnly,
        super(key: key);

  ///build your ccustom text span
  final SpecialTextSpanBuilder? specialTextSpanBuilder;

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// {@template flutter.widgets.editableText.obscuringCharacter}
  /// Character used for obscuring text if [obscureText] is true.
  ///
  /// Must be only a single character.
  ///
  /// Defaults to the character U+2022 BULLET (•).
  /// {@endtemplate}
  final String obscuringCharacter;

  /// {@template flutter.widgets.editableText.obscureText}
  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the text field are
  /// replaced by [obscuringCharacter].
  ///
  /// Defaults to false. Cannot be null.
  /// {@endtemplate}
  final bool obscureText;

  /// {@macro flutter.dart:ui.textHeightBehavior},
  final TextHeightBehavior? textHeightBehavior;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// {@template flutter.widgets.editableText.readOnly}
  /// Whether the text can be changed.
  ///
  /// When this is set to true, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to false. Must not be null.
  /// {@endtemplate}
  final bool readOnly;

  /// Whether the text will take the full width regardless of the text width.
  ///
  /// When this is set to false, the width will be based on text width, which
  /// will also be affected by [textWidthBasis].
  ///
  /// Defaults to true. Must not be null.
  ///
  /// See also:
  ///
  ///  * [textWidthBasis], which controls the calculation of text width.
  final bool forceLine;

  /// Configuration of toolbar options.
  ///
  /// By default, all options are enabled. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// Whether to show selection handles.
  ///
  /// When a selection is active, there will be two handles at each side of
  /// boundary, or one handle if the selection is collapsed. The handles can be
  /// dragged to adjust the selection.
  ///
  /// See also:
  ///
  ///  * [showCursor], which controls the visibility of the cursor..
  final bool showSelectionHandles;

  /// {@template flutter.widgets.editableText.showCursor}
  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the [EditableText] is focused.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [showSelectionHandles], which controls the visibility of the selection handles.
  final bool showCursor;

  /// {@template flutter.widgets.editableText.autocorrect}
  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  /// {@endtemplate}
  final bool autocorrect;

  /// {@macro flutter.services.textInput.smartDashesType}
  final SmartDashesType smartDashesType;

  /// {@macro flutter.services.textInput.smartQuotesType}
  final SmartQuotesType smartQuotesType;

  /// {@macro flutter.services.textInput.enableSuggestions}
  final bool enableSuggestions;

  /// The text style to use for the editable text.
  final TextStyle style;

  /// {@template flutter.widgets.editableText.strutStyle}
  /// The strut style used for the vertical layout.
  ///
  /// [StrutStyle] is used to establish a predictable vertical layout.
  /// Since fonts may vary depending on user input and due to font
  /// fallback, [StrutStyle.forceStrutHeight] is enabled by default
  /// to lock all lines to the height of the base [TextStyle], provided by
  /// [style]. This ensures the typed text fits within the allotted space.
  ///
  /// If null, the strut used will is inherit values from the [style] and will
  /// have [StrutStyle.forceStrutHeight] set to true. When no [style] is
  /// passed, the theme's [TextStyle] will be used to generate [strutStyle]
  /// instead.
  ///
  /// To disable strut-based vertical alignment and allow dynamic vertical
  /// layout based on the glyphs typed, use [StrutStyle.disabled].
  ///
  /// Flutter's strut is based on [typesetting strut](https://en.wikipedia.org/wiki/Strut_(typesetting))
  /// and CSS's [line-height](https://www.w3.org/TR/CSS2/visudet.html#line-height).
  /// {@endtemplate}
  ///
  /// Within editable text and textfields, [StrutStyle] will not use its standalone
  /// default values, and will instead inherit omitted/null properties from the
  /// [TextStyle] instead. See [StrutStyle.inheritFromTextStyle].
  StrutStyle? get strutStyle {
    return _strutStyle;

    ///not good for widgetSpan
    // if (_strutStyle == null) {
    //   return style != null
    //       ? StrutStyle.fromTextStyle(style, forceStrutHeight: true)
    //       : const StrutStyle();
    // }
    // return _strutStyle.inheritFromTextStyle(style);
  }

  final StrutStyle? _strutStyle;

  /// {@template flutter.widgets.editableText.textAlign}
  /// How the text should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.start] and cannot be null.
  /// {@endtemplate}
  final TextAlign textAlign;

  /// {@template flutter.widgets.editableText.textDirection}
  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the text is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// When LTR text is entered into an RTL field, or RTL text is entered into an
  /// LTR field, [LRM](https://en.wikipedia.org/wiki/Left-to-right_mark) or
  /// [RLM](https://en.wikipedia.org/wiki/Right-to-left_mark) characters will be
  /// inserted alongside whitespace characters, respectively. This is to
  /// eliminate ambiguous directionality in whitespace and ensure proper caret
  /// placement. These characters will affect the length of the string and may
  /// need to be parsed out when doing things like string comparison with other
  /// text.
  ///
  /// Defaults to the ambient [Directionality], if any.
  /// {@endtemplate}
  final TextDirection? textDirection;

  /// {@template flutter.widgets.editableText.textCapitalization}
  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.none]. Must not be null.
  ///
  /// See also:
  ///
  ///  * [TextCapitalization], for a description of each capitalization behavior.
  ///
  /// {@endtemplate}
  final TextCapitalization textCapitalization;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderEditable.locale] for more information.
  final Locale? locale;

  /// {@template flutter.widgets.editableText.textScaleFactor}
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  /// {@endtemplate}
  final double? textScaleFactor;

  /// The color to use when painting the cursor.
  ///
  /// Cannot be null.
  final Color cursorColor;

  /// The color to use when painting the autocorrection Rect.
  ///
  /// For [CupertinoTextField]s, the value is set to the ambient
  /// [CupertinoThemeData.primaryColor] with 20% opacity. For [TextField]s, the
  /// value is null on non-iOS platforms and the same color used in [CupertinoTextField]
  /// on iOS.
  ///
  /// Currently the autocorrection Rect only appears on iOS.
  ///
  /// Defaults to null, which disables autocorrection Rect painting.
  final Color? autocorrectionTextRectColor;

  /// The color to use when painting the background cursor aligned with the text
  /// while rendering the floating cursor.
  ///
  /// Cannot be null. By default it is the disabled grey color from
  /// CupertinoColors.
  final Color backgroundCursorColor;

  /// {@template flutter.widgets.editableText.maxLines}
  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  ///
  /// If this is null, there is no limit to the number of lines, and the text
  /// container will start with enough vertical space for one line and
  /// automatically grow to accommodate additional lines as they are entered.
  ///
  /// If this is not null, the value must be greater than zero, and it will lock
  /// the input to the given number of lines and take up enough horizontal space
  /// to accommodate that number of lines. Setting [minLines] as well allows the
  /// input to grow between the indicated range.
  ///
  /// The full set of behaviors possible with [minLines] and [maxLines] are as
  /// follows. These examples apply equally to `TextField`, `TextFormField`, and
  /// `EditableText`.
  ///
  /// Input that occupies a single line and scrolls horizontally as needed.
  /// ```dart
  /// TextField()
  /// ```
  ///
  /// Input whose height grows from one line up to as many lines as needed for
  /// the text that was entered. If a height limit is imposed by its parent, it
  /// will scroll vertically when its height reaches that limit.
  /// ```dart
  /// TextField(maxLines: null)
  /// ```
  ///
  /// The input's height is large enough for the given number of lines. If
  /// additional lines are entered the input scrolls vertically.
  /// ```dart
  /// TextField(maxLines: 2)
  /// ```
  ///
  /// Input whose height grows with content between a min and max. An infinite
  /// max is possible with `maxLines: null`.
  /// ```dart
  /// TextField(minLines: 2, maxLines: 4)
  /// ```
  /// {@endtemplate}
  final int? maxLines;

  /// {@template flutter.widgets.editableText.minLines}
  /// The minimum number of lines to occupy when the content spans fewer lines.
  ///
  /// If this is null (default), text container starts with enough vertical space
  /// for one line and grows to accommodate additional lines as they are entered.
  ///
  /// This can be used in combination with [maxLines] for a varying set of behaviors.
  ///
  /// If the value is set, it must be greater than zero. If the value is greater
  /// than 1, [maxLines] should also be set to either null or greater than
  /// this value.
  ///
  /// When [maxLines] is set as well, the height will grow between the indicated
  /// range of lines. When [maxLines] is null, it will grow as high as needed,
  /// starting from [minLines].
  ///
  /// A few examples of behaviors possible with [minLines] and [maxLines] are as follows.
  /// These apply equally to `TextField`, `TextFormField`, `CupertinoTextField`,
  /// and `EditableText`.
  ///
  /// Input that always occupies at least 2 lines and has an infinite max.
  /// Expands vertically as needed.
  /// ```dart
  /// TextField(minLines: 2)
  /// ```
  ///
  /// Input whose height starts from 2 lines and grows up to 4 lines at which
  /// point the height limit is reached. If additional lines are entered it will
  /// scroll vertically.
  /// ```dart
  /// TextField(minLines:2, maxLines: 4)
  /// ```
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines]
  /// and [minLines] interact to produce various behaviors.
  ///
  /// Defaults to null.
  /// {@endtemplate}
  final int? minLines;

  /// {@template flutter.widgets.editableText.expands}
  /// Whether this widget's height will be sized to fill its parent.
  ///
  /// If set to true and wrapped in a parent widget like [Expanded] or
  /// [SizedBox], the input will expand to fill the parent.
  ///
  /// [maxLines] and [minLines] must both be null when this is set to true,
  /// otherwise an error is thrown.
  ///
  /// Defaults to false.
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines],
  /// [minLines], and [expands] interact to produce various behaviors.
  ///
  /// Input that matches the height of its parent:
  /// ```dart
  /// Expanded(
  ///   child: TextField(maxLines: null, expands: true),
  /// )
  /// ```
  /// {@endtemplate}
  final bool expands;

  /// {@template flutter.widgets.editableText.autofocus}
  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  /// {@endtemplate}
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// The color to use when painting the selection.
  ///
  /// For [CupertinoTextField]s, the value is set to the ambient
  /// [CupertinoThemeData.primaryColor] with 20% opacity. For [TextField]s, the
  /// value is set to the ambient.
  final Color? selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// The [ExtendedEditableText] widget used on its own will not trigger the display
  /// of the selection toolbar by itself. The toolbar is shown by calling
  /// [ExtendedEditableTextState.showToolbar] in response to an appropriate user event.
  ///
  /// See also:
  ///
  ///  * [CupertinoTextField], which wraps an [ExtendedEditableText] and which shows the
  ///    selection toolbar upon user events that are appropriate on the iOS
  ///    platform.
  ///  * [TextField], a Material Design themed wrapper of [ExtendedEditableText], which
  ///    shows the selection toolbar upon appropriate user events based on the
  ///    user's platform set in [ThemeData.platform].
  final TextSelectionControls? selectionControls;

  /// {@template flutter.widgets.editableText.keyboardType}
  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.text] if [maxLines] is one and
  /// [TextInputType.multiline] otherwise.
  /// {@endtemplate}
  final TextInputType keyboardType;

  /// The type of action button to use with the soft keyboard.
  final TextInputAction? textInputAction;

  /// {@template flutter.widgets.editableText.onChanged}
  /// Called when the user initiates a change to the TextField's
  /// value: when they have inserted or deleted text.
  ///
  /// This callback doesn't run when the TextField's text is changed
  /// programmatically, via the TextField's [controller]. Typically it
  /// isn't necessary to be notified of such changes, since they're
  /// initiated by the app itself.
  ///
  /// To be notified of all changes to the TextField's text, cursor,
  /// and selection, one can add a listener to its [controller] with
  /// [TextEditingController.addListener].
  ///
  /// {@tool dartpad --template=stateful_widget_material}
  ///
  /// This example shows how onChanged could be used to check the TextField's
  /// current value each time the user inserts or deletes a character.
  ///
  /// ```dart
  /// TextEditingController _controller;
  ///
  /// void initState() {
  ///   super.initState();
  ///   _controller = TextEditingController();
  /// }
  ///
  /// void dispose() {
  ///   _controller.dispose();
  ///   super.dispose();
  /// }
  ///
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     body: Column(
  ///       mainAxisAlignment: MainAxisAlignment.center,
  ///       children: <Widget>[
  ///         const Text('What number comes next in the sequence?'),
  ///         const Text('1, 1, 2, 3, 5, 8...?'),
  ///         TextField(
  ///           controller: _controller,
  ///           onChanged: (String value) async {
  ///             if (value != '13') {
  ///               return;
  ///             }
  ///             await showDialog<void>(
  ///               context: context,
  ///               builder: (BuildContext context) {
  ///                 return AlertDialog(
  ///                   title: const Text('Thats correct!'),
  ///                   content: Text ('13 is the right answer.'),
  ///                   actions: <Widget>[
  ///                     TextButton(
  ///                       onPressed: () { Navigator.pop(context); },
  ///                       child: const Text('OK'),
  ///                     ),
  ///                   ],
  ///                 );
  ///               },
  ///             );
  ///           },
  ///         ),
  ///       ],
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
  final ValueChanged<String>? onChanged;

  /// {@template flutter.widgets.editableText.onEditingComplete}
  /// Called when the user submits editable content (e.g., user presses the "done"
  /// button on the keyboard).
  ///
  /// The default implementation of [onEditingComplete] executes 2 different
  /// behaviors based on the situation:
  ///
  ///  - When a completion action is pressed, such as "done", "go", "send", or
  ///    "search", the user's content is submitted to the [controller] and then
  ///    focus is given up.
  ///
  ///  - When a non-completion action is pressed, such as "next" or "previous",
  ///    the user's content is submitted to the [controller], but focus is not
  ///    given up because developers may want to immediately move focus to
  ///    another input widget within [onSubmitted].
  ///
  /// Providing [onEditingComplete] prevents the aforementioned default behavior.
  /// {@endtemplate}
  final VoidCallback? onEditingComplete;

  /// {@template flutter.widgets.editableText.onSubmitted}
  /// Called when the user indicates that they are done editing the text in the
  /// field.
  /// {@endtemplate}
  ///
  /// {@tool dartpad --template=stateful_widget_material}
  /// When a non-completion action is pressed, such as "next" or "previous", it
  /// is often desirable to move the focus to the next or previous field.  To do
  /// this, handle it as in this example, by calling [FocusNode.nextFocus] in
  /// the `onFieldSubmitted` callback of [TextFormField]. ([TextFormField] wraps
  /// [EditableText] internally, and uses the value of `onFieldSubmitted` as its
  /// [onSubmitted]).
  ///
  /// ```dart
  /// FocusScopeNode _focusScopeNode = FocusScopeNode();
  /// final _controller1 = TextEditingController();
  /// final _controller2 = TextEditingController();
  ///
  /// void dispose() {
  ///   _focusScopeNode.dispose();
  ///   _controller1.dispose();
  ///   _controller2.dispose();
  ///   super.dispose();
  /// }
  ///
  /// void _handleSubmitted(String value) {
  ///   _focusScopeNode.nextFocus();
  /// }
  ///
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     body: FocusScope(
  ///       node: _focusScopeNode,
  ///       child: Column(
  ///         mainAxisAlignment: MainAxisAlignment.center,
  ///         children: <Widget>[
  ///           Padding(
  ///             padding: const EdgeInsets.all(8.0),
  ///             child: TextFormField(
  ///               textInputAction: TextInputAction.next,
  ///               onFieldSubmitted: _handleSubmitted,
  ///               controller: _controller1,
  ///               decoration: InputDecoration(border: OutlineInputBorder()),
  ///             ),
  ///           ),
  ///           Padding(
  ///             padding: const EdgeInsets.all(8.0),
  ///             child: TextFormField(
  ///               textInputAction: TextInputAction.next,
  ///               onFieldSubmitted: _handleSubmitted,
  ///               controller: _controller2,
  ///               decoration: InputDecoration(border: OutlineInputBorder()),
  ///             ),
  ///           ),
  ///         ],
  ///       ),
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final ValueChanged<String>? onSubmitted;

  /// {@template flutter.widgets.editableText.onAppPrivateCommand}
  /// Called when the result of an app private command is received.
  /// {@endtemplate}
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Called when the user changes the selection of text (including the cursor
  /// location).
  final SelectionChangedCallback? onSelectionChanged;

  /// {@macro flutter.widgets.textSelection.onSelectionHandleTapped}
  final VoidCallback? onSelectionHandleTapped;

  /// {@template flutter.widgets.editableText.inputFormatters}
  /// Optional input validation and formatting overrides.
  ///
  /// Formatters are run in the provided order when the text input changes.
  /// {@endtemplate}
  final List<TextInputFormatter>? inputFormatters;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If this property is null, [SystemMouseCursors.text] will be used.
  ///
  /// The [mouseCursor] is the only property of [EditableText] that controls the
  /// appearance of the mouse pointer. All other properties related to "cursor"
  /// stands for the text cursor, which is usually a blinking vertical line at
  /// the editing position.
  final MouseCursor? mouseCursor;

  /// If true, the [RenderEditable] created by this widget will not handle
  /// pointer events, see [RenderEditable] and [RenderEditable.ignorePointer].
  ///
  /// This property is false by default.
  final bool rendererIgnoresPointer;

  /// {@template flutter.widgets.editableText.cursorWidth}
  /// How thick the cursor will be.
  ///
  /// Defaults to 2.0
  ///
  /// The cursor will draw under the text. The cursor width will extend
  /// to the right of the boundary between characters for left-to-right text
  /// and to the left for right-to-left text. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  /// {@endtemplate}
  final double cursorWidth;

  /// {@template flutter.widgets.editableText.cursorHeight}
  /// How tall the cursor will be.
  ///
  /// If this property is null, [RenderEditable.preferredLineHeight] will be used.
  /// {@endtemplate}
  final double? cursorHeight;

  /// {@template flutter.widgets.editableText.cursorRadius}
  /// How rounded the corners of the cursor should be.
  ///
  /// By default, the cursor has no radius.
  /// {@endtemplate}
  final Radius? cursorRadius;

  /// Whether the cursor will animate from fully transparent to fully opaque
  /// during each cursor blink.
  ///
  /// By default, the cursor opacity will animate on iOS platforms and will not
  /// animate on Android platforms.
  final bool cursorOpacityAnimates;

  ///{@macro flutter.rendering.editable.cursorOffset}
  final Offset? cursorOffset;

  ///{@macro flutter.rendering.editable.paintCursorOnTop}
  final bool paintCursorAboveText;

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// {@template flutter.widgets.editableText.scrollPadding}
  /// Configures padding to edges surrounding a [Scrollable] when the Textfield scrolls into view.
  ///
  /// When this widget receives focus and is not completely visible (for example scrolled partially
  /// off the screen or overlapped by the keyboard)
  /// then it will attempt to make itself visible by scrolling a surrounding [Scrollable], if one is present.
  /// This value controls how far from the edges of a [Scrollable] the TextField will be positioned after the scroll.
  ///
  /// Defaults to EdgeInsets.all(20.0).
  /// {@endtemplate}
  final EdgeInsets scrollPadding;

  /// {@template flutter.widgets.editableText.enableInteractiveSelection}
  /// Whether to enable user interface affordances for changing the
  /// text selection.
  ///
  /// For example, setting this to true will enable features such as
  /// long-pressing the TextField to select text and show the
  /// cut/copy/paste menu, and tapping to move the text caret.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  /// {@endtemplate}
  final bool enableInteractiveSelection;

  /// Setting this property to true makes the cursor stop blinking or fading
  /// on and off once the cursor appears on focus. This property is useful for
  /// testing purposes.
  ///
  /// It does not affect the necessity to focus the EditableText for the cursor
  /// to appear in the first place.
  ///
  /// Defaults to false, resulting in a typical blinking cursor.
  static bool debugDeterministicCursor = false;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@template flutter.widgets.editableText.scrollController}
  /// The [ScrollController] to use when vertically scrolling the input.
  ///
  /// If null, it will instantiate a new ScrollController.
  ///
  /// See [Scrollable.controller].
  /// {@endtemplate}
  final ScrollController? scrollController;

  /// {@template flutter.widgets.editableText.scrollPhysics}
  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  /// {@endtemplate}
  final ScrollPhysics? scrollPhysics;

  /// {@template flutter.widgets.editableText.selectionEnabled}
  /// Same as [enableInteractiveSelection].
  ///
  /// This getter exists primarily for consistency with
  /// [RenderEditable.selectionEnabled].
  /// {@endtemplate}
  bool get selectionEnabled => enableInteractiveSelection;

  /// {@template flutter.widgets.editableText.autofillHints}
  /// A list of strings that helps the autofill service identify the type of this
  /// text input.
  ///
  /// When set to null or empty, the text input will not send any autofill related
  /// information to the platform. As a result, it will not participate in
  /// autofills triggered by a different [AutofillClient], even if they're in the
  /// same [AutofillScope]. Additionally, on Android and web, setting this to null
  /// or empty will disable autofill for this text field.
  ///
  /// The minimum platform SDK version that supports Autofill is API level 26
  /// for Android, and iOS 10.0 for iOS.
  ///
  /// ### iOS-specific Concerns:
  ///
  /// To provide the best user experience and ensure your app fully supports
  /// password autofill on iOS, follow these steps:
  ///
  /// * Set up your iOS app's
  ///   [associated domains](https://developer.apple.com/documentation/safariservices/supporting_associated_domains_in_your_app).
  /// * Some autofill hints only work with specific [keyboardType]s. For example,
  ///   [AutofillHints.name] requires [TextInputType.name] and [AutofillHints.email]
  ///   works only with [TextInputType.emailAddress]. Make sure the input field has a
  ///   compatible [keyboardType]. Empirically, [TextInputType.name] works well
  ///   with many autofill hints that are predefined on iOS.
  /// {@endtemplate}
  /// {@macro flutter.services.autofill.autofillHints}
  final Iterable<String>? autofillHints;

  /// {@macro flutter.widgets.Clip}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Restoration ID to save and restore the scroll offset of the
  /// [EditableText].
  ///
  /// If a restoration id is provided, the [EditableText] will persist its
  /// current scroll offset and restore it during state restoration.
  ///
  /// The scroll offset is persisted in a [RestorationBucket] claimed from
  /// the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// Persisting and restoring the content of the [EditableText] is the
  /// responsibilility of the owner of the [controller], who may use a
  /// [RestorableTextEditingController] for that purpose.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;
  // Infer the keyboard type of an `EditableText` if it's not specified.
  static TextInputType _inferKeyboardType({
    required Iterable<String>? autofillHints,
    required int? maxLines,
  }) {
    if (autofillHints?.isEmpty ?? true) {
      return maxLines == 1 ? TextInputType.text : TextInputType.multiline;
    }

    TextInputType? returnValue;
    final String effectiveHint = autofillHints!.first;

    // On iOS oftentimes specifying a text content type is not enough to qualify
    // the input field for autofill. The keyboard type also needs to be compatible
    // with the content type. To get autofill to work by default on EditableText,
    // the keyboard type inference on iOS is done differently from other platforms.
    //
    // The entries with "autofill not working" comments are the iOS text content
    // types that should work with the specified keyboard type but won't trigger
    // (even within a native app). Tested on iOS 13.5.
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          const Map<String, TextInputType> iOSKeyboardType =
              <String, TextInputType>{
            AutofillHints.addressCity: TextInputType.name,
            AutofillHints.addressCityAndState:
                TextInputType.name, // Autofill not working.
            AutofillHints.addressState: TextInputType.name,
            AutofillHints.countryName: TextInputType.name,
            AutofillHints.creditCardNumber:
                TextInputType.number, // Couldn't test.
            AutofillHints.email: TextInputType.emailAddress,
            AutofillHints.familyName: TextInputType.name,
            AutofillHints.fullStreetAddress: TextInputType.name,
            AutofillHints.givenName: TextInputType.name,
            AutofillHints.jobTitle: TextInputType.name, // Autofill not working.
            AutofillHints.location: TextInputType.name, // Autofill not working.
            AutofillHints.middleName:
                TextInputType.name, // Autofill not working.
            AutofillHints.name: TextInputType.name,
            AutofillHints.namePrefix:
                TextInputType.name, // Autofill not working.
            AutofillHints.nameSuffix:
                TextInputType.name, // Autofill not working.
            AutofillHints.newPassword: TextInputType.text,
            AutofillHints.newUsername: TextInputType.text,
            AutofillHints.nickname: TextInputType.name, // Autofill not working.
            AutofillHints.oneTimeCode: TextInputType.number,
            AutofillHints.organizationName:
                TextInputType.text, // Autofill not working.
            AutofillHints.password: TextInputType.text,
            AutofillHints.postalCode: TextInputType.name,
            AutofillHints.streetAddressLine1: TextInputType.name,
            AutofillHints.streetAddressLine2:
                TextInputType.name, // Autofill not working.
            AutofillHints.sublocality:
                TextInputType.name, // Autofill not working.
            AutofillHints.telephoneNumber: TextInputType.name,
            AutofillHints.url: TextInputType.url, // Autofill not working.
            AutofillHints.username: TextInputType.text,
          };

          returnValue = iOSKeyboardType[effectiveHint];
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    }

    if (returnValue != null || maxLines != 1)
      return returnValue ?? TextInputType.multiline;

    const Map<String, TextInputType> inferKeyboardType =
        <String, TextInputType>{
      AutofillHints.addressCity: TextInputType.streetAddress,
      AutofillHints.addressCityAndState: TextInputType.streetAddress,
      AutofillHints.addressState: TextInputType.streetAddress,
      AutofillHints.birthday: TextInputType.datetime,
      AutofillHints.birthdayDay: TextInputType.datetime,
      AutofillHints.birthdayMonth: TextInputType.datetime,
      AutofillHints.birthdayYear: TextInputType.datetime,
      AutofillHints.countryCode: TextInputType.number,
      AutofillHints.countryName: TextInputType.text,
      AutofillHints.creditCardExpirationDate: TextInputType.datetime,
      AutofillHints.creditCardExpirationDay: TextInputType.datetime,
      AutofillHints.creditCardExpirationMonth: TextInputType.datetime,
      AutofillHints.creditCardExpirationYear: TextInputType.datetime,
      AutofillHints.creditCardFamilyName: TextInputType.name,
      AutofillHints.creditCardGivenName: TextInputType.name,
      AutofillHints.creditCardMiddleName: TextInputType.name,
      AutofillHints.creditCardName: TextInputType.name,
      AutofillHints.creditCardNumber: TextInputType.number,
      AutofillHints.creditCardSecurityCode: TextInputType.number,
      AutofillHints.creditCardType: TextInputType.text,
      AutofillHints.email: TextInputType.emailAddress,
      AutofillHints.familyName: TextInputType.name,
      AutofillHints.fullStreetAddress: TextInputType.streetAddress,
      AutofillHints.gender: TextInputType.text,
      AutofillHints.givenName: TextInputType.name,
      AutofillHints.impp: TextInputType.url,
      AutofillHints.jobTitle: TextInputType.text,
      AutofillHints.language: TextInputType.text,
      AutofillHints.location: TextInputType.streetAddress,
      AutofillHints.middleInitial: TextInputType.name,
      AutofillHints.middleName: TextInputType.name,
      AutofillHints.name: TextInputType.name,
      AutofillHints.namePrefix: TextInputType.name,
      AutofillHints.nameSuffix: TextInputType.name,
      AutofillHints.newPassword: TextInputType.text,
      AutofillHints.newUsername: TextInputType.text,
      AutofillHints.nickname: TextInputType.text,
      AutofillHints.oneTimeCode: TextInputType.text,
      AutofillHints.organizationName: TextInputType.text,
      AutofillHints.password: TextInputType.text,
      AutofillHints.photo: TextInputType.text,
      AutofillHints.postalAddress: TextInputType.streetAddress,
      AutofillHints.postalAddressExtended: TextInputType.streetAddress,
      AutofillHints.postalAddressExtendedPostalCode: TextInputType.number,
      AutofillHints.postalCode: TextInputType.number,
      AutofillHints.streetAddressLevel1: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel2: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel3: TextInputType.streetAddress,
      AutofillHints.streetAddressLevel4: TextInputType.streetAddress,
      AutofillHints.streetAddressLine1: TextInputType.streetAddress,
      AutofillHints.streetAddressLine2: TextInputType.streetAddress,
      AutofillHints.streetAddressLine3: TextInputType.streetAddress,
      AutofillHints.sublocality: TextInputType.streetAddress,
      AutofillHints.telephoneNumber: TextInputType.phone,
      AutofillHints.telephoneNumberAreaCode: TextInputType.phone,
      AutofillHints.telephoneNumberCountryCode: TextInputType.phone,
      AutofillHints.telephoneNumberDevice: TextInputType.phone,
      AutofillHints.telephoneNumberExtension: TextInputType.phone,
      AutofillHints.telephoneNumberLocal: TextInputType.phone,
      AutofillHints.telephoneNumberLocalPrefix: TextInputType.phone,
      AutofillHints.telephoneNumberLocalSuffix: TextInputType.phone,
      AutofillHints.telephoneNumberNational: TextInputType.phone,
      AutofillHints.transactionAmount:
          TextInputType.numberWithOptions(decimal: true),
      AutofillHints.transactionCurrency: TextInputType.text,
      AutofillHints.url: TextInputType.url,
      AutofillHints.username: TextInputType.text,
    };

    return inferKeyboardType[effectiveHint] ?? TextInputType.text;
  }

  @override
  ExtendedEditableTextState createState() => ExtendedEditableTextState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<TextEditingController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText,
        defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: true));
    properties.add(EnumProperty<SmartDashesType>(
        'smartDashesType', smartDashesType,
        defaultValue:
            obscureText ? SmartDashesType.disabled : SmartDashesType.enabled));
    properties.add(EnumProperty<SmartQuotesType>(
        'smartQuotesType', smartQuotesType,
        defaultValue:
            obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled));
    properties.add(DiagnosticsProperty<bool>(
        'enableSuggestions', enableSuggestions,
        defaultValue: true));
    style.debugFillProperties(properties);
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollController>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Iterable<String>>(
        'autofillHints', autofillHints,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextHeightBehavior>(
        'textHeightBehavior', textHeightBehavior,
        defaultValue: null));
  }
}

/// State for a [ExtendedEditableText].
class ExtendedEditableTextState extends State<ExtendedEditableText>
    with
        AutomaticKeepAliveClientMixin<ExtendedEditableText>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<ExtendedEditableText>,
        TextSelectionDelegate
    implements TextInputClient, AutofillClient {
  Timer? _cursorTimer;
  bool _targetCursorVisibility = false;
  final ValueNotifier<bool> _cursorVisibilityNotifier =
      ValueNotifier<bool>(true);
  final GlobalKey _editableKey = GlobalKey();
  final ClipboardStatusNotifier? _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  TextInputConnection? _textInputConnection;
  ExtendedTextSelectionOverlay? _selectionOverlay;
  late ScrollController _scrollController;
  late AnimationController _cursorBlinkOpacityController;

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  bool _didAutoFocus = false;
  FocusAttachment? _focusAttachment;

  AutofillGroupState? _currentAutofillScope;
  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  ///whether to support build SpecialText
  bool get supportSpecialText =>
      widget.specialTextSpanBuilder != null &&
      !widget.obscureText &&
      _textDirection == TextDirection.ltr;

  // Is this field in the current autofill context.
  bool _isInAutofillContext = false;

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get _shouldCreateInputConnection => kIsWeb || !widget.readOnly;

  // This value is an eyeball estimation of the time it takes for the iOS cursor
  // to ease in and out.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  late AnimationController _floatingCursorResetController;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  Color get _cursorColor =>
      widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }
  // State lifecycle:

  @override
  void initState() {
    super.initState();
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
    widget.controller.addListener(_didChangeTextEditingValue);
    _focusAttachment = widget.focusNode.attach(context);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_updateForScroll);
    _cursorBlinkOpacityController =
        AnimationController(vsync: this, duration: _fadeDuration);
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(_onFloatingCursorResetTick);
    _cursorVisibilityNotifier.value = widget.showCursor;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AutofillGroupState? newAutofillGroup = AutofillGroup.of(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      newAutofillGroup?.register(this);
      _isInAutofillContext = _isInAutofillContext || _shouldBeInAutofillContext;
    }
    if (!_didAutoFocus && widget.autofocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).autofocus(widget.focusNode);
        }
      });
    }
  }

  @override
  void didUpdateWidget(ExtendedEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(_value);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;
    _isInAutofillContext = _isInAutofillContext || _shouldBeInAutofillContext;
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }
    if (!_shouldCreateInputConnection) {
      _closeInputConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        _openInputConnection();
      }
    }
    if (kIsWeb && _hasInputConnection) {
      if (oldWidget.readOnly != widget.readOnly) {
        _textInputConnection!.updateConfig(textInputConfiguration);
      }
    }
    if (widget.style != oldWidget.style) {
      final TextStyle style = widget.style;
      // The _textInputConnection will pick up the new style when it attaches in
      // _openInputConnection.
      if (_hasInputConnection) {
        _textInputConnection!.setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        );
      }
    }
    if (widget.selectionEnabled &&
        pasteEnabled &&
        widget.selectionControls?.canPaste(this) == true) {
      _clipboardStatus?.update();
    }

    if (widget.scrollController != null &&
        widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_updateForScroll);
      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_updateForScroll);
    }
  }

  @override
  void dispose() {
    _currentAutofillScope?.unregister(autofillId);
    widget.controller.removeListener(_didChangeTextEditingValue);
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    _floatingCursorResetController.removeListener(_onFloatingCursorResetTick);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _stopCursorTimer();
    assert(_cursorTimer == null);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    _focusAttachment!.detach();
    widget.focusNode.removeListener(_handleFocusChanged);
    WidgetsBinding.instance!.removeObserver(this);
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    _scrollController.removeListener(_updateForScroll);
    _scrollController.dispose();
    super.dispose();
    assert(_batchEditDepth <= 0, 'unfinished batch edits: $_batchEditDepth');
  }

  // TextInputClient implementation:

  /// The last known [TextEditingValue] of the platform text input plugin.
  ///
  /// This value is updated when the platform text input plugin sends a new
  /// update via [updateEditingValue], or when [EditableText] calls
  /// [TextInputConnection.setEditingState] to overwrite the platform text input
  /// plugin's [TextEditingValue].
  ///
  /// Used in [_updateRemoteEditingValueIfNeeded] to determine whether the
  /// remote value is outdated and needs updating.
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    // Since we still have to support keyboard select, this is the best place
    // to disable text updating.
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (widget.readOnly) {
      // In the read-only case, we only care about selection changes, and reject
      // everything else.
      value = _value.copyWith(selection: value.selection);
    }
    _lastKnownRemoteTextEditingValue = value;
    value = _handleSpecialTextSpan(value);
    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    if (value.text == _value.text && value.composing == _value.composing) {
      // `selection` is the only change.
      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);
    } else {
      hideToolbar();
      _currentPromptRectRange = null;

      if (_hasInputConnection) {
        _showCaretOnScreen();
        if (widget.obscureText && value.text.length == _value.text.length + 1) {
          _obscureShowCharTicksPending = _kObscureShowLatestCharCursorTicks;
          _obscureLatestCharIndex = _value.selection.baseOffset;
        }
      }

      _formatAndSetValue(value);
    }
    if (_hasInputConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  ///zmt
  TextEditingValue _handleSpecialTextSpan(TextEditingValue value) {
    if (supportSpecialText) {
      final bool textChanged = _value.text != value.text;
      final bool selectionChanged = _value.selection != value.selection;
      if (textChanged) {
        final TextSpan newTextSpan = widget.specialTextSpanBuilder!
            .build(value.text, textStyle: widget.style);

        final TextSpan oldTextSpan = widget.specialTextSpanBuilder!
            .build(_value.text, textStyle: widget.style);
        value = handleSpecialTextSpanDelete(
            value, _value, oldTextSpan, _textInputConnection!);

        final String text = newTextSpan.toPlainText();
        //correct caret Offset
        //make sure caret is not in text when caretIn is false
        if (text != value.text || selectionChanged) {
          value = correctCaretOffset(value, newTextSpan, _textInputConnection!);
        }
      }
    }

    return value;
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (!_isMultiline) {
          _finalizeEditing(action, shouldUnfocus: true);
        }
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.search:
      case TextInputAction.send:
        _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.continueAction:
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
        // Finalize editing, but don't give up focus because this keyboard
        // action does not imply the user is done inputting information.
        _finalizeEditing(action, shouldUnfocus: false);
        break;
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    widget.onAppPrivateCommand!(action, data);
  }

  // The original position of the caret on FloatingCursorDragState.start.
  Rect? _startCaretRect;

  // The most recent text position as determined by the location of the floating
  // cursor.
  TextPosition? _lastTextPosition;

  // The offset of the floating cursor as determined from the start call.
  Offset? _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset? _lastBoundedOffset;

  // Because the center of the cursor is preferredLineHeight / 2 below the touch
  // origin, but the touch origin is used to determine which line the cursor is
  // on, we need this offset to correctly render and move the cursor.
  Offset get _floatingCursorOffset =>
      Offset(0, renderEditable.preferredLineHeight / 2);

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (_floatingCursorResetController.isAnimating) {
          _floatingCursorResetController.stop();
          _onFloatingCursorResetTick();
        }

        // We want to send in points that are centered around a (0,0) origin, so
        // we cache the position.
        _pointOffsetOrigin = point.offset;

        TextPosition currentTextPosition =
            TextPosition(offset: renderEditable.selection!.baseOffset);
        //zmt
        if (supportSpecialText) {
          currentTextPosition = convertTextInputPostionToTextPainterPostion(
              renderEditable.text!, renderEditable.selection!.base);
        } else {
          currentTextPosition =
              TextPosition(offset: renderEditable.selection!.baseOffset);
        }
        _startCaretRect =
            renderEditable.getLocalRectForCaret(currentTextPosition);

        _lastBoundedOffset = _startCaretRect!.center - _floatingCursorOffset;
        _lastTextPosition = currentTextPosition;
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.Update:
        final Offset centeredPoint = point.offset! - _pointOffsetOrigin!;
        final Offset rawCursorOffset =
            _startCaretRect!.center + centeredPoint - _floatingCursorOffset;

        _lastBoundedOffset = renderEditable
            .calculateBoundedFloatingCursorOffset(rawCursorOffset);
        _lastTextPosition = renderEditable.getPositionForPoint(renderEditable
            .localToGlobal(_lastBoundedOffset! + _floatingCursorOffset));
        if (renderEditable.hasSpecialInlineSpanBase) {
          _lastTextPosition = makeSureCaretNotInSpecialText(
              renderEditable.text!, _lastTextPosition!);
        }
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          _floatingCursorResetController.value = 0.0;
          _floatingCursorResetController.animateTo(1.0,
              duration: _floatingCursorResetTime, curve: Curves.decelerate);
        }
        break;
    }
  }

  void _onFloatingCursorResetTick() {
    final Offset finalPosition =
        renderEditable.getLocalRectForCaret(_lastTextPosition!).centerLeft -
            _floatingCursorOffset;
    if (_floatingCursorResetController.isCompleted) {
      renderEditable.setFloatingCursor(
          FloatingCursorDragState.End, finalPosition, _lastTextPosition!);
      if (_lastTextPosition!.offset != renderEditable.selection!.baseOffset)
        // The cause is technically the force cursor, but the cause is listed as tap as the desired functionality is the same.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _lastTextPosition!.offset),
            SelectionChangedCause.forcePress);
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final double lerpValue = _floatingCursorResetController.value;
      final double lerpX =
          ui.lerpDouble(_lastBoundedOffset!.dx, finalPosition.dx, lerpValue)!;
      final double lerpY =
          ui.lerpDouble(_lastBoundedOffset!.dy, finalPosition.dy, lerpValue)!;

      renderEditable.setFloatingCursor(FloatingCursorDragState.Update,
          Offset(lerpX, lerpY), _lastTextPosition!,
          resetLerpValue: lerpValue);
    }
  }

  void _finalizeEditing(TextInputAction action, {required bool shouldUnfocus}) {
    // Take any actions necessary now that the user has completed editing.
    if (widget.onEditingComplete != null) {
      try {
        widget.onEditingComplete!();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context:
              ErrorDescription('while calling onEditingComplete for $action'),
        ));
      }
    } else {
      // Default behavior if the developer did not provide an
      // onEditingComplete callback: Finalize editing and remove focus, or move
      // it to the next/previous field, depending on the action.
      widget.controller.clearComposing();
      if (shouldUnfocus) {
        switch (action) {
          case TextInputAction.none:
          case TextInputAction.unspecified:
          case TextInputAction.done:
          case TextInputAction.go:
          case TextInputAction.search:
          case TextInputAction.send:
          case TextInputAction.continueAction:
          case TextInputAction.join:
          case TextInputAction.route:
          case TextInputAction.emergencyCall:
          case TextInputAction.newline:
            widget.focusNode.unfocus();
            break;
          case TextInputAction.next:
            widget.focusNode.nextFocus();
            break;
          case TextInputAction.previous:
            widget.focusNode.previousFocus();
            break;
        }
      }
    }

    // Invoke optional callback with the user's submitted content.
    try {
      widget.onSubmitted?.call(_value.text);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context: ErrorDescription('while calling onSubmitted for $action'),
      ));
    }
  }

  int _batchEditDepth = 0;

  /// Begins a new batch edit, within which new updates made to the text editing
  /// value will not be sent to the platform text input plugin.
  ///
  /// Batch edits nest. When the outermost batch edit finishes, [endBatchEdit]
  /// will attempt to send [currentTextEditingValue] to the text input plugin if
  /// it detected a change.
  void beginBatchEdit() {
    _batchEditDepth += 1;
  }

  /// Ends the current batch edit started by the last call to [beginBatchEdit],
  /// and send [currentTextEditingValue] to the text input plugin if needed.
  ///
  /// Throws an error in debug mode if this [EditableText] is not in a batch
  /// edit.
  void endBatchEdit() {
    _batchEditDepth -= 1;
    assert(
      _batchEditDepth >= 0,
      'Unbalanced call to endBatchEdit: beginBatchEdit must be called first.',
    );
    _updateRemoteEditingValueIfNeeded();
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) {
      return;
    }
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) {
      return;
    }
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;

  // Finds the closest scroll offset to the current scroll offset that fully
  // reveals the given caret rect. If the given rect's main axis extent is too
  // large to be fully revealed in `renderEditable`, it will be centered along
  // the main axis.
  //
  // If this is a multiline EditableText (which means the Editable can only
  // scroll vertically), the given rect's height will first be extended to match
  // `renderEditable.preferredLineHeight`, before the target scroll offset is
  // calculated.
  RevealedOffset _getOffsetToRevealCaret(Rect? rect) {
    if (!_scrollController.position.allowImplicitScrolling)
      return RevealedOffset(offset: _scrollController.offset, rect: rect!);

    final Size editableSize = renderEditable.size;
    double additionalOffset;
    Offset unitOffset;

    if (!_isMultiline) {
      additionalOffset = rect!.width >= editableSize.width
          // Center `rect` if it's oversized.
          ? editableSize.width / 2 - rect.center.dx
          // Valid additional offsets range from (rect.right - size.width)
          // to (rect.left). Pick the closest one if out of range.
          : 0.0.clamp(rect.right - editableSize.width, rect.left);
      unitOffset = const Offset(1, 0);
    } else {
      // The caret is vertically centered within the line. Expand the caret's
      // height so that it spans the line because we're going to ensure that the
      // entire expanded caret is scrolled into view.
      final Rect expandedRect = Rect.fromCenter(
        center: rect!.center,
        width: rect.width,
        height: max(rect.height, renderEditable.preferredLineHeight),
      );

      additionalOffset = expandedRect.height >= editableSize.height
          ? editableSize.height / 2 - expandedRect.center.dy
          : 0.0.clamp(
              expandedRect.bottom - editableSize.height, expandedRect.top);
      unitOffset = const Offset(0, 1);
    }

    // No overscrolling when encountering tall fonts/scripts that extend past
    // the ascent.
    final double targetOffset =
        (additionalOffset + _scrollController.offset).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    final double offsetDelta = _scrollController.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  bool get _hasInputConnection =>
      _textInputConnection != null && _textInputConnection!.attached;
  bool get _needsAutofill => widget.autofillHints?.isNotEmpty ?? false;
  bool get _shouldBeInAutofillContext =>
      _needsAutofill && currentAutofillScope != null;

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      // When _needsAutofill == true && currentAutofillScope == null, autofill
      // is allowed but saving the user input from the text field is
      // discouraged.
      //
      // In case the autofillScope changes from a non-null value to null, or
      // _needsAutofill changes to false from true, the platform needs to be
      // notified to exclude this field from the autofill context. So we need to
      // provide the autofillId.
      _textInputConnection = _needsAutofill && currentAutofillScope != null
          ? currentAutofillScope!.attach(this, textInputConfiguration)
          : TextInput.attach(
              this,
              _createTextInputConfiguration(
                  _isInAutofillContext || _needsAutofill));
      _textInputConnection!.show();
      _updateSizeAndTransform();
      _updateComposingRectIfNeeded();
      if (_needsAutofill) {
        // Request autofill AFTER the size and the transform have been sent to
        // the platform text input plugin.
        _textInputConnection!.requestAutofill();
      }
      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        )
        ..setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _finalizeEditing(TextInputAction.done, shouldUnfocus: true);
    }
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [EditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    if (!widget.controller.isSelectionWithinTextBounds(selection)) {
      return;
    }

    if (renderEditable.hasSpecialInlineSpanBase) {
      final TextEditingValue value = correctCaretOffset(
          _value, renderEditable.text!, _textInputConnection,
          newSelection: selection);

      ///change
      if (value != _value) {
        selection = value.selection;
        _value = value;
      }
    }

    final bool textChanged = widget.controller.text != renderEditable.plainText;
    // zmt
    // if textChanged, text was changed by user,
    // _didChangeTextEditingValue setstate to change text of ExtendedRenderEditable
    // but still slower than this method.
    if (!textChanged) {
      widget.controller.selection = selection;
    }

    // This will show the keyboard for all selection changes on the
    // EditableWidget, not just changes triggered by user gestures.
    requestKeyboard();

    _hideSelectionOverlayIfNeeded();

    if (widget.selectionControls != null) {
      createSelectionOverlay(renderObject: renderEditable);

//      final bool longPress = cause == SelectionChangedCause.longPress;
//      if (cause != SelectionChangedCause.keyboard &&
//          (_value.text.isNotEmpty || longPress))
//        _selectionOverlay.showHandles();

    }

    if (!textChanged && widget.onSelectionChanged != null)
      widget.onSelectionChanged!(selection, cause);
  }

  void createSelectionOverlay({
    ExtendedRenderEditable? renderObject,
    bool showHandles = true,
  }) {
    _selectionOverlay = ExtendedTextSelectionOverlay(
      clipboardStatus: _clipboardStatus,
      context: context,
      value: _value,
      debugRequiredFor: widget,
      toolbarLayerLink: _toolbarLayerLink,
      startHandleLayerLink: _startHandleLayerLink,
      endHandleLayerLink: _endHandleLayerLink,
      renderObject: renderObject ?? renderEditable,
      selectionControls: widget.selectionControls,
      selectionDelegate: this,
      dragStartBehavior: widget.dragStartBehavior,
      onSelectionHandleTapped: widget.onSelectionHandleTapped,
    );
    _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
    _selectionOverlay!.showHandles();

    // To keep the cursor from blinking while it moves, restart the timer here.
    if (_cursorTimer != null) {
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  bool _textChangedSinceLastCaretUpdate = false;
  Rect? _currentCaretRect;

  void _handleCaretChanged(Rect caretRect) {
    _currentCaretRect = caretRect;
    // If the caret location has changed due to an update to the text or
    // selection, then scroll the caret into view.
    if (_textChangedSinceLastCaretUpdate) {
      _textChangedSinceLastCaretUpdate = false;
      _showCaretOnScreen();
    }
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _showCaretOnScreen() {
    if (_showCaretOnScreenScheduled) {
      return;
    }
    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _showCaretOnScreenScheduled = false;
      if (_currentCaretRect == null || !_scrollController.hasClients) {
        return;
      }

      final double lineHeight = renderEditable.preferredLineHeight;

      // Enlarge the target rect by scrollPadding to ensure that caret is not
      // positioned directly at the edge after scrolling.
      double bottomSpacing = widget.scrollPadding.bottom;
      if (_selectionOverlay?.selectionControls != null) {
        final double handleHeight = _selectionOverlay!.selectionControls!
            .getHandleSize(lineHeight)
            .height;
        final double interactiveHandleHeight = max(
          handleHeight,
          kMinInteractiveDimension,
        );
        final Offset anchor =
            _selectionOverlay!.selectionControls!.getHandleAnchor(
          TextSelectionHandleType.collapsed,
          lineHeight,
        );
        final double handleCenter = handleHeight / 2 - anchor.dy;
        bottomSpacing = max(
          handleCenter + interactiveHandleHeight / 2,
          bottomSpacing,
        );
      }

      final EdgeInsets caretPadding =
          widget.scrollPadding.copyWith(bottom: bottomSpacing);

      final RevealedOffset targetOffset =
          _getOffsetToRevealCaret(_currentCaretRect);

      _scrollController.animateTo(
        targetOffset.offset,
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );

      renderEditable.showOnScreen(
        rect: caretPadding.inflateRect(targetOffset.rect),
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );
    });
  }

  late double _lastBottomViewInset;

  @override
  void didChangeMetrics() {
    if (_lastBottomViewInset <
        WidgetsBinding.instance!.window.viewInsets.bottom) {
      _showCaretOnScreen();
    }
    _lastBottomViewInset = WidgetsBinding.instance!.window.viewInsets.bottom;
  }

  late final _WhitespaceDirectionalityFormatter _whitespaceFormatter =
      _WhitespaceDirectionalityFormatter(textDirection: _textDirection);

  void _formatAndSetValue(TextEditingValue value) {
    // Only apply input formatters if the text has changed (including uncommited
    // text in the composing region), or when the user committed the composing
    // text.
    // Gboard is very persistent in restoring the composing region. Applying
    // input formatters on composing-region-only changes (except clearing the
    // current composing region) is very infinite-loop-prone: the formatters
    // will keep trying to modify the composing region while Gboard will keep
    // trying to restore the original composing region.
    final bool textChanged = _value.text != value.text ||
        (!_value.composing.isCollapsed && value.composing.isCollapsed);
    final bool selectionChanged = _value.selection != value.selection;

    if (textChanged) {
      value = widget.inputFormatters?.fold<TextEditingValue>(
            value,
            (TextEditingValue newValue, TextInputFormatter formatter) =>
                formatter.formatEditUpdate(_value, newValue),
          ) ??
          value;

      // Always pass the text through the whitespace directionality formatter to
      // maintain expected behavior with carets on trailing whitespace.
      // TODO(LongCatIsLooong): The if statement here is for retaining the
      // previous behavior. The input formatter logic will be updated in an
      // upcoming PR.
      if (widget.inputFormatters?.isNotEmpty ?? false)
        value = _whitespaceFormatter.formatEditUpdate(_value, value);
    }

    // Put all optional user callback invocations in a batch edit to prevent
    // sending multiple `TextInput.updateEditingValue` messages.
    beginBatchEdit();
    _value = value;
    if (textChanged) {
      try {
        widget.onChanged?.call(value.text);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while calling onChanged'),
        ));
      }
    }

    if (selectionChanged) {
      try {
        widget.onSelectionChanged?.call(value.selection, null);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while calling onSelectionChanged'),
        ));
      }
    }

    endBatchEdit();
  }

  void _onCursorColorTick() {
    renderEditable.cursorColor =
        widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);
    _cursorVisibilityNotifier.value =
        widget.showCursor && _cursorBlinkOpacityController.value > 0;
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  @visibleForTesting
  bool get cursorCurrentlyVisible => _cursorBlinkOpacityController.value > 0;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  @visibleForTesting
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  /// The current status of the text selection handles.
  //@visibleForTesting
  ExtendedTextSelectionOverlay? get selectionOverlay => _selectionOverlay;

  int _obscureShowCharTicksPending = 0;
  int? _obscureLatestCharIndex;

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final double targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (widget.cursorOpacityAnimates) {
      // If we want to show the cursor, we will animate the opacity to the value
      // of 1.0, and likewise if we want to make it disappear, to 0.0. An easing
      // curve is used for the animation to mimic the aesthetics of the native
      // iOS cursor.
      //
      // These values and curves have been obtained through eyeballing, so are
      // likely not exactly the same as the values for native iOS.
      _cursorBlinkOpacityController.animateTo(targetOpacity,
          curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController.value = targetOpacity;
    }

    if (_obscureShowCharTicksPending > 0) {
      setState(() {
        _obscureShowCharTicksPending--;
      });
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void _startCursorTimer() {
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController.value = 1.0;
    if (ExtendedEditableText.debugDeterministicCursor) {
      return;
    }
    if (widget.cursorOpacityAnimates) {
      _cursorTimer =
          Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void _stopCursorTimer({bool resetCharTicks = true}) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController.value = 0.0;
    if (ExtendedEditableText.debugDeterministicCursor) {
      return;
    }
    if (resetCharTicks) {
      _obscureShowCharTicksPending = 0;
    }
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController.stop();
      _cursorBlinkOpacityController.value = 0.0;
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (_cursorTimer == null && _hasFocus && _value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorTimer != null &&
        (!_hasFocus || !_value.selection.isCollapsed)) {
      _stopCursorTimer();
    }
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    _textChangedSinceLastCaretUpdate = true;
    // TODO(abarth): Teach RenderEditable about ValueNotifier<TextEditingValue>
    // to avoid this setState().
    setState(() {/* We use widget.controller.value in build(). */});
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance!.addObserver(this);
      _lastBottomViewInset = WidgetsBinding.instance!.window.viewInsets.bottom;
      _showCaretOnScreen();
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _value.text.length), null);
      }
    } else {
      WidgetsBinding.instance!.removeObserver(this);
      // Clear the selection and composition state if this widget lost focus.
      _value = TextEditingValue(text: _value.text);
      _currentPromptRectRange = null;
    }
    updateKeepAlive();
  }

  void _updateSizeAndTransform() {
    if (_hasInputConnection) {
      final Size size = renderEditable.size;
      final Matrix4 transform = renderEditable.getTransformTo(null);
      _textInputConnection!.setEditableSizeAndTransform(size, transform);
      SchedulerBinding.instance!
          .addPostFrameCallback((Duration _) => _updateSizeAndTransform());
    }
  }

  // Sends the current composing rect to the iOS text input plugin via the text
  // input channel. We need to keep sending the information even if no text is
  // currently marked, as the information usually lags behind. The text input
  // plugin needs to estimate the composing rect based on the latest caret rect,
  // when the composing rect info didn't arrive in time.
  void _updateComposingRectIfNeeded() {
    final TextRange composingRange = _value.composing;
    if (_hasInputConnection) {
      assert(mounted);
      Rect? composingRect =
          renderEditable.getRectForComposingRange(composingRange);
      // Send the caret location instead if there's no marked text yet.
      if (composingRect == null) {
        assert(!composingRange.isValid || composingRange.isCollapsed);
        final int offset = composingRange.isValid ? composingRange.start : 0;
        composingRect =
            renderEditable.getLocalRectForCaret(TextPosition(offset: offset));
      }
      _textInputConnection!.setComposingRect(composingRect);
      SchedulerBinding.instance!
          .addPostFrameCallback((Duration _) => _updateComposingRectIfNeeded());
    }
  }

  TextDirection get _textDirection {
    final TextDirection result =
        widget.textDirection ?? Directionality.of(context);
    return result;
  }

  /// The renderer for this widget's [Editable] descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures
  /// when [ignorePointer] is true. See [RenderEditable.ignorePointer].
  ExtendedRenderEditable get renderEditable =>
      _editableKey.currentContext!.findRenderObject() as ExtendedRenderEditable;

  @override
  TextEditingValue get textEditingValue => _value;

  double get _devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  @override
  set textEditingValue(TextEditingValue value) {
    value = _handleSpecialTextSpan(value);
    _selectionOverlay?.update(value);
    _formatAndSetValue(value);
  }

  @override
  void bringIntoView(TextPosition position) {
    if (supportSpecialText) {
      position = convertTextInputPostionToTextPainterPostion(
          renderEditable.text!, position);
    }

    final Rect localRect = renderEditable.getLocalRectForCaret(position);

    final RevealedOffset targetOffset = _getOffsetToRevealCaret(localRect);
    _scrollController.jumpTo(targetOffset.offset);
    renderEditable.showOnScreen(rect: targetOffset.rect);
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();
    return true;
  }

  void _hideSelectionOverlayIfNeeded() {
    _selectionOverlay?.hide();
    _selectionOverlay = null;
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    _selectionOverlay?.hide();
  }

  /// Toggles the visibility of the toolbar.
  void toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar();
    } else {
      showToolbar();
    }
  }

  @override
  String get autofillId => 'EditableText-$hashCode';

  TextInputConfiguration _createTextInputConfiguration(
      bool needsAutofillConfiguration) {
    return TextInputConfiguration(
      inputType: widget.keyboardType,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      inputAction: widget.textInputAction ??
          (widget.keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done),
      textCapitalization: widget.textCapitalization,
      keyboardAppearance: widget.keyboardAppearance,
      autofillConfiguration: !needsAutofillConfiguration
          ? AutofillConfiguration.disabled
          : AutofillConfiguration(
              uniqueIdentifier: autofillId,
              autofillHints:
                  widget.autofillHints?.toList(growable: false) ?? <String>[],
              currentEditingValue: currentTextEditingValue,
            ),
    );
  }

  @override
  TextInputConfiguration get textInputConfiguration {
    return _createTextInputConfiguration(_needsAutofill);
  }

  // null if no promptRect should be shown.
  TextRange? _currentPromptRectRange;

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    setState(() {
      _currentPromptRectRange = TextRange(start: start, end: end);
    });
  }

  VoidCallback? _semanticsOnCopy(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            copyEnabled &&
            _hasFocus &&
            controls?.canCopy(this) == true
        ? () => controls!.handleCopy(this, _clipboardStatus)
        : null;
  }

  VoidCallback? _semanticsOnCut(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            cutEnabled &&
            _hasFocus &&
            controls?.canCut(this) == true
        ? () => controls!.handleCut(this, _clipboardStatus)
        : null;
  }

  VoidCallback? _semanticsOnPaste(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            pasteEnabled &&
            _hasFocus &&
            controls?.canPaste(this) == true &&
            (_clipboardStatus == null ||
                _clipboardStatus!.value == ClipboardStatus.pasteable)
        ? () => controls!.handlePaste(this)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment!.reparent();
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls? controls = widget.selectionControls;
    return MouseRegion(
      cursor: widget.mouseCursor ?? SystemMouseCursors.text,
      child: Scrollable(
        excludeFromSemantics: true,
        axisDirection: _isMultiline ? AxisDirection.down : AxisDirection.right,
        controller: _scrollController,
        physics: widget.scrollPhysics,
        dragStartBehavior: widget.dragStartBehavior,
        restorationId: widget.restorationId,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: Semantics(
              onCopy: _semanticsOnCopy(controls),
              onCut: _semanticsOnCut(controls),
              onPaste: _semanticsOnPaste(controls),
              child: _Editable(
                key: _editableKey,
                startHandleLayerLink: _startHandleLayerLink,
                endHandleLayerLink: _endHandleLayerLink,
                textSpan: _buildTextSpan(),
                value: _value,
                cursorColor: _cursorColor,
                backgroundCursorColor: widget.backgroundCursorColor,
                showCursor: ExtendedEditableText.debugDeterministicCursor
                    ? ValueNotifier<bool>(widget.showCursor)
                    : _cursorVisibilityNotifier,
                forceLine: widget.forceLine,
                readOnly: widget.readOnly,
                hasFocus: _hasFocus,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                expands: widget.expands,
                strutStyle: widget.strutStyle,
                selectionColor: widget.selectionColor,
                textScaleFactor: widget.textScaleFactor ??
                    MediaQuery.textScaleFactorOf(context),
                textAlign: widget.textAlign,
                textDirection: _textDirection,
                locale: widget.locale,
                textHeightBehavior: widget.textHeightBehavior ??
                    DefaultTextHeightBehavior.of(context),
                textWidthBasis: widget.textWidthBasis,
                obscuringCharacter: widget.obscuringCharacter,
                obscureText: widget.obscureText,
                autocorrect: widget.autocorrect,
                smartDashesType: widget.smartDashesType,
                smartQuotesType: widget.smartQuotesType,
                enableSuggestions: widget.enableSuggestions,
                offset: offset,
                onSelectionChanged: _handleSelectionChanged,
                onCaretChanged: _handleCaretChanged,
                rendererIgnoresPointer: widget.rendererIgnoresPointer,
                cursorWidth: widget.cursorWidth,
                cursorHeight: widget.cursorHeight,
                cursorRadius: widget.cursorRadius,
                cursorOffset: widget.cursorOffset,
                selectionHeightStyle: widget.selectionHeightStyle,
                selectionWidthStyle: widget.selectionWidthStyle,
                paintCursorAboveText: widget.paintCursorAboveText,
                enableInteractiveSelection: widget.enableInteractiveSelection,
                textSelectionDelegate: this,
                devicePixelRatio: _devicePixelRatio,
                supportSpecialText: supportSpecialText,
                promptRectRange: _currentPromptRectRange,
                promptRectColor: widget.autocorrectionTextRectColor,
                clipBehavior: widget.clipBehavior,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds [TextSpan] from current editing value.
  ///
  /// By default makes text in composing range appear as underlined.
  /// Descendants can override this method to customize appearance of text.
  InlineSpan _buildTextSpan() {
    if (widget.obscureText) {
      String text = _value.text;
      text = widget.obscuringCharacter * text.length;
      // Reveal the latest character in an obscured field only on mobile.
      if ((defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.fuchsia) &&
          !kIsWeb) {
        final int? o =
            _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
        if (o != null && o >= 0 && o < text.length)
          text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
        return TextSpan(style: widget.style, text: text);
      }
    }

    if (_value.composing.isValid && !widget.readOnly) {
      final TextStyle composingStyle = widget.style.merge(
        const TextStyle(decoration: TextDecoration.underline),
      );
      final String beforeText = _value.composing.textBefore(_value.text);
      final String insideText = _value.composing.textInside(_value.text);
      final String afterText = _value.composing.textAfter(_value.text);

      if (supportSpecialText) {
        final TextSpan before = widget.specialTextSpanBuilder!
            .build(beforeText, textStyle: widget.style);
        final TextSpan after = widget.specialTextSpanBuilder!
            .build(afterText, textStyle: widget.style);

        final List<InlineSpan> children = <InlineSpan>[];

        children.add(before);

        children.add(TextSpan(
          style: composingStyle,
          text: insideText,
        ));

        children.add(after);

        return TextSpan(style: widget.style, children: children);
      }

      return TextSpan(style: widget.style, children: <TextSpan>[
        TextSpan(text: beforeText),
        TextSpan(
          style: composingStyle,
          text: insideText,
        ),
        TextSpan(text: afterText),
      ]);
    }

    //final String text = _value.text;

    if (supportSpecialText) {
      final TextSpan? specialTextSpan = widget.specialTextSpanBuilder
          ?.build(_value.text, textStyle: widget.style);
      if (specialTextSpan != null) {
        return specialTextSpan;
      }
    }

    // Read only mode should not paint text composing.
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: !widget.readOnly,
    );

    //return TextSpan(style: widget.style, text: text);
  }

  void _updateForScroll() {
    _selectionOverlay?.updateForScroll();
  }

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    textEditingValue = value;
  }

  @override
  void autofill(TextEditingValue value) => updateEditingValue(value);

  /// Copy current selection to [Clipboard].
  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar(false);

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Collapse the selection and hide the toolbar and handles.
          userUpdateTextEditingValue(
            TextEditingValue(
              text: textEditingValue.text,
              selection: TextSelection.collapsed(
                  offset: textEditingValue.selection.end),
            ),
            SelectionChangedCause.toolbar,
          );
          break;
      }
    }
  }

  void _replaceText(ReplaceTextIntent intent) {
    userUpdateTextEditingValue(
      intent.currentTextEditingValue
          .replaced(intent.replacementRange, intent.replacementText),
      intent.cause,
    );
  }

  /// Cut current selection to [Clipboard].
  @override
  void cutSelection(SelectionChangedCause cause) {
    if (widget.readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    _replaceText(ReplaceTextIntent(textEditingValue, '', selection, cause));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar();
    }
  }

  /// Paste text from [Clipboard].
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (widget.readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    if (!selection.isValid) {
      return;
    }
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }

    _replaceText(
        ReplaceTextIntent(textEditingValue, data.text!, selection, cause));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar();
    }
  }

  /// Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    userUpdateTextEditingValue(
      textEditingValue.copyWith(
        selection: TextSelection(
            baseOffset: 0, extentOffset: textEditingValue.text.length),
      ),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
    }
  }
}

class _Editable extends MultiChildRenderObjectWidget {
  _Editable({
    Key? key,
    required this.textSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.cursorColor,
    this.backgroundCursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.readOnly,
    this.textHeightBehavior,
    required this.textWidthBasis,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.strutStyle,
    this.selectionColor,
    required this.textScaleFactor,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.obscuringCharacter,
    required this.obscureText,
    required this.autocorrect,
    required this.smartDashesType,
    required this.smartQuotesType,
    required this.enableSuggestions,
    required this.offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOffset,
    required this.paintCursorAboveText,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.supportSpecialText = false,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
  }) : super(
          key: key,
          children: _extractChildren(textSpan),
        );
  // Traverses the InlineSpan tree and depth-first collects the list of
  // child widgets that are created in WidgetSpans.
  static List<Widget> _extractChildren(InlineSpan span) {
    final List<Widget> result = <Widget>[];
    span.visitChildren((InlineSpan span) {
      if (span is WidgetSpan) {
        result.add(span.child);
      }
      return true;
    });
    return result;
  }

  final bool supportSpecialText;
  final InlineSpan textSpan;
  final TextEditingValue value;
  final Color? cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final Color? backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool readOnly;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final StrutStyle? strutStyle;
  final Color? selectionColor;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final String obscuringCharacter;
  final bool obscureText;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final bool autocorrect;
  final SmartDashesType smartDashesType;
  final SmartQuotesType smartQuotesType;
  final bool enableSuggestions;
  final ViewportOffset offset;
  final TextSelectionChangedHandler? onSelectionChanged;
  final CaretChangedHandler? onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset? cursorOffset;
  final bool paintCursorAboveText;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final TextRange? promptRectRange;
  final Color? promptRectColor;
  final Clip clipBehavior;

  @override
  ExtendedRenderEditable createRenderObject(BuildContext context) {
    return ExtendedRenderEditable(
      supportSpecialText: supportSpecialText,
      text: textSpan,
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
      onSelectionChanged: onSelectionChanged,
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

  @override
  void updateRenderObject(
      BuildContext context, ExtendedRenderEditable renderObject) {
    renderObject
      ..supportSpecialText = supportSpecialText
      ..text = textSpan
      ..cursorColor = cursorColor
      ..startHandleLayerLink = startHandleLayerLink
      ..endHandleLayerLink = endHandleLayerLink
      ..showCursor = showCursor
      ..forceLine = forceLine
      ..readOnly = readOnly
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..minLines = minLines
      ..expands = expands
      ..strutStyle = strutStyle
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale ?? Localizations.maybeLocaleOf(context)
      ..selection = value.selection
      ..offset = offset
      ..onSelectionChanged = onSelectionChanged
      ..onCaretChanged = onCaretChanged
      ..ignorePointer = rendererIgnoresPointer
      ..textHeightBehavior = textHeightBehavior
      ..textWidthBasis = textWidthBasis
      ..obscuringCharacter = obscuringCharacter
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorRadius = cursorRadius
      ..cursorOffset = cursorOffset
      ..selectionHeightStyle = selectionHeightStyle
      ..selectionWidthStyle = selectionWidthStyle
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText
      ..promptRectColor = promptRectColor
      ..clipBehavior = clipBehavior
      ..setPromptRectRange(promptRectRange);
  }
}

// This formatter inserts [Unicode.RLM] and [Unicode.LRM] into the
// string in order to preserve expected caret behavior when trailing
// whitespace is inserted.
//
// When typing in a direction that opposes the base direction
// of the paragraph, un-enclosed whitespace gets the directionality
// of the paragraph. This is often at odds with what is immediately
// being typed causing the caret to jump to the wrong side of the text.
// This formatter makes use of the RLM and LRM to cause the text
// shaper to inherently treat the whitespace as being surrounded
// by the directionality of the previous non-whitespace codepoint.
class _WhitespaceDirectionalityFormatter extends TextInputFormatter {
  // The [textDirection] should be the base directionality of the
  // paragraph/editable.
  _WhitespaceDirectionalityFormatter({TextDirection? textDirection})
      : _baseDirection = textDirection,
        _previousNonWhitespaceDirection = textDirection;

  // Using regex here instead of ICU is suboptimal, but is enough
  // to produce the correct results for any reasonable input where this
  // is even relevant. Using full ICU would be a much heavier change,
  // requiring exposure of the C++ ICU API.
  //
  // LTR covers most scripts and symbols, including but not limited to Latin,
  // ideographic scripts (Chinese, Japanese, etc), Cyrilic, Indic, and
  // SE Asian scripts.
  final RegExp _ltrRegExp = RegExp(
      r'[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF]');
  // RTL covers Arabic, Hebrew, and other RTL languages such as Urdu,
  // Aramic, Farsi, Dhivehi.
  final RegExp _rtlRegExp =
      RegExp(r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]');
  // Although whitespaces are not the only codepoints that have weak directionality,
  // these are the primary cause of the caret being misplaced.
  final RegExp _whitespaceRegExp = RegExp(r'\s');

  final TextDirection? _baseDirection;
  // Tracks the directionality of the most recently encountered
  // codepoint that was not whitespace. This becomes the direction of
  // marker inserted to fully surround ambiguous whitespace.
  TextDirection? _previousNonWhitespaceDirection;

  // Prevents the formatter from attempting more expensive formatting
  // operations mixed directionality is found.
  bool _hasOpposingDirection = false;

  // See [Unicode.RLM] and [Unicode.LRM].
  //
  // We do not directly use the [Unicode] constants since they are strings.
  static const int _rlm = 0x200F;
  static const int _lrm = 0x200E;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Skip formatting (which can be more expensive) if there are no cases of
    // mixing directionality. Once a case of mixed directionality is found,
    // always perform the formatting.
    if (!_hasOpposingDirection) {
      _hasOpposingDirection = _baseDirection == TextDirection.ltr
          ? _rtlRegExp.hasMatch(newValue.text)
          : _ltrRegExp.hasMatch(newValue.text);
    }

    if (_hasOpposingDirection) {
      _previousNonWhitespaceDirection = _baseDirection;

      final List<int> outputCodepoints = <int>[];

      // We add/subtract from these as we insert/remove markers.
      int selectionBase = newValue.selection.baseOffset;
      int selectionExtent = newValue.selection.extentOffset;
      int composingStart = newValue.composing.start;
      int composingEnd = newValue.composing.end;

      void addToLength() {
        selectionBase += outputCodepoints.length <= selectionBase ? 1 : 0;
        selectionExtent += outputCodepoints.length <= selectionExtent ? 1 : 0;

        composingStart += outputCodepoints.length <= composingStart ? 1 : 0;
        composingEnd += outputCodepoints.length <= composingEnd ? 1 : 0;
      }

      void subtractFromLength() {
        selectionBase -= outputCodepoints.length < selectionBase ? 1 : 0;
        selectionExtent -= outputCodepoints.length < selectionExtent ? 1 : 0;

        composingStart -= outputCodepoints.length < composingStart ? 1 : 0;
        composingEnd -= outputCodepoints.length < composingEnd ? 1 : 0;
      }

      final bool isBackspace =
          oldValue.text.runes.length - newValue.text.runes.length == 1 &&
              isDirectionalityMarker(oldValue.text.runes.last) &&
              oldValue.text.substring(0, oldValue.text.length - 1) ==
                  newValue.text;

      bool previousWasWhitespace = false;
      bool previousWasDirectionalityMarker = false;
      int? previousNonWhitespaceCodepoint;
      int index = 0;
      for (final int codepoint in newValue.text.runes) {
        if (isWhitespace(codepoint)) {
          // Only compute the directionality of the non-whitespace
          // when the value is needed.
          if (!previousWasWhitespace &&
              previousNonWhitespaceCodepoint != null) {
            _previousNonWhitespaceDirection =
                getDirection(previousNonWhitespaceCodepoint);
          }
          // If we already added directionality for this run of whitespace,
          // "shift" the marker added to the end of the whitespace run.
          if (previousWasWhitespace) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }
          // Handle trailing whitespace deleting the directionality char instead of the whitespace.
          if (isBackspace && index == newValue.text.runes.length - 1) {
            // Do not append the whitespace to the outputCodepoints.
            subtractFromLength();
          } else {
            outputCodepoints.add(codepoint);
            addToLength();
            outputCodepoints.add(
                _previousNonWhitespaceDirection == TextDirection.rtl
                    ? _rlm
                    : _lrm);
          }

          previousWasWhitespace = true;
          previousWasDirectionalityMarker = false;
        } else if (isDirectionalityMarker(codepoint)) {
          // Handle pre-existing directionality markers. Use pre-existing marker
          // instead of the one we add.
          if (previousWasWhitespace) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }
          outputCodepoints.add(codepoint);

          previousWasWhitespace = false;
          previousWasDirectionalityMarker = true;
        } else {
          // If the whitespace was already enclosed by the same directionality,
          // we can remove the artificially added marker.
          if (!previousWasDirectionalityMarker &&
              previousWasWhitespace &&
              getDirection(codepoint) == _previousNonWhitespaceDirection) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }
          // Normal character, track its codepoint add it to the string.
          previousNonWhitespaceCodepoint = codepoint;
          outputCodepoints.add(codepoint);

          previousWasWhitespace = false;
          previousWasDirectionalityMarker = false;
        }
        index++;
      }
      final String formatted = String.fromCharCodes(outputCodepoints);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection(
            baseOffset: selectionBase,
            extentOffset: selectionExtent,
            affinity: newValue.selection.affinity,
            isDirectional: newValue.selection.isDirectional),
        composing: TextRange(start: composingStart, end: composingEnd),
      );
    }
    return newValue;
  }

  bool isWhitespace(int value) {
    return _whitespaceRegExp.hasMatch(String.fromCharCode(value));
  }

  bool isDirectionalityMarker(int value) {
    return value == _rlm || value == _lrm;
  }

  TextDirection getDirection(int value) {
    // Use the LTR version as short-circuiting will be more efficient since
    // there are more LTR codepoints.
    return _ltrRegExp.hasMatch(String.fromCharCode(value))
        ? TextDirection.ltr
        : TextDirection.rtl;
  }
}
