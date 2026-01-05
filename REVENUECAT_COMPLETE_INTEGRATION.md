# Complete RevenueCat Integration Guide - ScrollDeeds

## 📋 Overview

This guide provides a complete, production-ready RevenueCat integration for ScrollDeeds using SwiftUI and Swift Package Manager.

---

## ✅ Step 1: Install RevenueCat SDK

### In Xcode:

1. **Open your project** (`scrolldeeds.xcodeproj`)

2. **Add Swift Package:**
   - Click on your project in the navigator (top)
   - Select target: `scrolldeeds`
   - Go to tab: **"Package Dependencies"**
   - Click **"+"** button (bottom left)

3. **Add RevenueCat:**
   - Paste this URL:
     ```
     https://github.com/RevenueCat/purchases-ios-spm.git
     ```
   - Click **"Add Package"**
   - Select **"RevenueCat"** (not RevenueCatHybrid)
   - Ensure **"scrolldeeds"** target is checked
   - Click **"Add Package"**

4. **Verify:**
   - Check that `RevenueCat` appears under "Package Dependencies"
   - ✅ Installation complete!

---

## ✅ Step 2: Configure RevenueCat

### API Key Setup

The API key is already configured in `scrolldeedsApp.swift`:

```swift
let revenueCatAPIKey = "test_RtMCUxaPxJRUnsyRrYNIdJBZOjW"
Purchases.configure(withAPIKey: revenueCatAPIKey)
```

**For Production:**
- Replace with production key: `pk_live_...`
- Change log level: `Purchases.logLevel = .info` or `.warn`

---

## ✅ Step 3: Configure Products in RevenueCat Dashboard

### 3.1 Create Products

