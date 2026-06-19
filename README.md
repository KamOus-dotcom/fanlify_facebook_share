# fanlify_facebook_share

Native Facebook link share plugin for Fanlify.

This package is intentionally small. Its first goal is to open the native iOS Facebook Share Dialog with a public Fanlify link such as:

```text
https://link.fanlify.eu/c/...
https://link.fanlify.eu/p/...
```

The shared URL is expected to be handled by Fanlify `linkPreview`, which provides Open Graph metadata for Facebook.

## Status

- iOS: native Facebook SDK `ShareDialog` with `ShareLinkContent`
- Android: stub only, returns `UNSUPPORTED_ANDROID`

For now, keep the existing working Android share path in FlutterFlow and use this package only for iOS testing.

## FlutterFlow dependency

Add this package as a Git dependency:

```yaml
fanlify_facebook_share:
  git:
    url: https://github.com/KamOus-dotcom/fanlify_facebook_share.git
    ref: main
```

## iOS requirements

The app `Info.plist` must contain the Fanlify Meta app values:

```xml
<key>FacebookAppID</key>
<string>2155366581985623</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Fanlify</string>
```

The URL scheme must include:

```xml
<string>fb2155366581985623</string>
```

Recommended `LSApplicationQueriesSchemes` values include:

```xml
<string>fbapi</string>
<string>fbauth2</string>
<string>fbshareextension</string>
<string>fb-messenger-share-api</string>
```

Do not add a duplicate `LSApplicationQueriesSchemes` block in FlutterFlow. If FlutterFlow already generates this key, prefer keeping one block only.

## AppDelegate

The Facebook SDK usually expects `FBSDKCoreKit` initialization in `AppDelegate.swift`.

If FlutterFlow or another Facebook package already initializes it, do not duplicate the initialization.

The standard iOS setup is:

```swift
import FBSDKCoreKit

ApplicationDelegate.shared.application(
  application,
  didFinishLaunchingWithOptions: launchOptions
)
```

and URL handling:

```swift
ApplicationDelegate.shared.application(app, open: url, options: options)
```

## FlutterFlow custom action example

```dart
import 'package:fanlify_facebook_share/fanlify_facebook_share.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String?> facebookShareIosNative(String url) async {
  try {
    final result = await FanlifyFacebookShare.shareLink(url);
    return result;
  } catch (e) {
    return 'ERROR|message=$e';
  }
}
```

For the first test, return the result into a SnackBar and do not fallback immediately. We need to know whether iOS returns `SUCCESS`, `CANCEL`, or `ERROR|message=...`.
