# Backend API Integration Guide

This document explains how to set up your backend server to work with the EveryPay Apple Pay iOS SDK. The SDK requires backend API calls to initialize payments and process Apple Pay tokens.

## Overview

The Apple Pay payment flow involves three main steps:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │     │   Your Backend  │     │   EveryPay API  │
│   (SDK)         │     │   Server        │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │  1. Init Payment      │                       │
         │──────────────────────>│                       │
         │                       │  2. Create Payment    │
         │                       │──────────────────────>│
         │                       │<──────────────────────│
         │<──────────────────────│                       │
         │  (paymentReference,   │                       │
         │   mobileAccessToken)  │                       │
         │                       │                       │
         │  3. User authorizes   │                       │
         │     via Apple Pay     │                       │
         │                       │                       │
         │  4. Process Token     │                       │
         │──────────────────────>│                       │
         │   (paymentData)       │  5. Send Token        │
         │                       │──────────────────────>│
         │                       │<──────────────────────│
         │<──────────────────────│                       │
         │  (payment state)      │                       │
         │                       │                       │
```

## EveryPay API Credentials

Before implementing the backend, you'll need EveryPay API credentials:

| Credential | Description | Example |
|------------|-------------|---------|
| `api_username` | Your API username | `123abc` |
| `api_secret` | Your API secret key | `123abcabc123` |
| `account_name` | Your account name | `EUR3D1` |
| `api_url` | EveryPay API base URL | `https://payment.sandbox.lhv.ee` (sandbox) |


## Required Backend Endpoints

Your backend needs to implement two endpoints:

### 1. Initialize Payment Endpoint

**Purpose:** Creates a payment in EveryPay and returns the data needed by the iOS SDK.

**Endpoint:** `POST /api/oneoff` (or your preferred path)

#### Request from iOS App

