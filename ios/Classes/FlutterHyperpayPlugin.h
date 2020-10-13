#import <Flutter/Flutter.h>
#import <OPPWAMobile/OPPWAMobile.h>

@interface FlutterHyperpayPlugin : NSObject<FlutterPlugin> {
    OPPPaymentProvider *provider;
    OPPCheckoutProvider *checkoutProvider;
    NSString *checkoutID;
    NSString *callbackURL;
    NSString *languageCode;
}
@end
