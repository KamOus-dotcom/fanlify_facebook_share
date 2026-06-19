import 'package:flutter/services.dart';

class FanlifyFacebookShare {
  static const MethodChannel _channel = MethodChannel('fanlify_facebook_share');

  /// Opens the native Facebook Share Dialog for a public link URL.
  ///
  /// Expected return values:
  /// - `SUCCESS`
  /// - `CANCEL`
  /// - `ERROR|message=...`
  /// - `UNSUPPORTED_ANDROID` for the current Android stub
  static Future<String> shareLink(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return 'ERROR|message=empty_url';
    }

    final result = await _channel.invokeMethod<String>(
      'shareLink',
      <String, Object?>{'url': trimmedUrl},
    );

    return result ?? 'ERROR|message=null_result';
  }
}
