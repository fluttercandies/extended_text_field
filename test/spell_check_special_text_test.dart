import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _source = '@[Mira] hello wrold';
const String _token = '@[Mira]';
const TextStyle _misspelledStyle = TextStyle(
  decoration: TextDecoration.underline,
  decorationColor: Colors.red,
  decorationStyle: TextDecorationStyle.wavy,
);

void main() {
  testWidgets(
    'spell check preserves special spans and metadata during composition',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focusNode = FocusNode();
      final TapGestureRecognizer recognizer = TapGestureRecognizer();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      addTearDown(recognizer.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: ExtendedTextField(
              controller: controller,
              focusNode: focusNode,
              specialTextSpanBuilder: _TokenFirstSpanBuilder(recognizer),
              extendedSpellCheckConfiguration: ExtendedSpellCheckConfiguration(
                spellCheckService: _FakeSpellCheckService(),
                misspelledTextStyle: _misspelledStyle,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExtendedTextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: _source,
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 2, end: 4),
        ),
      );
      await tester.pumpAndSettle();

      final ExtendedEditableTextState state =
          tester.state<ExtendedEditableTextState>(
        find.byType(ExtendedEditableText),
      );
      final TextSpan rendered = state.renderEditable.text! as TextSpan;
      final List<TextSpan> textSpans = <TextSpan>[];
      final List<ExtendedWidgetSpan> widgetSpans = <ExtendedWidgetSpan>[];
      rendered.visitChildren((InlineSpan span) {
        if (span is TextSpan && span.text != null) {
          textSpans.add(span);
        }
        if (span is ExtendedWidgetSpan) {
          widgetSpans.add(span);
        }
        return true;
      });

      expect(
        textSpans.where(
          (TextSpan span) =>
              span.text == 'wrold' && span.style == _misspelledStyle,
        ),
        hasLength(1),
      );
      expect(textSpans.where((TextSpan span) => span.text == 'Mi'), isEmpty);
      expect(_hasItalicSpan(rendered), isTrue);
      expect(rendered.recognizer, same(recognizer));
      expect(rendered.mouseCursor, SystemMouseCursors.precise);
      expect(rendered.onEnter, same(_handleEnter));
      expect(rendered.onExit, same(_handleExit));
      expect(rendered.semanticsIdentifier, 'composer-text');
      expect(rendered.locale, const Locale('en'));
      expect(rendered.spellOut, isTrue);
      expect(widgetSpans, hasLength(1));
      expect(widgetSpans.single.actualText, _token);
      expect(ExtendedTextLibraryUtils.textSpanToActualText(rendered), _source);
    },
  );
}

bool _hasItalicSpan(InlineSpan span) {
  if (span.style?.fontStyle == FontStyle.italic) {
    return true;
  }
  if (span is TextSpan) {
    return span.children?.any(_hasItalicSpan) ?? false;
  }
  return false;
}

void _handleEnter(PointerEnterEvent event) {}
void _handleExit(PointerExitEvent event) {}

class _FakeSpellCheckService implements SpellCheckService {
  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    return const <SuggestionSpan>[
      SuggestionSpan(TextRange(start: 14, end: 19), <String>['world']),
    ];
  }
}

class _TokenFirstSpanBuilder extends SpecialTextSpanBuilder {
  _TokenFirstSpanBuilder(this.recognizer);

  final GestureRecognizer recognizer;

  @override
  TextSpan build(
    String data, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    if (!data.startsWith(_token)) {
      return TextSpan(text: data, style: textStyle);
    }
    return TextSpan(
      style: textStyle,
      recognizer: recognizer,
      mouseCursor: SystemMouseCursors.precise,
      onEnter: _handleEnter,
      onExit: _handleExit,
      semanticsIdentifier: 'composer-text',
      locale: const Locale('en'),
      spellOut: true,
      children: <InlineSpan>[
        ExtendedWidgetSpan(
          actualText: _token,
          child: const SizedBox(width: 20, height: 20),
        ),
        TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: <InlineSpan>[
            TextSpan(text: data.substring(_token.length)),
          ],
        ),
      ],
    );
  }

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    return null;
  }
}
