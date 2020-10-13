#import "FlutterHyperpayPlugin.h"

@implementation FlutterHyperpayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_hyperpay"
            binaryMessenger:[registrar messenger]];
  FlutterHyperpayPlugin* instance = [[FlutterHyperpayPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }
  else if ([call.method isEqualToString:@"checkoutActivity"]) {
    self->checkoutID = call.arguments[@"checkoutID"];
    self->callbackURL = call.arguments[@"callbackIos"];
    self->languageCode = call.arguments[@"languageCodeIos"];
    self->provider = [OPPPaymentProvider paymentProviderWithMode:OPPProviderModeTest];
    OPPCheckoutSettings *checkoutSettings = [[OPPCheckoutSettings alloc] init];
    checkoutSettings.paymentBrands = @[@"VISA", @"MASTER"];
    checkoutSettings.shopperResultURL = self->callbackURL;
    checkoutSettings.displayTotalAmount = YES;
    checkoutSettings.storePaymentDetails = OPPCheckoutStorePaymentDetailsModeNever;
    self->checkoutProvider = [OPPCheckoutProvider checkoutProviderWithPaymentProvider:provider checkoutID:checkoutID settings:checkoutSettings];
    [checkoutProvider presentCheckoutForSubmittingTransactionCompletionHandler:^(OPPTransaction * _Nullable transaction, NSError * _Nullable error) {
        if (error) {
            result(@"HP_ERROR");
            // Executed in case of failure of the transaction for any reason
        } else if (transaction.type == OPPTransactionTypeSynchronous)  {
            // Send request to your server to obtain the status of the synchronous transaction
            // You can use transaction.resourcePath or just checkout id to do it
            result(@"HP_SYNC_COMPLETED");
        } else {
            // The SDK opens transaction.redirectUrl in a browser
            // See 'Asynchronous Payments' guide for more details
           result(@"HP_ASYNC_STARTED");
        }
    } cancelHandler:^{
        // Executed if the shopper closes the payment page prematurely
       result(@"HP_CANCELLED");
    }];
    }
  else if ([call.method isEqualToString:@"closeCheckout"]) {
    [checkoutProvider dismissCheckoutAnimated:YES completion:^{
        result(@"HP_ASYNC_CLOSED");
    }];
    } 
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
