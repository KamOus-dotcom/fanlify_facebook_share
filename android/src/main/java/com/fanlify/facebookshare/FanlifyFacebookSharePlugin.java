package com.fanlify.facebookshare;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.share.Sharer;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.widget.ShareDialog;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class FanlifyFacebookSharePlugin implements
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

  private MethodChannel channel;
  private Activity activity;
  private ActivityPluginBinding activityBinding;
  private CallbackManager callbackManager;
  private MethodChannel.Result pendingResult;
  private String pendingMode = "automatic";
  private boolean pendingDidShow = false;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "fanlify_facebook_share");
    channel.setMethodCallHandler(this);
    callbackManager = CallbackManager.Factory.create();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if ("shareLink".equals(call.method)) {
      shareLink(call, result);
      return;
    }

    result.notImplemented();
  }

  private void shareLink(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (pendingResult != null) {
      result.success("ERROR|message=share_already_in_progress");
      return;
    }

    if (activity == null) {
      result.success("ERROR|message=no_activity");
      return;
    }

    final String url = call.argument("url");
    final String requestedMode = call.argument("mode") == null
        ? "automatic"
        : call.<String>argument("mode");

    if (url == null || url.trim().isEmpty()) {
      result.success("ERROR|message=empty_url");
      return;
    }

    final Uri uri = Uri.parse(url.trim());
    final String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase();
    if (!scheme.startsWith("http")) {
      result.success("ERROR|message=invalid_url");
      return;
    }

    final ShareLinkContent content = new ShareLinkContent.Builder()
        .setContentUrl(uri)
        .build();

    final ShareDialog dialog = new ShareDialog(activity);
    dialog.registerCallback(callbackManager, new FacebookCallback<Sharer.Result>() {
      @Override
      public void onSuccess(Sharer.Result shareResult) {
        finish("SUCCESS|mode=" + pendingMode + "|didShow=" + pendingDidShow);
      }

      @Override
      public void onCancel() {
        finish("CANCEL|mode=" + pendingMode + "|didShow=" + pendingDidShow);
      }

      @Override
      public void onError(@NonNull FacebookException error) {
        finish("ERROR|mode=" + pendingMode + "|didShow=" + pendingDidShow + "|message=" + escape(error.getMessage()));
      }
    });

    final ShareDialog.Mode mode = dialogMode(requestedMode);
    if (!ShareDialog.canShow(content, mode)) {
      result.success("ERROR|mode=" + requestedMode + "|message=dialog_cannot_show");
      return;
    }

    pendingResult = result;
    pendingMode = requestedMode;
    pendingDidShow = true;
    dialog.show(content, mode);
  }

  private void finish(String value) {
    MethodChannel.Result result = pendingResult;
    pendingResult = null;
    pendingMode = "automatic";
    pendingDidShow = false;

    if (result != null) {
      result.success(value);
    }
  }

  private ShareDialog.Mode dialogMode(@Nullable String value) {
    if (value == null) {
      return ShareDialog.Mode.AUTOMATIC;
    }

    switch (value.toLowerCase()) {
      case "native":
        return ShareDialog.Mode.NATIVE;
      case "web":
      case "browser":
        return ShareDialog.Mode.WEB;
      case "feed":
      case "feedbrowser":
      case "feed_browser":
      case "feed-browser":
        return ShareDialog.Mode.FEED;
      default:
        return ShareDialog.Mode.AUTOMATIC;
    }
  }

  private static String escape(@Nullable String value) {
    if (value == null) {
      return "unknown";
    }

    return value
        .replace("|", "/")
        .replace("\n", " ")
        .replace("\r", " ");
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
    return callbackManager != null && callbackManager.onActivityResult(requestCode, resultCode, data);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    activity = binding.getActivity();
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    detachActivity();
  }

  private void detachActivity() {
    if (activityBinding != null) {
      activityBinding.removeActivityResultListener(this);
    }
    activityBinding = null;
    activity = null;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    callbackManager = null;
  }
}
