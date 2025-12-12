# EverypayApplePay

[![Version](https://img.shields.io/cocoapods/v/EverypayApplePay.svg?style=flat)](https://cocoapods.org/pods/EverypayApplePay)
[![License](https://img.shields.io/cocoapods/l/EverypayApplePay.svg?style=flat)](https://cocoapods.org/pods/EverypayApplePay)
[![Platform](https://img.shields.io/cocoapods/p/EverypayApplePay.svg?style=flat)](https://cocoapods.org/pods/EverypayApplePay)

A native iOS library that provides easy-to-use Apple Pay functionality for EveryPay integration.

## Features

- Simple Apple Pay button creation with customizable styles
- Full payment flow support
- Completion handler-based async API (no delegates)
- Device capability checking
- Support for Visa and Mastercard payment networks
- [Recurring payment token support](README-RecurringToken.md) (iOS 16+)
- iOS 12.4+ compatibility

## Requirements

- iOS 12.4+
- Xcode 11.0+
- CocoaPods 1.10+

## Installation

### CocoaPods

Add the following line to your `Podfile`:

```ruby
pod 'EverypayApplePay', '~> 0.1.0'
```

Then run:

```bash
pod install
```

## Apple Pay Setup

Before using this library, you need to configure Apple Pay in your project:

### 1. Apple Developer Account Setup

1. Log in to your [Apple Developer Account](https://developer.apple.com)
2. Go to **Certificates, Identifiers & Profiles**
3. Create a **Merchant ID**:
   - Navigate to **Identifiers** → **Merchant IDs**
   - Click **+** to create a new Merchant ID
   - Enter an identifier (e.g., `merchant.com.yourcompany.app`)
   - Enter a description

### 2. EveryPay setup

When the payment processor handles decryption, they need to generate the cryptographic keys and provide the public key via a Certificate Signing Request (CSR) to the merchant. The merchant will then upload this CSR to the Apple Developer portal. In return, Apple will provide the merchant a certificate which the payment processor will need to import.

**Merchant actions:**
1. Login to the Everypay Merchant portal and open E-Shop Settings → select shop → Apple Pay (in apps). To the "Apple Pay Merchant Indentifier" field enter the identifier you created in the step 1 and register it.
2. Download the "Payment Processing Certificate CSR" from the same block.
3. Log in to the [Apple Developer Portal](https://developer.apple.com)
4. Navigate to **Certificates, Identifiers & Profiles** > **Certificates**
5. Add new certificate and select **Apple Pay Payment Processing Certificate**
6. Select the merchant ID created in the previous step ("Apple Developer Account Setup")
7. Under the *** Apple Pay Payment Processing Certificate*** click "Create Certificate" and upload the CSR file provided by Paytech/EveryPay
8. Download the generated certificate (.cer file) from Apple Developer portal
9. Upload the downloaded certificate to the Everypay Merchant portal under **E-Shop Settings** → select shop → **Apple Pay (in apps)** → **Upload Certificate**

### 3. Xcode Project Configuration

1. Open your project in Xcode
2. Select your target
3. Go to **Signing & Capabilities**
4. Click **+ Capability** and add **Apple Pay**
5. Select the Merchant ID you created

### 4. Entitlements

Xcode will automatically add the Apple Pay entitlement to your project. Verify that your entitlements file contains:

```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.yourcompany.app</string>
</array>
```

## Usage

### Import the Library

```objective-c
#import <EverypayApplePay/EverypayApplePay.h>
```

### Quick Start

The library uses a simple three-step process:

1. **Configure** - Set up payment details (amount, merchant info, etc.)
2. **Create Button** - Get an Apple Pay button to display
3. **Present Payment** - Show payment sheet and get the payment token

### Basic Example

```objective-c
#import "YourViewController.h"
#import <EverypayApplePay/EverypayApplePay.h>

@interface YourViewController ()
@property (nonatomic, strong) EPApplePayManager *applePayManager;
@end

@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize the manager
    self.applePayManager = [EPApplePayManager sharedManager];

    // Check if Apple Pay is available
    if ([self.applePayManager canMakePayments]) {
        // Step 1: Configure payment details
        [self.applePayManager configureWithAmount:[NSDecimalNumber decimalNumberWithString:@"19.99"]
                                merchantIdentifier:@"merchant.com.yourcompany.app"
                                      merchantName:@"Your Company"
                                      currencyCode:@"EUR"
                                       countryCode:@"EE"
                                        buttonType:PKPaymentButtonTypeBuy
                                       buttonStyle:PKPaymentButtonStyleBlack];

        // Step 2: Create and display the Apple Pay button
        PKPaymentButton *button = [self.applePayManager createPaymentButton];
        button.frame = CGRectMake(50, 200, 300, 50);
        [button addTarget:self
                   action:@selector(handleApplePayButtonTap)
         forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

- (void)handleApplePayButtonTap {
    // Step 3: Present payment and handle the result
    [self.applePayManager presentPaymentFromViewController:self
                                         completionHandler:^(PKPayment *payment, NSError *error) {
        if (payment) {
            // Payment successful - send token to your backend
            NSLog(@"Payment authorized!");

            // The payment token contains:
            // - payment.token.paymentData (encrypted payment data)
            // - payment.token.transactionIdentifier (unique transaction ID)
            // - payment.token.paymentMethod (payment method details)

            // Send to your backend
            [self sendPaymentTokenToBackend:payment.token];

        } else if (error) {
            // Payment failed or was cancelled
            NSLog(@"Payment error: %@", error.localizedDescription);

            // Show error to user
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Payment Error"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)sendPaymentTokenToBackend:(PKPaymentToken *)token {
    // Send the payment token to your Everypay backend
    // Example:
    // NSData *paymentData = token.paymentData;
    // NSString *transactionId = token.transactionIdentifier;
    // [YourAPI processPayment:paymentData transactionId:transactionId completion:^(BOOL success) {
    //     if (success) {
    //         [self showPaymentSuccessMessage];
    //     }
    // }];
}

@end
```

## API Reference

### EPApplePayManager

The main manager class for handling Apple Pay functionality.

#### Class Methods

```objective-c
+ (instancetype)sharedManager;
```
Returns the shared singleton instance.

#### Instance Methods

##### Check Capabilities

```objective-c
- (BOOL)canMakePayments;
```
Checks if Apple Pay is available on the device.

**Returns:** `YES` if Apple Pay is available, `NO` otherwise.

```objective-c
- (BOOL)canMakePaymentsWithNetworks:(NSArray<PKPaymentNetwork> *)networks
                       capabilities:(PKMerchantCapability)capabilities;
```
Checks if Apple Pay can make payments with specific networks and capabilities.

**Parameters:**
- `networks` - Array of payment networks (e.g., `PKPaymentNetworkVisa`)
- `capabilities` - Merchant capabilities (e.g., `PKMerchantCapability3DS`)

**Returns:** `YES` if payments can be made with specified configuration.

##### Configure Payment

```objective-c
- (void)configureWithAmount:(NSDecimalNumber *)amount
           merchantIdentifier:(NSString *)merchantId
                 merchantName:(NSString *)merchantName
                 currencyCode:(NSString *)currencyCode
                  countryCode:(NSString *)countryCode
                   buttonType:(PKPaymentButtonType)buttonType
                  buttonStyle:(PKPaymentButtonStyle)buttonStyle;
```
Configure the Apple Pay manager with merchant and payment information. Must be called before creating a button or presenting payment.

**Parameters:**
- `amount` - Payment amount as `NSDecimalNumber`
- `merchantId` - Your Apple Pay merchant identifier (e.g., "merchant.com.yourcompany.app")
- `merchantName` - Merchant display name shown to the user
- `currencyCode` - Three-letter ISO 4217 currency code (e.g., "USD", "EUR", "GBP")
- `countryCode` - Two-letter ISO 3166 country code (e.g., "US", "GB", "EE")
- `buttonType` - The button type (see available types below)
- `buttonStyle` - The button style (see available styles below)

##### Create Button

```objective-c
- (PKPaymentButton *)createPaymentButton;
```
Creates and returns an Apple Pay button configured with the settings from `configureWithAmount:...`. The button uses a default corner radius of 4.0 points.

**Returns:** Configured `PKPaymentButton` instance ready to be added to your view hierarchy.

**Note:** You must manually add a target-action to handle button taps and call `presentPaymentFromViewController:completionHandler:`.

**Available Button Types:**
- `PKPaymentButtonTypePlain`
- `PKPaymentButtonTypeBuy`
- `PKPaymentButtonTypeSetUp`
- `PKPaymentButtonTypeInStore`
- `PKPaymentButtonTypeDonate`
- `PKPaymentButtonTypeCheckout`
- `PKPaymentButtonTypeBook`
- `PKPaymentButtonTypeSubscribe`

**Available Button Styles:**
- `PKPaymentButtonStyleWhite`
- `PKPaymentButtonStyleWhiteOutline`
- `PKPaymentButtonStyleBlack`
- `PKPaymentButtonStyleAutomatic`

##### Present Payment

```objective-c
- (void)presentPaymentFromViewController:(UIViewController *)viewController
                       completionHandler:(EPApplePayCompletionHandler)completion;
```
Presents the Apple Pay payment sheet using the configured payment details.

**Parameters:**
- `viewController` - The view controller to present the payment sheet from
- `completion` - Completion handler called with the result

**Completion Handler:**
```objective-c
typedef void (^EPApplePayCompletionHandler)(PKPayment *_Nullable payment, NSError *_Nullable error);
```

The completion handler is called with one of the following:
- **Success:** `payment` contains the payment token, `error` is `nil`
- **Failure/Cancelled:** `payment` is `nil`, `error` contains the error details

**Error Codes:**
- `1000` - Manager not configured (call `configureWithAmount:...` first)
- `1001` - Unable to create payment authorization view controller
- `1002` - Payment was cancelled by the user
- `1003` - Recurring payment missing required properties

## Recurring Payment Tokens

The SDK supports requesting recurring payment tokens on iOS 16+, allowing you to save card details for future payments. When enabled, Apple Pay displays additional consent UI to the user.

For full documentation, see **[README-RecurringToken.md](README-RecurringToken.md)**.

### Quick Example

```objective-c
EPApplePayManager *manager = [EPApplePayManager sharedManager];

// Check if recurring tokens are supported
if ([manager canRequestRecurringToken]) {
    manager.requestRecurringToken = YES;
    manager.recurringPaymentDescription = @"Save card for future payments";
    manager.recurringManagementURL = [NSURL URLWithString:@"https://yourstore.com/manage"];
}
```

## Integration with React Native

This pod is designed to be consumed by a React Native library. The completion handler-based API makes it easy to bridge to React Native's promise-based architecture.

### 1. Create React Native View Manager for the Button

```objective-c
// RNApplePayButton.h
#import <React/RCTViewManager.h>

@interface RNApplePayButton : RCTViewManager
@end
```

```objective-c
// RNApplePayButton.m
#import "RNApplePayButton.h"
#import <EverypayApplePay/EverypayApplePay.h>
#import <PassKit/PassKit.h>

@implementation RNApplePayButton

RCT_EXPORT_MODULE(ApplePayButton)

- (UIView *)view {
    // Create and return the Apple Pay button
    PKPaymentButton *button = [[EPApplePayManager sharedManager] createPaymentButton];
    return button;
}

@end
```

### 2. Create React Native Module for Payment Configuration

```objective-c
// RNEverypayApplePay.h
#import <React/RCTBridgeModule.h>

@interface RNEverypayApplePay : NSObject <RCTBridgeModule>
@end
```

```objective-c
// RNEverypayApplePay.m
#import "RNEverypayApplePay.h"
#import <EverypayApplePay/EverypayApplePay.h>

@implementation RNEverypayApplePay

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(canMakePayments:(RCTPromiseResolveBlock)resolve
                         rejecter:(RCTPromiseRejectBlock)reject) {
    BOOL canMake = [[EPApplePayManager sharedManager] canMakePayments];
    resolve(@(canMake));
}

RCT_EXPORT_METHOD(configure:(NSDictionary *)config
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *amount = config[@"amount"];
    NSString *merchantId = config[@"merchantIdentifier"];
    NSString *merchantName = config[@"merchantName"];
    NSString *currencyCode = config[@"currencyCode"];
    NSString *countryCode = config[@"countryCode"];
    NSNumber *buttonType = config[@"buttonType"] ?: @(PKPaymentButtonTypeBuy);
    NSNumber *buttonStyle = config[@"buttonStyle"] ?: @(PKPaymentButtonStyleBlack);

    [[EPApplePayManager sharedManager] configureWithAmount:[NSDecimalNumber decimalNumberWithString:amount]
                                        merchantIdentifier:merchantId
                                              merchantName:merchantName
                                              currencyCode:currencyCode
                                               countryCode:countryCode
                                                buttonType:[buttonType integerValue]
                                               buttonStyle:[buttonStyle integerValue]];
    resolve(@(YES));
}

RCT_EXPORT_METHOD(presentPayment:(RCTPromiseResolveBlock)resolve
                        rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;

        [[EPApplePayManager sharedManager] presentPaymentFromViewController:rootVC
                                                          completionHandler:^(PKPayment *payment, NSError *error) {
            if (payment) {
                // Convert payment token to dictionary
                NSData *tokenData = payment.token.paymentData;
                NSString *tokenString = [tokenData base64EncodedStringWithOptions:0];
                NSDictionary *result = @{
                    @"paymentData": tokenString,
                    @"transactionIdentifier": payment.token.transactionIdentifier
                };
                resolve(result);
            } else {
                reject(@"payment_error", error.localizedDescription, error);
            }
        }];
    });
}

@end
```

### 3. React Native JavaScript Usage

```javascript
import { NativeModules, requireNativeComponent } from 'react-native';

const { RNEverypayApplePay } = NativeModules;
const ApplePayButton = requireNativeComponent('ApplePayButton');

// In your component
const handlePayment = async () => {
  try {
    // Check if Apple Pay is available
    const canMake = await RNEverypayApplePay.canMakePayments();
    if (!canMake) {
      console.log('Apple Pay not available');
      return;
    }

    // Configure payment
    await RNEverypayApplePay.configure({
      amount: '19.99',
      merchantIdentifier: 'merchant.com.yourcompany.app',
      merchantName: 'Your Company',
      currencyCode: 'USD',
      countryCode: 'US',
      buttonType: 0, // PKPaymentButtonTypeBuy
      buttonStyle: 2  // PKPaymentButtonStyleBlack
    });

    // Present payment when button is tapped
    const paymentToken = await RNEverypayApplePay.presentPayment();

    // Send token to your backend
    console.log('Payment token:', paymentToken);
  } catch (error) {
    console.error('Payment error:', error);
  }
};

// Render the button
<ApplePayButton style={{ width: 300, height: 50 }} />
```

### 4. Add to Podfile

In your React Native project's `Podfile`:

```ruby
pod 'EverypayApplePay', :path => '../path/to/EverypayApplePay'
```

## Payment Networks

This library currently supports:
- Visa (`PKPaymentNetworkVisa`)
- Mastercard (`PKPaymentNetworkMasterCard`)

Additional networks can be added by modifying the implementation in `EPApplePayManager.m:128`.

## Testing

### Simulator Testing

1. Add a test card in the Wallet app on iOS Simulator
2. Apple provides test cards for development
3. No actual charges will be made in the simulator

### Device Testing

1. Add a real payment method to your device's Wallet
2. Test in sandbox mode using your sandbox merchant ID
3. For production, use your production merchant ID

## Security Considerations

- Never log or store payment tokens
- Always process payments server-side
- Use HTTPS for all payment-related API calls
- Validate payments on your backend before fulfilling orders
- Payment data is encrypted by Apple and should only be decrypted by your payment processor

## Troubleshooting

### Apple Pay button doesn't appear

- Verify Apple Pay capability is enabled in your Xcode project
- Check that your merchant ID is properly configured
- Ensure the device supports Apple Pay
- Check that `canMakePayments` returns `YES`

### Payment sheet doesn't present

- Verify your merchant ID matches the one in your Apple Developer account
- Check that the view controller is properly presented
- Ensure payment items are not empty and have valid amounts
- Review console logs for any error messages

### "Unable to create payment authorization view controller" error

- Check that your payment request is properly configured
- Verify all required fields are set (merchant ID, currency code, country code)
- Ensure payment summary items are valid

## Example App

An example implementation is included in the `Example` folder. To run:

```bash
cd Example
pod install
open EverypayApplePay.xcworkspace
```

## License

EverypayApplePay is available under the MIT license. See the LICENSE file for more info.