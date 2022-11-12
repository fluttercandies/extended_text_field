import 'dart:ui';

import 'package:extended_text_field/src/extended_text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'no_keyboard_mixin.dart';

/// void main() {
///   TextInputBinding();
///   runApp(const MyApp());
/// }
class TextInputBinding extends WidgetsFlutterBinding
    with TextInputBindingMixin {
  @override
  bool ignoreTextInputShow() {
    return SystemKeyboardShowWidgetMixin.ignoreShowSystemKeyboard<
        ExtendedTextField>();
  }
}

/// class YourBinding extends WidgetsFlutterBinding
///     with TextInputBindingMixin,YourBindingMixin {
///   @override
///   bool ignoreTextInputShow() {
///     // you can do base on your case
///     // ignore it if your need
///     return SystemKeyboardShowWidgetMixin.ignoreShowSystemKeyboard<
///         ExtendedTextField>();
///   }
/// }
/// void main() {
///   YourBinding();
///   runApp(const MyApp());
/// }
mixin TextInputBindingMixin on WidgetsFlutterBinding {
  @override
  BinaryMessenger createBinaryMessenger() {
    return TextInputBinaryMessenger(super.createBinaryMessenger(), this);
  }

  bool ignoreSendMessage(MethodCall methodCall) => false;

  bool ignoreTextInputShow() => false;
}

class TextInputBinaryMessenger extends BinaryMessenger {
  TextInputBinaryMessenger(this.origin, this.textInputBindingMixin);
  final BinaryMessenger origin;
  final TextInputBindingMixin textInputBindingMixin;
  @override
  Future<void> handlePlatformMessage(String channel, ByteData? data,
      PlatformMessageResponseCallback? callback) {
    return origin.handlePlatformMessage(channel, data, callback);
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) async {
    if (channel == SystemChannels.textInput.name) {
      final MethodCall methodCall =
          SystemChannels.textInput.codec.decodeMethodCall(message);
      bool ignore = false;
      switch (methodCall.method) {
        case 'TextInput.show':
          ignore = textInputBindingMixin.ignoreTextInputShow();
          break;
        default:
          ignore = textInputBindingMixin.ignoreSendMessage(methodCall);
      }

      if (ignore) {
        return null;
      }
    }
    return origin.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    origin.setMessageHandler(channel, handler);
  }
}
