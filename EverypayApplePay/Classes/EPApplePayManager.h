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

@protocol EPApplePayManagerDelegate <NSObject>

@optional
- (void)applePayButtonTapped;
- (void)applePayPaymentAuthorized:(PKPayment *)payment;
- (void)applePayPaymentFailed:(NSError *)error;
- (void)applePayPaymentCancelled;

@end

@interface EPApplePayManager : NSObject <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, weak, nullable) id<EPApplePayManagerDelegate> delegate;
@property (nonatomic, strong, readonly) PKPaymentButton *paymentButton;

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
 Create an Apple Pay button with default corner radius
 @param type The button type (e.g., PKPaymentButtonTypeBuy, PKPaymentButtonTypeCheckout)
 @param style The button style (e.g., PKPaymentButtonStyleBlack, PKPaymentButtonStyleWhite)
 @return Configured PKPaymentButton instance
 */
- (PKPaymentButton *)createPaymentButtonWithType:(PKPaymentButtonType)type
                                           style:(PKPaymentButtonStyle)style;

/**
 Create an Apple Pay button with custom corner radius
 @param type The button type (e.g., PKPaymentButtonTypeBuy, PKPaymentButtonTypeCheckout)
 @param style The button style (e.g., PKPaymentButtonStyleBlack, PKPaymentButtonStyleWhite)
 @param cornerRadius Corner radius for the button (recommended: 4.0-8.0)
 @return Configured PKPaymentButton instance
 */
- (PKPaymentButton *)createPaymentButtonWithType:(PKPaymentButtonType)type
                                           style:(PKPaymentButtonStyle)style
                                          corner:(CGFloat)cornerRadius;

/**
 Present the Apple Pay payment sheet
 @param merchantId Your Apple Pay merchant identifier
 @param currencyCode Three-letter ISO 4217 currency code (e.g., "USD", "EUR")
 @param countryCode Two-letter ISO 3166 country code (e.g., "US", "GB")
 @param items Array of PKPaymentSummaryItem objects representing the payment breakdown
 @param viewController The view controller to present the payment sheet from
 */
- (void)presentApplePayWithMerchantIdentifier:(NSString *)merchantId
                                  currencyCode:(NSString *)currencyCode
                                   countryCode:(NSString *)countryCode
                                  paymentItems:(NSArray<PKPaymentSummaryItem *> *)items
                            fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
