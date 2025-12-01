//
//  EPApplePayManager.m
//  EverypayApplePay
//
//  Created by EveryPay on 2025-11-20.
//  Copyright © 2025 EveryPay. All rights reserved.
//

#import "EPApplePayManager.h"

@interface EPApplePayManager ()

// Configuration properties
@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, copy) NSString *merchantIdentifier;
@property (nonatomic, copy) NSString *merchantName;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, assign) PKPaymentButtonType buttonType;
@property (nonatomic, assign) PKPaymentButtonStyle buttonStyle;

// Payment flow properties
@property (nonatomic, strong) PKPaymentRequest *currentPaymentRequest;
@property (nonatomic, copy) EPApplePayCompletionHandler completionHandler;

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

#pragma mark - Configuration

- (void)configureWithAmount:(NSDecimalNumber *)amount
           merchantIdentifier:(NSString *)merchantId
                 merchantName:(NSString *)merchantName
                 currencyCode:(NSString *)currencyCode
                  countryCode:(NSString *)countryCode
                   buttonType:(PKPaymentButtonType)buttonType
                  buttonStyle:(PKPaymentButtonStyle)buttonStyle {

    self.amount = amount;
    self.merchantIdentifier = merchantId;
    self.merchantName = merchantName;
    self.currencyCode = currencyCode;
    self.countryCode = countryCode;
    self.buttonType = buttonType;
    self.buttonStyle = buttonStyle;
}

#pragma mark - Button Creation

- (PKPaymentButton *)createPaymentButton {
    PKPaymentButton *button = [PKPaymentButton buttonWithType:self.buttonType
                                                        style:self.buttonStyle];
    button.cornerRadius = 4.0;

    // Add target for button tap
    [button addTarget:self
               action:@selector(paymentButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];

    return button;
}

#pragma mark - Button Action

- (void)paymentButtonTapped:(PKPaymentButton *)sender {
    // Button tap is handled internally - no delegate callback needed
    // The merchant should call presentPaymentFromViewController:completionHandler:
    // This method is kept for potential future use or can be removed if not needed
}

#pragma mark - Payment Presentation

- (void)presentPaymentFromViewController:(UIViewController *)viewController
                       completionHandler:(EPApplePayCompletionHandler)completion {

    // Store completion handler
    self.completionHandler = completion;

    // Validate configuration
    if (!self.amount || !self.merchantIdentifier || !self.merchantName ||
        !self.currencyCode || !self.countryCode) {
        NSError *error = [NSError errorWithDomain:@"com.everypay.applepay"
                                             code:1000
                                         userInfo:@{NSLocalizedDescriptionKey: @"Apple Pay manager not configured. Call configureWithAmount:merchantIdentifier:... before presenting payment."}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    // Create payment request
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = self.merchantIdentifier;
    request.countryCode = self.countryCode;
    request.currencyCode = self.currencyCode;

    // Configure supported networks (Visa and Mastercard)
    request.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard];

    // Set merchant capabilities
    request.merchantCapabilities = PKMerchantCapability3DS;

    // Create payment summary item
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:self.merchantName
                                                                           amount:self.amount];
    request.paymentSummaryItems = @[totalItem];

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

        if (completion) {
            completion(nil, error);
        }
    }
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion {

    // Return success to Apple Pay - the merchant will handle the actual payment processing
    // with their backend using the payment token
    PKPaymentAuthorizationResult *result = [[PKPaymentAuthorizationResult alloc]
                                           initWithStatus:PKPaymentAuthorizationStatusSuccess
                                           errors:nil];
    completion(result);

    // Call merchant's completion handler with the payment token
    if (self.completionHandler) {
        self.completionHandler(payment, nil);
        self.completionHandler = nil; // Clear after calling
    }
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        // If completion handler wasn't called yet, it means payment was cancelled
        if (self.completionHandler) {
            NSError *error = [NSError errorWithDomain:@"com.everypay.applepay"
                                                 code:1002
                                             userInfo:@{NSLocalizedDescriptionKey: @"Payment was cancelled by the user."}];
            self.completionHandler(nil, error);
            self.completionHandler = nil;
        }
    }];
}

@end
