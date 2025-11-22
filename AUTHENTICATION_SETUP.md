# Authentication Setup Guide

## ✅ Apple Sign In Setup (REQUIRED)

Apple Sign In is **fully implemented** and ready to use! Follow these steps to enable it:

### Step 1: Enable Sign In with Apple Capability

1. Open your project in Xcode
2. Select your app target (`scrolldeeds`)
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button
5. Search for and add **"Sign in with Apple"**

### Step 2: Apple Developer Portal Configuration

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID for `scrolldeeds`
4. Enable **"Sign in with Apple"** capability
5. Save and regenerate your provisioning profile

### Step 3: Test on Real Device

⚠️ **Important**: Apple Sign In **only works on real iOS devices**, not in the simulator!

1. Connect your iPhone
2. Select your device in Xcode
3. Build and run the app
4. Tap "Sign in with Apple" button
5. Authenticate with Face ID/Touch ID
6. ✅ You're signed in!

---

## 🔄 Google Sign In Setup (OPTIONAL - Step by Step)

Google Sign In is **prepared** but requires Firebase setup. Here's exactly what to do:

### 📋 Step-by-Step Firebase Setup (10 minutes)

#### Step 1: Create Firebase Project

1. Go to: https://console.firebase.google.com
2. Click **"Add project"** (or "Create a project")
3. Enter project name: **"ScrollDeeds"**
4. Click **Continue**
5. **Disable** Google Analytics (not needed for now)
6. Click **Create project**
7. Wait for it to finish, then click **Continue**

#### Step 2: Add iOS App to Firebase

1. In your Firebase project dashboard, click the **iOS icon** (🍎)
2. Fill in the form:
   - **Bundle ID**: `com.sabrielmakhoukhi.scrolldeeds` (or your actual bundle ID from Xcode)
   - **App nickname**: "ScrollDeeds" (optional)
   - **App Store ID**: Leave empty for now
3. Click **Register app**

#### Step 3: Download Configuration File

1. Click **"Download GoogleService-Info.plist"**
2. Save it to your Downloads folder
3. Click **Next**

#### Step 4: Add File to Xcode

1. Open Xcode
2. In the Project Navigator (left sidebar), **right-click** on the `scrolldeeds` folder
3. Choose **"Add Files to scrolldeeds..."**
4. Navigate to Downloads, select `GoogleService-Info.plist`
5. ✅ **IMPORTANT**: Check **"Copy items if needed"**
6. ✅ Make sure target **"scrolldeeds"** is selected
7. Click **Add**

#### Step 5: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **Authentication** (in left menu)
2. Click **Get started** (if first time)
3. Go to **Sign-in method** tab
4. Click on **Google** in the list
5. Toggle the **Enable** switch to ON
6. Enter **Project support email**: (your email)
7. Click **Save**

#### Step 6: Install Google Sign In SDK

**In Xcode:**

1. Go to **File** → **Add Package Dependencies...**
2. In the search bar, paste: `https://github.com/google/GoogleSignIn-iOS`
3. Click **Add Package**
4. Wait for it to load versions
5. Select version **7.0.0** or later
6. Click **Add Package** again
7. Check **"GoogleSignIn"** and **"GoogleSignInSwift"**
8. Click **Add Package**

#### Step 7: Configure Info.plist

1. In Xcode, find and open **Info.plist** file
2. Right-click in the file → **Add Row**
3. Add a new item:
   - **Key**: `GIDClientID`
   - **Type**: String
   - **Value**: (get this from `GoogleService-Info.plist`, look for `CLIENT_ID`)
4. Add another row:
   - **Key**: `CFBundleURLTypes`
   - **Type**: Array
   - Expand it → Add Item → Type: Dictionary
   - In that dictionary, add:
     - **Key**: `CFBundleURLSchemes`
     - **Type**: Array
     - Add item: (get `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`)

**Example of what to copy:**
```
Open GoogleService-Info.plist and find:
<key>CLIENT_ID</key>
<string>123456789-abcdefg.apps.googleusercontent.com</string>

<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.123456789-abcdefg</string>
```

### ⚡ Quick Alternative: Skip Google for Now!

**Don't want to deal with Firebase right now?**

Just use **Apple Sign In** (already working!) or **Email login** (already working!).

You can add Google Sign In later when you're ready. The app works perfectly without it! 🎉

---

## 📱 Current Login Options

Your app now supports **3 login methods**:

### 1. 🍎 Sign in with Apple (Ready to use!)
- Native iOS authentication
- Secure and private
- Works on all iOS 13+ devices
- **Best option for iOS users**

### 2. 📧 Sign in with Email (Working)
- Traditional email/password
- Stored locally on device
- No server required
- Good for development/testing

### 3. 🔵 Sign in with Google (Placeholder)
- Requires Firebase setup
- Popular with Android users
- Follow setup guide above to enable

---

## 🎨 Login Screen Features

- **Beautiful UI** matching your app design
- **Apple Sign In** button (black, native style)
- **Google Sign In** button (white with border)
- **Email login** expandable section
- **Smooth animations** between states

---

## 🔐 Security Notes

- All user data stored locally in **UserDefaults**
- No passwords stored (Apple/Google handle authentication)
- Email login is basic (enhance with server validation later)
- Apple Sign In provides maximum privacy

---

## 🚀 Testing

### Test Apple Sign In:
1. Use a real iPhone (not simulator!)
2. Sign out from previous Apple ID if needed
3. Tap "Sign in with Apple"
4. Use Face ID or Touch ID
5. ✅ Logged in successfully!

### Test Email Sign In:
1. Works in simulator or device
2. Tap "Sign in with Email"
3. Enter any email and password
4. ✅ Logged in successfully!

---

## ⚠️ Troubleshooting

### Apple Sign In Issues:

**"This app is not allowed to use Apple Sign In"**
- Enable capability in Xcode (Step 1 above)
- Configure App ID in Developer Portal (Step 2 above)
- Use a real device, not simulator

**"User cancelled"**
- Normal behavior if user taps cancel
- No action needed

**"Network error"**
- Check internet connection
- Try again after a few seconds

### Google Sign In Issues:

**"Not implemented yet"**
- Google Sign In is a placeholder
- Follow setup guide above to enable
- Or use Apple/Email login for now

---

## 📋 Next Steps

1. ✅ Enable Apple Sign In capability in Xcode
2. ✅ Test on a real iPhone
3. 🔵 (Optional) Set up Google Sign In with Firebase
4. 🎉 Start using your app!

---

## 💡 Tips

- **Apple Sign In** is the fastest and most secure option
- **Email login** is great for development and testing
- Users can switch between login methods
- All authentication is handled securely
- User profile shows which provider they used

Enjoy your authentication system! 🎉

