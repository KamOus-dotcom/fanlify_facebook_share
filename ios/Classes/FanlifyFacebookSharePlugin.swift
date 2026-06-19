import Flutter
import UIKit
import FBSDKCoreKit
import FBSDKShareKit

public class FanlifyFacebookSharePlugin: NSObject, FlutterPlugin, SharingDelegate {
  private var pendingResult: FlutterResult?
  private var pendingMode = "automatic"
  private var pendingDidShow = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "fanlify_facebook_share",
      binaryMessenger: registrar.messenger()
    )
    let instance = FanlifyFacebookSharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareLink":
      shareLink(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    return true
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any]
  ) -> Bool {
    return ApplicationDelegate.shared.application(application, open: url, options: options)
  }

  private func shareLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result("ERROR|message=share_already_in_progress")
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let urlString = args["url"] as? String,
      let url = URL(string: urlString),
      url.scheme?.lowercased().hasPrefix("http") == true
    else {
      result("ERROR|message=invalid_url")
      return
    }

    let requestedMode = (args["mode"] as? String) ?? "automatic"

    guard let rootViewController = Self.rootViewController() else {
      result("ERROR|mode=\(requestedMode)|message=no_root_view_controller")
      return
    }

    let content = ShareLinkContent()
    content.contentURL = url

    let dialog = ShareDialog(
      viewController: rootViewController,
      content: content,
      delegate: self
    )
    dialog.mode = Self.dialogMode(from: requestedMode)

    guard dialog.canShow else {
      result("ERROR|mode=\(requestedMode)|message=dialog_cannot_show")
      return
    }

    pendingResult = result
    pendingMode = requestedMode
    pendingDidShow = dialog.show()

    if !pendingDidShow {
      finish("ERROR|mode=\(requestedMode)|message=dialog_show_returned_false")
    }
  }

  public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
    finish("SUCCESS|mode=\(pendingMode)|didShow=\(pendingDidShow)")
  }

  public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
    finish("ERROR|mode=\(pendingMode)|didShow=\(pendingDidShow)|message=\(Self.escape(error.localizedDescription))")
  }

  public func sharerDidCancel(_ sharer: Sharing) {
    finish("CANCEL|mode=\(pendingMode)|didShow=\(pendingDidShow)")
  }

  private func finish(_ value: String) {
    let result = pendingResult
    pendingResult = nil
    pendingMode = "automatic"
    pendingDidShow = false
    result?(value)
  }

  private static func dialogMode(from value: String) -> ShareDialog.Mode {
    switch value.lowercased() {
    case "native":
      return .native
    case "browser":
      return .browser
    case "web":
      return .web
    case "feedbrowser", "feed_browser", "feed-browser":
      return .feedBrowser
    default:
      return .automatic
    }
  }

  private static func rootViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }

    let keyWindow = scenes
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    return topViewController(from: keyWindow?.rootViewController)
  }

  private static func topViewController(from viewController: UIViewController?) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }

    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }

    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }

    return viewController
  }

  private static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "|", with: "/")
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
  }
}
