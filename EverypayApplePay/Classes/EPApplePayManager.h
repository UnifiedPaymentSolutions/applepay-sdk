//
//  EPApplePayManager.h
//  EverypayApplePay
//
//  Created by EveryPay on 2025-11-20.
//  Copyright © 2025 EveryPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Completion handler for Apple Pay payment flow
 @param payment The payment object containing the payment token if successful
 @param error Error object if payment failed or was cancelled
 */
typedef void (^EPApplePayCompletionHandler)(PKPayment * _Nullable payment, NSError * _Nullable error);

@interface EPApplePayManager : NSObject <PKPaymentAuthorizationViewControllerDelegate>

/**
 Returns the shared instance of EPApplePayManager
 */
+ (instancetype)sharedManager;

/**
 Check if Apple Pay is available on this device
 @return YES if Apple Pay is available, NO otherwise
 */
- (BOOL)canMakePayments;

/**
 Check if Apple Pay can make payments with specific networks and capabilities
 @param networks Array of payment networks (e.g., PKPaymentNetworkVisa, PKPaymentNetworkMasterCard)
 @param capabilities Merchant capabilities (e.g., PKMerchantCapability3DS)
 @return YES if payments can be made with the specified networks and capabilities
 */
- (BOOL)canMakePaymentsWithNetworks:(NSArray<PKPaymentNetwork> *)networks
                       capabilities:(PKMerchantCapability)capabilities;

/**
 Configure the Apple Pay manager with merchant and payment information
 @param amount Payment amount as NSDecimalNumber
 @param merchantId Your Apple Pay merchant identifier
 @param merchantName Merchant display name shown to the user
 @param currencyCode Three-letter ISO 4217 currency code (e.g., "USD", "EUR")
 @param countryCode Two-letter ISO 3166 country code (e.g., "US", "GB")
 @param buttonType The button type (default: PKPaymentButtonTypeBuy)
 @param buttonStyle The button style (default: PKPaymentButtonStyleBlack)
 */
- (void)configureWithAmount:(NSDecimalNumber *)amount
           merchantIdentifier:(NSString *)merchantId
                 merchantName:(NSString *)merchantName
                 currencyCode:(NSString *)currencyCode
                  countryCode:(NSString *)countryCode
                   buttonType:(PKPaymentButtonType)buttonType
                  buttonStyle:(PKPaymentButtonStyle)buttonStyle;

/**
 Create and return an Apple Pay button configured with the settings from configureWithAmount:...
 The button automatically triggers the payment flow when tapped
 @return Configured PKPaymentButton instance ready to be added to your view hierarchy
 */
- (PKPaymentButton *)createPaymentButton;

/**
 Present the Apple Pay payment sheet
 @param viewController The view controller to present the payment sheet from
 @param completion Completion handler called with payment token on success, or error on failure/cancellation
 */
- (void)presentPaymentFromViewController:(UIViewController *)viewController
                       completionHandler:(EPApplePayCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
