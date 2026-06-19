import 'package:flutter/services.dart';

class FanlifyFacebookShare {
  static const MethodChannel _channel = MethodChannel('fanlify_facebook_share');

  /// Opens the Facebook Share Dialog for a public link URL.
  ///
  /// [mode] can be:
  /// - `automatic`
  /// - `native`
  /// - `browser`
  /// - `web`
  /// - `feedBrowser`
  ///
  /// Expected return values:
  /// - `SUCCESS|mode=...`
  /// - `CANCEL|mode=...|didShow=...`
  /// - `ERROR|mode=...|message=...`
  /// - `UNSUPPORTED_ANDROID` for the current Android stub
  static Future<String> shareLink(
    String url, {
    String mode = 'automatic',
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return 'ERROR|message=empty_url';
    }

    final result = await _channel.invokeMethod<String>(
      'shareLink',
      <String, Object?>{
        'url': trimmedUrl,
        'mode': mode,
      },
    );

    return result ?? 'ERROR|message=null_result';
  }
}