```json
{
  "amount": "19.99",
  "orderReference": "ORDER-12345",
  "customerEmail": "customer@example.com",
  "label": "Product Purchase"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `amount` | string | No | Payment amount (defaults to 0.01 if not provided) |
| `orderReference` | string | Yes | Unique order reference for this payment |
| `customerEmail` | string | Yes | Customer's email address |
| `label` | string | No | Description shown in Apple Pay sheet |

#### Backend Implementation

Your backend should call the EveryPay **create payment** API:

```
POST {api_url}/api/v4/payments/oneoff
Authorization: Basic {base64(api_username:api_secret)}
Content-Type: application/json
```

**Request Body:**

```json
{
  "api_username": "your_api_username",
  "account_name": "your_account_name",
  "amount": 19.99,
  "label": "Product Purchase",
  "currency_code": "EUR",
  "country_code": "EE",
  "order_reference": "ORDER-12345",
  "nonce": "unique-uuid-v4",
  "mobile_payment": true,
  "customer_url": "https://yoursite.com",
  "customer_ip": "192.168.1.1",
  "customer_email": "customer@example.com",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

**EveryPay Response:**

```json
{
  "payment_reference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "mobile_access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "standing_amount": 19.99,
  "currency": "EUR",
  "descriptor_country": "EE",
  "label": "Product Purchase"
}
```

#### Response to iOS App

Return the following JSON to the iOS app:

```json
{
  "amount": 19.99,
  "paymentReference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "mobileAccessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "currency": "EUR",
  "countryCode": "EE",
  "label": "Product Purchase"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `amount` | number | The payment amount |
| `paymentReference` | string | EveryPay payment reference (used in processing) |
| `mobileAccessToken` | string | JWT token for authenticating the process request |
| `currency` | string | Currency code |
| `countryCode` | string | Country code |
| `label` | string | Payment description |

---

### 2. Process Payment Endpoint

**Purpose:** Receives the Apple Pay token from the iOS app and sends it to EveryPay for processing.

**Endpoint:** `POST /api/apple-pay/process` (or your preferred path)

#### Request from iOS App

```json
{
  "payment_reference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "mobile_access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "paymentData": {
    "data": "encrypted_payment_data_base64...",
    "signature": "signature_base64...",
    "header": {
      "ephemeralPublicKey": "public_key_base64...",
      "publicKeyHash": "hash_base64...",
      "transactionId": "transaction_id_hex..."
    },
    "version": "EC_v1"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `payment_reference` | string | Payment reference from init response |
| `mobile_access_token` | string | Access token from init response |
| `paymentData` | object | The Apple Pay payment token (from `PKPayment.token.paymentData`) |

#### Backend Implementation

Your backend should call the EveryPay **Apple Pay payment data** API:

```
POST {api_url}/api/v4/apple_pay/payment_data
Authorization: Bearer {mobile_access_token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "payment_reference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "ios_app": true,
  "paymentData": {
    "data": "encrypted_payment_data_base64...",
    "signature": "signature_base64...",
    "header": {
      "ephemeralPublicKey": "public_key_base64...",
      "publicKeyHash": "hash_base64...",
      "transactionId": "transaction_id_hex..."
    },
    "version": "EC_v1"
  }
}
```

**EveryPay Response:**

```json
{
  "payment_reference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "order_reference": "ORDER-12345",
  "state": "settled"
}
```

#### Response to iOS App

```json
{
  "state": "settled",
  "paymentReference": "fd0adc28d5e34f95cddb1b91f57ed4f33b7c90a1",
  "orderReference": "ORDER-12345"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `state` | string | Payment state: `settled`, `authorized`, `failed`, etc. |
| `paymentReference` | string | The payment reference |
| `orderReference` | string | Your original order reference |

---

## Recurring Token Request (Optional)

For saving card details for future payments (MIT - Merchant Initiated Transactions):

### Initialize Token Request Endpoint

**Endpoint:** `POST /api/google-pay/init-token` (same endpoint works for Apple Pay)

This creates a zero-amount payment with token flags:

```json
{
  "api_username": "your_api_username",
  "account_name": "your_account_name",
  "amount": 0,
  "label": "Card verification",
  "currency_code": "EUR",
  "country_code": "EE",
  "order_reference": "TOKEN-REQUEST-12345",
  "nonce": "unique-uuid-v4",
  "mobile_payment": true,
  "customer_url": "https://yoursite.com",
  "customer_ip": "192.168.1.1",
  "customer_email": "",
  "timestamp": "2025-01-15T10:30:00Z",
  "request_token": true,
  "token_consent_agreed": true,
  "token_agreement": "unscheduled"
}
```

Key differences:
- `amount`: Set to `0` for token requests
- `request_token`: Set to `true`
- `token_consent_agreed`: Set to `true`
- `token_agreement`: Set to `"unscheduled"` for MIT tokens

### Retrieve MIT Token

After processing, retrieve the MIT token from payment details:

```
GET {api_url}/api/v4/payments/{payment_reference}?api_username={api_username}
Authorization: Basic {base64(api_username:api_secret)}
```

The MIT token is in `cc_details.token` in the response.

---

## Example Backend Implementation (Node.js)

Here's a reference implementation for a Node.js backend:

```javascript
const http = require('http');
const https = require('https');
const { URL } = require('url');

// Configuration
const EVERYPAY_CONFIG = {
    apiUsername: 'your_api_username',
    apiSecret: 'your_api_secret',
    apiUrl: 'https://payment.sandbox.lhv.ee',
    accountName: 'EUR3D1',
    customerUrl: 'https://yoursite.com'
};

// Helper: Create Basic Auth header
function createBasicAuthHeader(username, password) {
    const credentials = `${username}:${password}`;
    return `Basic ${Buffer.from(credentials).toString('base64')}`;
}

// Helper: Generate UUID v4
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Helper: Get current timestamp
function getCurrentTimestamp() {
    return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

// Helper: Make HTTPS request
function makeHttpsRequest(url, method, headers, body) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const options = {
            hostname: urlObj.hostname,
            port: urlObj.port || 443,
            path: urlObj.pathname + urlObj.search,
            method: method,
            headers: headers
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(new Error(`Failed to parse response: ${e.message}`));
                    }
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

// Create Payment (for /api/oneoff endpoint)
async function createPayment(amount, label, orderReference, customerEmail) {
    const url = `${EVERYPAY_CONFIG.apiUrl}/api/v4/payments/oneoff`;
    const headers = {
        'Authorization': createBasicAuthHeader(EVERYPAY_CONFIG.apiUsername, EVERYPAY_CONFIG.apiSecret),
        'Content-Type': 'application/json'
    };
    const body = {
        api_username: EVERYPAY_CONFIG.apiUsername,
        account_name: EVERYPAY_CONFIG.accountName,
        amount: parseFloat(amount),
        label: label,
        currency_code: 'EUR',
        country_code: 'EE',
        order_reference: orderReference,
        nonce: generateUUID(),
        mobile_payment: true,
        customer_url: EVERYPAY_CONFIG.customerUrl,
        customer_ip: '192.168.1.1',
        customer_email: customerEmail,
        timestamp: getCurrentTimestamp()
    };

    return await makeHttpsRequest(url, 'POST', headers, body);
}

// Process Apple Pay Payment (for /api/apple-pay/process endpoint)
async function processApplePayPayment(paymentReference, mobileAccessToken, paymentData) {
    const url = `${EVERYPAY_CONFIG.apiUrl}/api/v4/apple_pay/payment_data`;
    const headers = {
        'Authorization': `Bearer ${mobileAccessToken}`,
        'Content-Type': 'application/json'
    };
    const body = {
        payment_reference: paymentReference,
        ios_app: true,
        paymentData: paymentData
    };

    return await makeHttpsRequest(url, 'POST', headers, body);
}

// Express.js route handlers example:
//
// app.post('/api/oneoff', async (req, res) => {
//     const { amount, orderReference, customerEmail, label } = req.body;
//     const paymentResponse = await createPayment(amount || '0.01', label || 'Purchase', orderReference, customerEmail);
//     res.json({
//         amount: paymentResponse.standing_amount,
//         paymentReference: paymentResponse.payment_reference,
//         mobileAccessToken: paymentResponse.mobile_access_token,
//         currency: paymentResponse.currency,
//         countryCode: paymentResponse.descriptor_country,
//         label: paymentResponse.label
//     });
// });
//
// app.post('/api/apple-pay/process', async (req, res) => {
//     const { payment_reference, mobile_access_token, paymentData } = req.body;
//     const processResponse = await processApplePayPayment(payment_reference, mobile_access_token, paymentData);
//     res.json({
//         state: processResponse.state,
//         paymentReference: processResponse.payment_reference,
//         orderReference: processResponse.order_reference
//     });
// });
```

---

## iOS App Integration

After implementing the backend, integrate with the iOS SDK:

### 1. Initialize Payment

```swift
// Call your backend to initialize payment
func initializePayment() async throws -> InitPaymentResponse {
    let url = URL(string: "https://your-backend.com/api/oneoff")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "amount": "19.99",
        "orderReference": UUID().uuidString,
        "customerEmail": "customer@example.com",
        "label": "Product Purchase"
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(InitPaymentResponse.self, from: data)
}
```

### 2. Configure SDK with Backend Response

```swift
// After receiving backend response, configure the SDK
let initResponse = try await initializePayment()

let manager = EPApplePayManager.shared()
manager.configure(
    with: NSDecimalNumber(string: "\(initResponse.amount)"),
    merchantIdentifier: "merchant.your.identifier",
    merchantName: "Your Store",
    currencyCode: initResponse.currency,
    countryCode: initResponse.countryCode,
    buttonType: .buy,
    buttonStyle: .black
)

// Store these for later use
self.paymentReference = initResponse.paymentReference
self.mobileAccessToken = initResponse.mobileAccessToken
```

### 3. Process Apple Pay Token

```swift
// After user authorizes payment
manager.presentPayment(from: self) { [weak self] payment, error in
    guard let payment = payment else { return }

    Task {
        await self?.processPaymentToken(payment: payment)
    }
}

func processPaymentToken(payment: PKPayment) async {
    let paymentData = payment.token.paymentData
    guard let paymentDataJSON = try? JSONSerialization.jsonObject(with: paymentData) as? [String: Any] else {
        return
    }

    // Send to your backend
    let url = URL(string: "https://your-backend.com/api/apple-pay/process")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "payment_reference": paymentReference,
        "mobile_access_token": mobileAccessToken,
        "paymentData": paymentDataJSON
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(ProcessPaymentResponse.self, from: data)

    if response.state == "settled" || response.state == "authorized" {
        // Payment successful
    }
}
```

---

## Payment States

| State | Description |
|-------|-------------|
| `settled` | Payment completed successfully |
| `authorized` | Payment authorized, pending capture |
| `failed` | Payment failed |
| `cancelled` | Payment was cancelled |
| `waiting_for_3ds_response` | 3DS authentication required |

---

## Security Best Practices

1. **Never expose API credentials** - Keep `api_username` and `api_secret` server-side only
2. **Use HTTPS** - All communication should be over HTTPS
3. **Validate inputs** - Sanitize all inputs from the iOS app
4. **Log securely** - Never log payment tokens or sensitive data
5. **Use unique order references** - Prevent duplicate payments
6. **Verify payment states** - Always check the final payment state before fulfilling orders

---

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `401 Unauthorized` | Invalid API credentials | Check `api_username` and `api_secret` |
| `Invalid payment_reference` | Reference not found or expired | Ensure payment was initialized first |
| `Invalid mobile_access_token` | Token expired or invalid | Re-initialize the payment |
| `Payment already processed` | Duplicate processing attempt | Use idempotency keys |

### Testing

1. Use the EveryPay sandbox environment for testing
2. Test cards are available in the EveryPay documentation
3. Monitor the EveryPay merchant portal for payment status

---

## Related Documentation

- [EveryPay API Documentation](https://support.every-pay.com)
- [Main SDK README](README.md)
- [Recurring Token Documentation](README-RecurringToken.md)
