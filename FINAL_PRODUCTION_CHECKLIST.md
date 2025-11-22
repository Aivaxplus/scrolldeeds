# ScrollDeeds - Final Production Checklist 🚀

---

## 🎯 **QUICK STATUS OVERVIEW**

### **✅ DONE:**
- [x] Local-only architecture (no cloud dependencies)
- [x] Family Controls integration
- [x] Shield persistence (apps stay locked after restart)
- [x] Unlock timer persistence (survives app close)
- [x] Background shield reapplication (works even when app closed!)
- [x] Named ManagedSettingsStore (persistent across launches)
- [x] Auto-relock when timer expires (applies on next ScrollDeeds open)
- [x] Splash screen
- [x] Recurring notifications
- [x] App icon
- [x] Bundle ID: `com.scrolldeeds.app`
- [x] Production timing: 15 minutes unlock period

### **⚠️ CRITICAL - DO BEFORE APP STORE:**
- [ ] **Family Controls Distribution Approval** (request from Apple, 1-2 weeks)
- [ ] **Privacy Policy page** (required for App Store)
- [ ] **Terms of Service page** (required for App Store)
- [ ] **Info.plist descriptions** (NSFamilyControlsUsageDescription, etc.)

### **📊 OPTIONAL - ANALYTICS (Post-Launch):**
- [ ] **TelemetryDeck integration** (privacy-first analytics)
  - Track: user count, onboarding completion, retention
  - 100% anonymous, no personal data
  - Free tier: 100k events/month
  - Setup time: 10 minutes
  - **Recommended:** Wait until after first App Store approval

---

## ✅ **1. FIREBASE SECURITY RULES (CRITICAL!)**

⚠️ **NOTE:** Firebase has been removed from this app. This section is deprecated.

### Go to Firebase Console NOW:
```
https://console.firebase.google.com
```

### Update Rules:
1. Select "scrolldeeds" project
2. Click "Firestore Database" (left sidebar)
3. Click "Rules" tab
4. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false;  // Never delete users
    }
    
    // Progress collection
    match /progress/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false;  // Keep progress history
    }
    
    // Block everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

5. Click **"Publish"**

---

## ✅ **2. APP CONFIGURATION**

### Bundle Identifier:
- **Current:** `com.yourname.scrolldeeds`
- **Update to:** `com.[YOUR_COMPANY].scrolldeeds`

**How to change:**
1. Open project in Xcode
2. Select project name (top left)
3. Select target "scrolldeeds"
4. General tab → Bundle Identifier
5. Change to your company name

---

## ✅ **3. APP ICONS (REQUIRED)**

### Create 1024x1024 icon:
**Design Guidelines:**
- Green/Gold color scheme
- Crescent moon + sparkles
- Simple, recognizable
- No text

**Tools:**
- Figma / Canva / Sketch
- Or use: https://icon.kitchen/

**Add to Xcode:**
1. Open Assets.xcassets
2. Click AppIcon
3. Drag 1024x1024 PNG
4. Xcode auto-generates all sizes

---

## ✅ **4. SIGNING & CAPABILITIES**

### Apple Developer Account:
1. Sign up at: https://developer.apple.com
2. Cost: $99/year

### In Xcode:
1. Select project → Signing & Capabilities
2. Team → Select your account
3. Signing → Automatic
4. Ensure all capabilities enabled:
   - ✅ Family Controls
   - ✅ Push Notifications (future)

---

## ✅ **5. PRIVACY POLICY (REQUIRED)**

### Must Include:
- Microphone usage (for dhikr recording)
- Screen Time data access
- Firebase data storage
- No data sharing with third parties

### Create:
1. Use generator: https://app-privacy-policy-generator.firebaseapp.com/
2. Host on: GitHub Pages / Notion / Your website
3. Get URL

### Add to App Store Connect:
- Privacy Policy URL field (required)

---

## ✅ **6. APP STORE CONNECT**

### Create App:
1. Go to: https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill in:
   - **Name:** ScrollDeeds
   - **Primary Language:** Dutch / English
   - **Bundle ID:** (your bundle ID)
   - **SKU:** scrolldeeds-app-001
   - **User Access:** Full Access

### App Information:
- **Category:** Lifestyle
- **Sub-Category:** Health & Fitness
- **Age Rating:** 4+
- **Price:** Free (with future in-app purchases option)

---

## ✅ **7. APP STORE SCREENSHOTS**

### Required Sizes:
- **6.7" (iPhone 15 Pro Max):** 1290 x 2796
- **6.5" (iPhone 14 Plus):** 1284 x 2778
- **5.5" (iPhone 8 Plus):** 1242 x 2208

### Screens to Screenshot:
1. Onboarding screen (with badges)
2. Questionnaire (with green/gold UI)
3. Dashboard (showing locked/unlocked status)
4. Dhikr session screen
5. Progress view (with charts)
6. Settings page

**Use iPhone Simulator in Xcode for perfect screenshots!**

---

## ✅ **8. APP DESCRIPTION**

### Title (30 chars):
```
ScrollDeeds - Islamic Focus
```

### Subtitle (30 chars):
```
Stop Doomscrolling with Dhikr
```

### Description:
```
Transform mindless scrolling into mindful living.

ScrollDeeds helps Muslims break free from doomscrolling by combining app management with spiritual practice.

HOW IT WORKS:
🔒 Lock distracting apps
✨ Unlock by reciting dhikr or making dua
⏱️ Get 15 minutes of mindful access
📊 Track your progress and build streaks

FEATURES:
• AI-verified dhikr recitation
• Customizable app locking
• Beautiful progress tracking
• Dark mode default
• Cloud sync across devices
• No ads, no tracking

Perfect for Muslims who want to:
- Reduce screen time
- Increase dhikr in daily life
- Build better digital habits
- Stay focused on what matters

Start your journey to mindful phone usage today.
```

