//
//  EPViewController.m
//  EverypayApplePay
//
//  Created by Märt Saarmets on 11/20/2025.
//  Copyright (c) 2025 Märt Saarmets. All rights reserved.
//

#import "EPViewController.h"
#import <EverypayApplePay/EverypayApplePay.h>

@interface EPViewController ()

@property (nonatomic, strong) EPApplePayManager *applePayManager;

@end

@implementation EPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Initialize Apple Pay Manager
    self.applePayManager = [EPApplePayManager sharedManager];

    // Set background color
    self.view.backgroundColor = [UIColor whiteColor];

    // Check if Apple Pay is available
    if ([self.applePayManager canMakePayments]) {
        // Configure payment details (Step 1)
        [self.applePayManager configureWithAmount:[NSDecimalNumber decimalNumberWithString:@"19.99"]
                                merchantIdentifier:@"merchant.com.everypay.example"
                                      merchantName:@"EveryPay Example Store"
                                      currencyCode:@"USD"
                                       countryCode:@"US"
                                        buttonType:PKPaymentButtonTypeBuy
                                       buttonStyle:PKPaymentButtonStyleBlack];

        // Enable recurring token if supported (iOS 16+)
        if ([self.applePayManager canRequestRecurringToken]) {
            self.applePayManager.requestRecurringToken = YES;
            NSLog(@"Recurring payment token enabled");
        } else {
            NSLog(@"Recurring payment token not supported on this iOS version");
        }

        // Create Apple Pay button (Step 2)
        PKPaymentButton *applePayButton = [self.applePayManager createPaymentButton];

        // Configure button frame
        CGFloat buttonWidth = 280;
        CGFloat buttonHeight = 50;
        CGFloat buttonX = (self.view.bounds.size.width - buttonWidth) / 2;
        CGFloat buttonY = (self.view.bounds.size.height - buttonHeight) / 2;

        applePayButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        applePayButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleRightMargin;

        // Add tap handler
        [applePayButton addTarget:self
                           action:@selector(handleApplePayButtonTap)
                 forControlEvents:UIControlEventTouchUpInside];

        // Add button to view
        [self.view addSubview:applePayButton];

        // Add label above button
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, buttonY - 60, self.view.bounds.size.width, 40)];
        label.text = @"Apple Pay Example";
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
        label.textColor = [UIColor blackColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                  UIViewAutoresizingFlexibleBottomMargin |
                                  UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:label];

        // Add info label below button
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, buttonY + buttonHeight + 20,
                                                                        self.view.bounds.size.width - 40, 80)];
        NSString *recurringInfo = [self.applePayManager canRequestRecurringToken] ? @"\nRecurring token: Enabled" : @"\nRecurring token: Not supported";
        infoLabel.text = [NSString stringWithFormat:@"Tap the button to see the Apple Pay sheet.\n\nAmount: $19.99%@", recurringInfo];
        infoLabel.numberOfLines = 0;
        infoLabel.textAlignment = NSTextAlignmentCenter;
        infoLabel.font = [UIFont systemFontOfSize:14];
        infoLabel.textColor = [UIColor grayColor];
        infoLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                      UIViewAutoresizingFlexibleBottomMargin |
                                      UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:infoLabel];
    } else {
        // Apple Pay not available
        UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.bounds.size.width - 40, 100)];
        errorLabel.center = self.view.center;
        errorLabel.numberOfLines = 0;
        errorLabel.text = @"Apple Pay is not available on this device";
        errorLabel.textAlignment = NSTextAlignmentCenter;
        errorLabel.font = [UIFont systemFontOfSize:16];
        errorLabel.textColor = [UIColor darkGrayColor];
        errorLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:errorLabel];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Apple Pay Button Handler

- (void)handleApplePayButtonTap {
    NSLog(@"Apple Pay button tapped - presenting payment sheet");

    // Present payment and handle result (Step 3)
    [self.applePayManager presentPaymentFromViewController:self
                                         completionHandler:^(PKPayment *payment, NSError *error) {
        if (payment) {
            // Payment successful
            NSLog(@"Payment authorized!");
            NSLog(@"Transaction ID: %@", payment.token.transactionIdentifier);

            // In a real app, you would send payment.token to your backend
            [self showSuccessAlert:payment];
        } else if (error) {
            // Payment failed or cancelled
            NSLog(@"Payment error: %@", error.localizedDescription);
            [self showErrorAlert:error];
        }
    }];
}

#pragma mark - Helper Methods

- (void)showSuccessAlert:(PKPayment *)payment {
    NSString *message = [NSString stringWithFormat:@"Payment token received!\n\nTransaction ID:\n%@\n\nIn a real app, you would send this token to your backend for processing.",
                        payment.token.transactionIdentifier];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Payment Successful"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showErrorAlert:(NSError *)error {
    NSString *title = @"Payment Error";
    NSString *message = error.localizedDescription;

    // Check if it was a cancellation
    if (error.code == 1002) {
        title = @"Payment Cancelled";
        message = @"You cancelled the payment.";
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
