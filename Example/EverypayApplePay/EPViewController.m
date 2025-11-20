//
//  EPViewController.m
//  EverypayApplePay
//
//  Created by Märt Saarmets on 11/20/2025.
//  Copyright (c) 2025 Märt Saarmets. All rights reserved.
//

#import "EPViewController.h"
#import <EverypayApplePay/EverypayApplePay.h>

@interface EPViewController () <EPApplePayManagerDelegate>

@property (nonatomic, strong) EPApplePayManager *applePayManager;

@end

@implementation EPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Initialize Apple Pay Manager
    self.applePayManager = [EPApplePayManager sharedManager];
    self.applePayManager.delegate = self;

    // Set background color
    self.view.backgroundColor = [UIColor whiteColor];

    // Check if Apple Pay is available
    if ([self.applePayManager canMakePayments]) {
        // Create Apple Pay button
        PKPaymentButton *applePayButton = [self.applePayManager createPaymentButtonWithType:PKPaymentButtonTypeBuy
                                                                                      style:PKPaymentButtonStyleBlack
                                                                                     corner:8.0];

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

#pragma mark - EPApplePayManagerDelegate

- (void)applePayButtonTapped {
    NSLog(@"Apple Pay button tapped");

    // This is where you would present the payment sheet
    // For this basic example, we just log the tap
    // In a real implementation, you would call presentApplePayWithMerchantIdentifier:

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Apple Pay"
                                                                   message:@"Button tapped! In a real app, this would present the payment sheet."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applePayPaymentAuthorized:(PKPayment *)payment {
    NSLog(@"Payment authorized: %@", payment.token.transactionIdentifier);
}

- (void)applePayPaymentFailed:(NSError *)error {
    NSLog(@"Payment failed: %@", error.localizedDescription);
}

- (void)applePayPaymentCancelled {
    NSLog(@"Payment cancelled by user");
}

@end
