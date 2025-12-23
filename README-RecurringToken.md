# Recurring Payment Token Support

This document describes how to request recurring payment tokens from Apple Pay using the EverypayApplePay SDK.

## Overview

Recurring payment tokens allow you to save card details for future payments. When enabled, Apple Pay will display additional consent UI to the user for saving their payment method.

## Requirements

- **iOS 16.0 or later** - The recurring payment feature uses `PKRecurringPaymentRequest` which requires iOS 16+
- The SDK remains backward compatible with iOS 12.4+, but recurring tokens are only available on iOS 16+

## API Reference

### Check Support

```objective-c
- (BOOL)canRequestRecurringToken;
```

Returns `YES` if the device supports recurring payment tokens (iOS 16+), `NO` otherwise.

### Enable Recurring Token

```objective-c
@property (nonatomic, assign) BOOL requestRecurringToken;
```

Set to `YES` to request a recurring payment token. Must be set before calling `presentPaymentFromViewController:completionHandler:`.

### Recurring Payment Properties

When `requestRecurringToken` is `YES`, you must configure the following required properties:

#### Required Properties

```objective-c
@property (nonatomic, copy, nullable) NSString *recurringPaymentDescription;
```
A description of the recurring payment shown in the payment sheet. This helps users understand what they're signing up for.

```objective-c
@property (nonatomic, strong, nullable) NSURL *recurringManagementURL;
```
A URL where users can manage (update or delete) their recurring payment. This URL appears in the Wallet app, allowing users to access subscription management directly.

#### Optional Properties

```objective-c
@property (nonatomic, copy, nullable) NSString *recurringBillingLabel;
```
Label for the recurring billing line item shown in the payment sheet. If not set, defaults to the merchant name.

```objective-c
@property (nonatomic, copy, nullable) NSString *recurringBillingAgreement;
```
A localized billing agreement text displayed to the user before they authorize payment. Use this to explain the recurring terms and conditions.

## Usage Example

```objective-c
#import <EverypayApplePay/EverypayApplePay.h>

- (void)setupApplePay {
    EPApplePayManager *manager = [EPApplePayManager sharedManager];

    // Step 1: Configure payment details
    [manager configureWithAmount:[NSDecimalNumber decimalNumberWithString:@"9.99"]
              merchantIdentifier:@"merchant.com.yourcompany.app"
                    merchantName:@"Your Store Name"
                    currencyCode:@"EUR"
                     countryCode:@"EE"
                      buttonType:PKPaymentButtonTypeBuy
                     buttonStyle:PKPaymentButtonStyleBlack];

    // Step 2: Enable recurring token if supported
    if ([manager canRequestRecurringToken]) {
        manager.requestRecurringToken = YES;

        // Required: Set payment description and management URL
        manager.recurringPaymentDescription = @"Save card for future payments";
        manager.recurringManagementURL = [NSURL URLWithString:@"https://yourstore.com/manage-payments"];

        // Optional: Custom billing label (defaults to merchantName if not set)
        manager.recurringBillingLabel = @"Card on file";

        // Optional: Billing agreement text shown to user
        manager.recurringBillingAgreement = @"Your card will be saved for future purchases. You can remove it anytime from your account settings.";

        NSLog(@"Recurring payment token enabled");
    } else {
        NSLog(@"Recurring payment token not supported (requires iOS 16+)");
    }
}

- (void)handlePayment {
    EPApplePayManager *manager = [EPApplePayManager sharedManager];

    // Step 3: Present payment sheet
    [manager presentPaymentFromViewController:self
                            completionHandler:^(PKPayment *payment, NSError *error) {
        if (payment) {
            // Payment successful - payment.token contains the recurring token
            NSLog(@"Payment authorized!");
            NSLog(@"Transaction ID: %@", payment.token.transactionIdentifier);

            // Send payment.token to your backend for processing
            [self processPaymentToken:payment.token];
        } else if (error) {
            NSLog(@"Payment error: %@", error.localizedDescription);
        }
    }];
}
```

## Recurring Payment Request Configuration

When `requestRecurringToken` is enabled, the SDK configures the `PKRecurringPaymentRequest` as follows:

| Property | Source | Description |
|----------|--------|-------------|
| `paymentDescription` | `recurringPaymentDescription` | User-facing description shown in the payment sheet |
| `regularBilling.label` | `recurringBillingLabel` or `merchantName` | Line item label for the recurring charge |
| `regularBilling.amount` | Payment amount from configuration | The recurring charge amount |
| `regularBilling.intervalUnit` | `NSCalendarUnitMonth` | Billing interval (fixed to monthly) |
| `managementURL` | `recurringManagementURL` | URL for managing the recurring payment in Wallet |
| `billingAgreement` | `recurringBillingAgreement` (optional) | Terms shown before authorization |

For more details, see [Apple's PKRecurringPaymentRequest documentation](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest).

## Backward Compatibility

The SDK handles iOS version differences automatically:

| iOS Version | Behavior |
|-------------|----------|
| iOS 16+ | Full recurring token support |
| iOS 12.4 - 15.x | `canRequestRecurringToken` returns `NO`, payment proceeds normally without recurring request |

Even if `requestRecurringToken` is set to `YES` on older iOS versions, the payment will proceed normally without the recurring payment request - no errors will occur.

## Swift Example

```swift
import EverypayApplePay

class PaymentViewController: UIViewController {

    let manager = EPApplePayManager.shared()

    func setupPayment() {
        // Configure
        manager.configure(
            with: NSDecimalNumber(string: "9.99"),
            merchantIdentifier: "merchant.com.yourcompany.app",
            merchantName: "Your Store Name",
            currencyCode: "EUR",
            countryCode: "EE",
            buttonType: .buy,
            buttonStyle: .black
        )

        // Enable recurring token if available
        if manager.canRequestRecurringToken() {
            manager.requestRecurringToken = true

            // Required properties
            manager.recurringPaymentDescription = "Save card for future payments"
            manager.recurringManagementURL = URL(string: "https://yourstore.com/manage-payments")

            // Optional properties
            manager.recurringBillingLabel = "Card on file"
            manager.recurringBillingAgreement = "Your card will be saved for future purchases."
        }
    }

    func presentPayment() {
        manager.presentPayment(from: self) { payment, error in
            if let payment = payment {
                print("Payment authorized: \(payment.token.transactionIdentifier)")
            } else if let error = error {
                print("Payment error: \(error.localizedDescription)")
            }
        }
    }
}
```

## Related Documentation

- [Apple PKRecurringPaymentRequest Documentation](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest)
- [Apple PKRecurringPaymentSummaryItem Documentation](https://developer.apple.com/documentation/passkit/pkrecurringpaymentsummaryitem)