### Keywords (100 chars):
```
muslim,islam,dhikr,focus,productivity,screen time,mindful,dua,spiritual,habit,lock,alhamdulillah
```

---

## ✅ **9. FAMILY CONTROLS ENTITLEMENT**

### Request from Apple:
1. Go to: https://developer.apple.com/contact/request/family-controls-distribution/
2. Fill out form:
   - **App Name:** ScrollDeeds
   - **Bundle ID:** com.[company].scrolldeeds
   - **Use Case:** "Islamic productivity app that helps Muslims reduce doomscrolling by requiring dhikr recitation to unlock social media apps. Educational and spiritual growth focused."
3. Submit
4. Wait 1-2 weeks for approval

**Note:** You can develop and test without this, but need it for App Store release.

---

## ✅ **10. TESTING**

### TestFlight Beta:
1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Add beta testers (up to 10,000)
4. Test for 1-2 weeks
5. Fix bugs, gather feedback

### Test Checklist:
- ✅ Onboarding flow (all 4 questions)
- ✅ App selection (multiple apps)
- ✅ Login (Apple ID + Email)
- ✅ Quick guide (shows for new users)
- ✅ Dhikr recording + AI verification
- ✅ 15-minute timer (countdown works)
- ✅ Auto re-lock after timer
- ✅ Progress tracking (charts update)
- ✅ Settings (dark/light mode toggle)
- ✅ Logout/login (data persists)
- ✅ Multiple users (separate data)
- ✅ Firebase sync (data in cloud)

---

## ✅ **11. APP REVIEW PREPARATION**

### Notes for Reviewer:
```
TEST ACCOUNT:
Email: reviewer@scrolldeeds.com
Password: TestAccount123!

HOW TO TEST:
1. Complete onboarding questionnaire
2. Select Instagram, TikTok, or Twitter to lock
3. Login with provided test account
4. Tap "Unlock Apps with Dhikr"
5. Record saying "Alhamdulillah" 3 times
6. Wait for AI verification
7. Apps unlock for 15 minutes

PERMISSIONS NEEDED:
- Microphone: For dhikr voice recording
- Screen Time: For app locking (Family Controls)

Note: This is a spiritual growth app for Muslims combining productivity with Islamic practices.
```

### Demo Video (Optional but Recommended):
- 30-60 seconds
- Show full flow
- Upload to YouTube (unlisted)
- Add link to App Store Connect

---

## ✅ **12. LAUNCH CHECKLIST**

### Pre-Launch:
- ✅ Firebase rules updated (secure!)
- ✅ Bundle ID updated
- ✅ App icons added (all sizes)
- ✅ Privacy policy created & hosted
- ✅ Screenshots prepared (all sizes)
- ✅ App description written
- ✅ Family Controls entitlement requested
- ✅ TestFlight testing completed
- ✅ All bugs fixed
- ✅ Test account created for reviewer

### Launch Day:
1. Submit for review
2. Wait 24-72 hours
3. If rejected, read feedback carefully
4. Fix issues, resubmit
5. When approved, set "Release Manually"
6. Choose launch date/time

### Post-Launch:
1. Monitor Firebase usage
2. Check for crashes (Xcode Organizer)
3. Respond to reviews
4. Gather user feedback
5. Plan updates

---

## ✅ **13. MARKETING (OPTIONAL)**

### Social Media:
- Twitter/X: @ScrollDeeds
- Instagram: @scrolldeeds_app
- TikTok: Short demo videos

### Communities:
- r/islam on Reddit
- Muslim tech Facebook groups
- Muslim productivity Discord servers

### Content:
- "How I reduced my screen time by 60%"
- "Combining dhikr with productivity"
- Before/after comparisons
- User testimonials

---

## ✅ **14. MONETIZATION (FUTURE)**

### Freemium Model:
**Free:**
- Lock up to 3 apps
- 15 minutes unlock time
- Basic progress tracking

**Premium ($2.99/month or $19.99/year):**
- Unlimited apps
- Custom unlock times (30/60 min)
- Advanced analytics
- Custom dhikr options
- Priority support

**Implement via:**
- StoreKit 2 (in-app purchases)
- RevenueCat (simplifies subscriptions)

---

## ✅ **15. FUTURE FEATURES**

### V1.1:
- [ ] Custom dhikr durations
- [ ] Multiple dhikr types (Subhanallah, etc)
- [ ] Widget for home screen
- [ ] Reminders for dhikr

### V1.2:
- [ ] Family sharing
- [ ] Accountability partners
- [ ] Rewards system
- [ ] Extended progress history

### V2.0:
- [ ] Quranic verses recitation
- [ ] Salah time reminders
- [ ] Community challenges
- [ ] Streaks with friends

---

## 🚀 **YOU'RE READY!**

Your app is:
- ✅ Fully functional
- ✅ User data isolated
- ✅ Cloud sync working
- ✅ Production code (no debug logs)
- ✅ Beautiful UI (green/gold)
- ✅ Dark mode default
- ✅ Quick guide for new users

**Next Steps:**
1. Update Firebase rules (CRITICAL!)
2. Change Bundle ID
3. Add app icons
4. Submit to TestFlight
5. Test with beta users
6. Submit to App Store

**Estimated Timeline:**
- TestFlight setup: 1 day
- Beta testing: 1-2 weeks
- App Store review: 1-3 days
- **Total: 2-3 weeks to launch!**

---

**May Allah bless your app and help many Muslims build better habits! 🌙✨**

**Barakallahu feek! Let's launch this! 🚀**

