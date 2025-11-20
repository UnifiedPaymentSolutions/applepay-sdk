//
//  EPApplePayManager.m
//  EverypayApplePay
//
//  Created by EveryPay on 2025-11-20.
//  Copyright © 2025 EveryPay. All rights reserved.
//

#import "EPApplePayManager.h"

@interface EPApplePayManager ()

@property (nonatomic, strong, readwrite) PKPaymentButton *paymentButton;
@property (nonatomic, strong) PKPaymentRequest *currentPaymentRequest;

@end

@implementation EPApplePayManager

#pragma mark - Initialization

+ (instancetype)sharedManager {
    static EPApplePayManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EPApplePayManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialization code if needed
    }
    return self;
}

#pragma mark - Capability Checks

- (BOOL)canMakePayments {
    return [PKPaymentAuthorizationViewController canMakePayments];
}

- (BOOL)canMakePaymentsWithNetworks:(NSArray<PKPaymentNetwork> *)networks
                       capabilities:(PKMerchantCapability)capabilities {
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:networks
                                                                 capabilities:capabilities];
}

#pragma mark - Button Creation

- (PKPaymentButton *)createPaymentButtonWithType:(PKPaymentButtonType)type
                                           style:(PKPaymentButtonStyle)style {
    return [self createPaymentButtonWithType:type style:style corner:4.0];
}

- (PKPaymentButton *)createPaymentButtonWithType:(PKPaymentButtonType)type
                                           style:(PKPaymentButtonStyle)style
                                          corner:(CGFloat)cornerRadius {
    PKPaymentButton *button = [PKPaymentButton buttonWithType:type style:style];
    button.cornerRadius = cornerRadius;

    // Add target for button tap
    [button addTarget:self
               action:@selector(paymentButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];

    self.paymentButton = button;
    return button;
}

#pragma mark - Button Action

- (void)paymentButtonTapped:(PKPaymentButton *)sender {
    if ([self.delegate respondsToSelector:@selector(applePayButtonTapped)]) {
        [self.delegate applePayButtonTapped];
    }
}

#pragma mark - Payment Presentation

- (void)presentApplePayWithMerchantIdentifier:(NSString *)merchantId
                                  currencyCode:(NSString *)currencyCode
                                   countryCode:(NSString *)countryCode
                                  paymentItems:(NSArray<PKPaymentSummaryItem *> *)items
                            fromViewController:(UIViewController *)viewController {

    // Create payment request
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = merchantId;
    request.countryCode = countryCode;
    request.currencyCode = currencyCode;

    // Configure supported networks (Visa and Mastercard as specified)
    request.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard];

    // Set merchant capabilities
    request.merchantCapabilities = PKMerchantCapability3DS;

    // Set payment items
    request.paymentSummaryItems = items;

    // Store current request
    self.currentPaymentRequest = request;

    // Create and present payment authorization view controller
    PKPaymentAuthorizationViewController *paymentVC =
        [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];

    if (paymentVC) {
        paymentVC.delegate = self;
        [viewController presentViewController:paymentVC animated:YES completion:nil];
    } else {
        // Unable to create payment view controller
        NSError *error = [NSError errorWithDomain:@"com.everypay.applepay"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unable to create payment authorization view controller. Please check your payment request configuration."}];

        if ([self.delegate respondsToSelector:@selector(applePayPaymentFailed:)]) {
            [self.delegate applePayPaymentFailed:error];
        }
    }
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion {

    // Notify delegate about authorized payment
    if ([self.delegate respondsToSelector:@selector(applePayPaymentAuthorized:)]) {
        [self.delegate applePayPaymentAuthorized:payment];
    }

    // In a real implementation, you would:
    // 1. Send the payment token to your backend server
    // 2. Process the payment
    // 3. Return success or failure based on the server response
    //
    // For now, we'll return success. The integrating app should handle
    // the actual payment processing in the delegate method.

    PKPaymentAuthorizationResult *result = [[PKPaymentAuthorizationResult alloc]
                                           initWithStatus:PKPaymentAuthorizationStatusSuccess
                                           errors:nil];
    completion(result);
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        // Notify delegate that payment flow finished (either completed or cancelled)
        if ([self.delegate respondsToSelector:@selector(applePayPaymentCancelled)]) {
            [self.delegate applePayPaymentCancelled];
        }
    }];
}

@end