1. Go to [app.revenuecat.com](https://app.revenuecat.com)
2. Select project: **Scrolldeeds**
3. Navigate to **Product catalog** → **Products**
4. Click **"+ New"** or **"New product"**

**Product 1: Monthly**
- **Product ID:** `com.scrolldeeds.premium.monthly`
- **Store Product ID:** `com.scrolldeeds.premium.monthly` (must match App Store Connect exactly!)
- **Type:** `Subscription`
- **Store:** `Apple App Store`
- Click **"Save"**

**Product 2: Yearly**
- **Product ID:** `com.scrolldeeds.premium.yearly`
- **Store Product ID:** `com.scrolldeeds.premium.yearly`
- **Type:** `Subscription`
- **Store:** `Apple App Store`
- Click **"Save"**

### 3.2 Create Entitlement

1. Go to **"Entitlements"** tab
2. Click **"+ New"** or **"New entitlement"**
3. **Entitlement ID:** `Scrolldeeds Pro` (must match code exactly!)
4. **Description:** `Premium access to all ScrollDeeds features`
5. **Link Products:**
   - Add `com.scrolldeeds.premium.monthly`
   - Add `com.scrolldeeds.premium.yearly`
6. Click **"Save"**

### 3.3 Create Offering (Recommended)

1. Go to **"Offerings"** tab
2. Click **"+ New"** or **"New offering"**
3. **Offering ID:** `default` (or leave empty for default)
4. **Description:** `Default offering for ScrollDeeds`
5. **Add Packages:**
   - Add `com.scrolldeeds.premium.monthly`
   - Add `com.scrolldeeds.premium.yearly`
6. Click **"Save"**

---

## ✅ Step 4: Code Implementation

### Files Created/Updated:

1. **`scrolldeedsApp.swift`** - RevenueCat initialization ✅
2. **`SubscriptionManager.swift`** - Subscription management ✅
3. **`RevenueCatDelegate.swift`** - Delegate for customer info updates ✅
4. **`PaywallView.swift`** - Paywall UI ✅
5. **`CustomerCenterView.swift`** - Customer center for managing subscriptions ✅

### Key Features:

#### SubscriptionManager
- ✅ Entitlement checking for "Scrolldeeds Pro"
- ✅ Customer info retrieval
- ✅ Purchase handling
- ✅ Restore purchases
- ✅ Error handling
- ✅ Observable properties for SwiftUI

#### PaywallView
- ✅ Displays available packages
- ✅ Purchase flow
- ✅ Error handling
- ✅ Loading states

#### CustomerCenterView
- ✅ View subscription status
- ✅ Restore purchases
- ✅ Link to App Store subscription management
- ✅ Debug info (in DEBUG builds)

---

## ✅ Step 5: Usage in Your App

### Check Premium Status

```swift
@StateObject private var subscriptionManager = SubscriptionManager.shared

// Check if user is premium
if subscriptionManager.isPremium {
    // Show premium features
} else {
    // Show paywall
}
```

### Show Paywall

```swift
@State private var showPaywall = false

.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

### Show Customer Center

```swift
@State private var showCustomerCenter = false

.sheet(isPresented: $showCustomerCenter) {
    CustomerCenterView()
}
```

### Load Offerings

```swift
Task {
    await subscriptionManager.loadOfferings()
}
```

### Purchase Package

```swift
if let package = selectedPackage {
    do {
        try await subscriptionManager.purchase(package)
        // Purchase successful
    } catch {
        // Handle error
    }
}
```

### Restore Purchases

```swift
Task {
    await subscriptionManager.restorePurchases()
}
```

### Get Customer Info

```swift
do {
    let customerInfo = try await subscriptionManager.getCustomerInfo()
    // Use customer info
} catch {
    // Handle error
}
```

---

## ✅ Step 6: App Store Connect Setup

**Important:** Products must also be configured in App Store Connect!

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app: **ScrollDeeds**
3. Go to **"Features"** → **"In-App Purchases"**
4. Create subscriptions:
   - `com.scrolldeeds.premium.monthly`
   - `com.scrolldeeds.premium.yearly`
5. Configure pricing, descriptions, etc.

**Product IDs must match exactly:**
- ✅ App Store Connect: `com.scrolldeeds.premium.monthly`
- ✅ RevenueCat: `com.scrolldeeds.premium.monthly`
- ✅ Your code: `com.scrolldeeds.premium.monthly`

---

## ✅ Step 7: Testing

### Sandbox Testing

1. **Create Sandbox Tester:**
   - App Store Connect → Users and Access → Sandbox Testers
   - Create test account

2. **Test in Simulator/Device:**
   - Sign out of real Apple ID
   - Run app
   - When prompted, sign in with sandbox account
   - Test purchase flow

3. **Verify in RevenueCat:**
   - Dashboard → Customers
   - Check test purchases appear
   - Verify entitlement status

### Debug Logging

RevenueCat logs are enabled in debug mode:
```swift
Purchases.logLevel = .debug // In scrolldeedsApp.swift
```

Check Xcode console for:
- `✅ RevenueCat initialized`
- `✅ Loaded offerings`
- `📊 Premium status: Active/Inactive`
- `✅ Purchase successful`

---

## 🎯 Best Practices

### 1. Error Handling

Always handle errors gracefully:

```swift
do {
    try await subscriptionManager.purchase(package)
} catch SubscriptionError.userCancelled {
    // User cancelled - don't show error
} catch {
    // Show error to user
    showError = true
    errorMessage = error.localizedDescription
}
```

### 2. Loading States

Show loading indicators during async operations:

```swift
if subscriptionManager.isLoading {
    ProgressView()
} else {
    // Content
}
```

### 3. Check Premium Status

Check premium status when app launches and after purchases:

```swift
.onAppear {
    subscriptionManager.checkPremiumStatus()
}
```

### 4. Listen for Updates

The `RevenueCatDelegate` automatically updates subscription status when:
- Purchase completes
- Subscription renews
- Subscription expires
- User restores purchases

### 5. Customer Info

Store customer info for offline access:

```swift
@Published var customerInfo: CustomerInfo?
```

---

## 🔒 Security

### API Keys

- **Test Key:** `test_...` (for development)
- **Production Key:** `pk_live_...` (for App Store)

**Never commit API keys to version control!**

Consider using:
- Environment variables
- Configuration files (excluded from git)
- Build configuration

---

## 📊 Analytics

RevenueCat provides built-in analytics:

1. **Dashboard:**
   - Revenue metrics
   - Subscription status
   - Customer lifetime value

2. **Webhooks:**
   - Configure in RevenueCat dashboard
   - Get real-time purchase notifications
   - Integrate with your backend

---

## 🆘 Troubleshooting

### SDK Not Found

**Solution:**
- Clean build folder: `Product → Clean Build Folder` (Cmd+Shift+K)
- Rebuild: `Product → Build` (Cmd+B)
- Verify package is added correctly

### Products Not Loading

**Check:**
- Product IDs match exactly (App Store Connect, RevenueCat, code)
- Products are approved in App Store Connect
- Offering is configured in RevenueCat
- Network connection is available

### Purchase Fails

**Check:**
- Sandbox account is signed in
- Product is available in App Store Connect
- Entitlement is configured correctly
- Check Xcode console for errors

### Premium Status Not Updating

**Solution:**
- Check entitlement ID matches: `"Scrolldeeds Pro"`
- Verify customer info is loaded
- Check RevenueCat dashboard for subscription status

---

## 📚 Additional Resources

- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [iOS Integration Guide](https://www.revenuecat.com/docs/getting-started/installation/ios)
- [Paywalls Guide](https://www.revenuecat.com/docs/tools/paywalls)
- [Customer Center](https://www.revenuecat.com/docs/tools/customer-center)
- [RevenueCat Dashboard](https://app.revenuecat.com)

---

## ✅ Checklist

- [ ] RevenueCat SDK installed via Swift Package Manager
- [ ] API key configured (test key for now)
- [ ] Products created in RevenueCat dashboard
- [ ] Entitlement "Scrolldeeds Pro" created
- [ ] Offering configured
- [ ] Products created in App Store Connect
- [ ] Code implementation complete
- [ ] Paywall integrated
- [ ] Customer Center integrated
- [ ] Error handling implemented
- [ ] Tested with sandbox account
- [ ] Ready for production (switch to production API key)

---

**Your RevenueCat integration is complete! 🎉**

For questions or issues, check the RevenueCat documentation or contact support.

