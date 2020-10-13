package com.osama.flutter_hyperpay;

import android.app.Activity;
import android.app.Application;
import android.content.ComponentName;

import android.content.Intent;
import android.os.Bundle;
import com.osama.flutter_hyperpay.common.Constants;

import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity;
import com.oppwa.mobile.connect.checkout.meta.CheckoutSettings;
import com.oppwa.mobile.connect.checkout.meta.CheckoutSkipCVVMode;
import com.oppwa.mobile.connect.exception.PaymentError;
import com.oppwa.mobile.connect.provider.Connect;
import com.oppwa.mobile.connect.provider.Transaction;
import com.oppwa.mobile.connect.provider.TransactionType;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterHyperpayPlugin */
public class FlutterHyperpayPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private final PluginRegistry.Registrar registrar;
  Result  result;

  private static final String STATE_RESOURCE_PATH = "STATE_RESOURCE_PATH";

  protected String resourcePath;
  protected String callbackScheme;

  private Application.ActivityLifecycleCallbacks activityLifecycleCallbacks;

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_hyperpay");
    FlutterHyperpayPlugin paymentGatewayPlugin = new FlutterHyperpayPlugin(registrar);
    registrar.addActivityResultListener(paymentGatewayPlugin);
    registrar.addNewIntentListener(paymentGatewayPlugin);
    channel.setMethodCallHandler(paymentGatewayPlugin);
  }

  public FlutterHyperpayPlugin(final  PluginRegistry.Registrar registrar ) {

    this.registrar=registrar;

    this.activityLifecycleCallbacks =
            new Application.ActivityLifecycleCallbacks() {
              @Override
              public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

                if (savedInstanceState != null) {
                  resourcePath = savedInstanceState.getString(STATE_RESOURCE_PATH);
                }
              }

              @Override
              public void onActivityStarted(Activity activity) {}

              @Override
              public void onActivityResumed(Activity activity) {}

              @Override
              public void onActivityPaused(Activity activity) {}

              @Override
              public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
                if (activity == registrar.activity()) {
                  outState.putString(STATE_RESOURCE_PATH, resourcePath);
                }
              }

              @Override
              public void onActivityDestroyed(Activity activity) {}

              @Override
              public void onActivityStopped(Activity activity) {}
            };

    if (this.registrar != null
            && this.registrar.activity() != null
            && this.registrar.activity().getApplication() != null) {
      this.registrar
              .activity()
              .getApplication()
              .registerActivityLifecycleCallbacks(this.activityLifecycleCallbacks);
    }
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android");
    }
    else if (call.method.equals("checkoutActivity")) {
      this.result = result;
      String checkoutID = call.argument("checkoutID");
      String languageCode = call.argument("languageCode");
      String callbackURL = call.argument("callbackURL");
      callbackScheme = callbackURL;
      openCheckoutUI(checkoutID, languageCode);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == CheckoutActivity.REQUEST_CODE_CHECKOUT) {
      switch (resultCode) {
        case CheckoutActivity.RESULT_OK:
          Transaction transaction = data.getParcelableExtra(
                  CheckoutActivity.CHECKOUT_RESULT_TRANSACTION);
          resourcePath = data.getStringExtra(
                  CheckoutActivity.CHECKOUT_RESULT_RESOURCE_PATH);
          if (transaction.getTransactionType() == TransactionType.SYNC) {
              result.success("201");
          } else {
              result.success("200");
          }
          break;
        case CheckoutActivity.RESULT_CANCELED:
            result.success("403");
          break;
        case CheckoutActivity.RESULT_ERROR:
          PaymentError payError = data.getParcelableExtra(
                  CheckoutActivity.CHECKOUT_RESULT_ERROR);
                  result.error("400", payError.getErrorMessage(), payError.getErrorInfo());
      }
    }

    return false;
  }

  private void openCheckoutUI(String checkoutId, String languageCode) {
    CheckoutSettings checkoutSettings = createCheckoutSettings(checkoutId);
    checkoutSettings.setLocale(languageCode);
    Intent intent = checkoutSettings.createCheckoutActivityIntent(registrar.activity());
    registrar.activity().startActivityForResult(intent, CheckoutActivity.REQUEST_CODE_CHECKOUT);
  }

  private CheckoutSettings createCheckoutSettings(String checkoutId) {
    return new CheckoutSettings(checkoutId, Constants.Config.PAYMENT_BRANDS,
            Connect.ProviderMode.TEST)
            .setSkipCVVMode(CheckoutSkipCVVMode.FOR_STORED_CARDS)
            .setWindowSecurityEnabled(false)
            .setShopperResultUrl(callbackScheme + "://callback");
  }



  private boolean hasCallbackScheme(Intent intent) {
    String scheme = intent.getScheme();
    return  callbackScheme.equals(scheme);
  }

  @Override
  public boolean onNewIntent(Intent intent) {
    registrar.activity().setIntent(intent);
    if (resourcePath != null && hasCallbackScheme(intent)) {}
    return true;
  }
}
