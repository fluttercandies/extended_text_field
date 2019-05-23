## [0.2.7]

* fix selection handles blinking

## [0.2.6]

* take care when TextSpan children is null

## [0.2.5]

* update extended_text_library
* update extended_text_library
1.remove caretIn parameter(SpecialTextSpan)
2.deleteAll parameter has the same effect as caretIn parameter(SpecialTextSpan)

## [0.2.4]

* fix caret position about image span
* add caretIn parameter(whether caret can move into special text for SpecialTextSpan(like a image span or @xxxx)) for SpecialTextSpan

## [0.2.3]

* disabled informationCollector to keep backwards compatibility for now (ExtendedNetworkImageProvider)

## [0.2.2]

* fix caret position for last one image span
* add image text demo
* fix position for specialTex

## [0.2.1]

* fix caret position for image span

## [0.2.0]

* only iterate textSpan.children to find SpecialTextSpan

## [0.1.9]

* add BackgroundTextSpan, support to paint custom background

## [0.1.8]

* handle TextEditingValue's composing

## [0.1.6]

* improve codes to avoid unnecessary computation

## [0.1.5]

* override compareTo method in SpecialTextSpan and ImageSpan to
  fix issue that image span or special text span was error rendering

## [0.1.4]

* update limitation
* improve codes

## [0.1.3]

* update limitation
* improve codes

## [0.1.1]

* support special text amd inline image
