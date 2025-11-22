# 🚀 ScrollDeeds - Complete App Store Submission Guide

**Volg deze stappen EXACT in deze volgorde!**

---

## 📋 **OVERVIEW: Wat Je Gaat Doen**

```
Week 1-2: Prep & TestFlight
Week 3-4: Family Controls Approval (wachten op Apple)
Week 5: App Store Submission
Week 6: LAUNCH! 🎉
```

---

# DEEL 1: VOOR TESTFLIGHT (DOE NU)

## ✅ **STAP 1: Apple Developer Account**

### **Heb je al een Apple Developer Account?**

**NEE?** → Doe dit eerst:

1. **Go to:** https://developer.apple.com
2. **Click:** "Account"
3. **Sign in** met je Apple ID
4. **Click:** "Enroll"
5. **Choose:** Individual ($99/jaar)
6. **Fill in:**
   - Legal name
   - Address
   - Phone number
7. **Pay:** $99 (credit card)
8. **Wait:** 24-48 uur voor approval

**JA?** → Go to stap 2! ✅

---

## ✅ **STAP 2: Info.plist Descriptions (BELANGRIJK!)**

### **Waarom?**
Apple vereist dat je uitlegt **waarom** je app permissions nodig heeft.

### **Wat Te Doen:**

1. **Open Xcode**
2. **Open:** `scrolldeeds.xcodeproj`
3. **Click:** Project "scrolldeeds" (top left)
4. **Select target:** "scrolldeeds"
5. **Click tab:** "Info"
6. **Scroll down** naar "Custom iOS Target Properties"

### **Add Deze Keys:**

#### **1. Family Controls Usage**
```
Key: NSFamilyControlsUsageDescription
Type: String
Value: ScrollDeeds uses Family Controls to help you manage screen time through Islamic mindfulness. Lock distracting apps and unlock them by reciting dhikr.
```

**How to add:**
- Click "+" button
- Type: `NSFamilyControlsUsageDescription`
- Press Enter
- Double-click value field
- Paste text above

#### **2. Speech Recognition Usage**
```
Key: NSSpeechRecognitionUsageDescription
Type: String
Value: ScrollDeeds uses speech recognition to verify your dhikr recitation. This ensures proper pronunciation and counts your repetitions accurately.
```

#### **3. Microphone Usage**
```
Key: NSMicrophoneUsageDescription
Type: String
Value: ScrollDeeds needs microphone access to listen to your dhikr recitation. Your audio is processed locally and never stored or shared.
```

#### **4. User Notifications**
```
Key: NSUserNotificationsUsageDescription
Type: String
Value: ScrollDeeds sends notifications to remind you when your screen time expires and to help you maintain mindful phone usage.
```

### **Check:**
- ✅ All 4 keys added?
- ✅ No typos in keys?
- ✅ Values make sense?

**Save** (Cmd + S)

---

## ✅ **STAP 3: App Store Connect Setup**

### **Create App Listing:**

1. **Go to:** https://appstoreconnect.apple.com
2. **Sign in** (same Apple ID als Developer Account)
3. **Click:** "My Apps"
4. **Click:** "+" button (top left)
5. **Select:** "New App"

### **Fill In Form:**

#### **Platforms:**
- ✅ Check "iOS"

#### **Name:**
```
ScrollDeeds
```
*(If taken, try: ScrollDeeds App, ScrollDeeds - Mindful Screen Time)*

#### **Primary Language:**
```
English (U.S.)
```

#### **Bundle ID:**
- **Select:** `com.scrolldeeds.app`
- (If not showing, wait 1 hour or check Xcode settings)

#### **SKU:**
```
scrolldeeds-ios-001
```
*(Unique identifier, only you see this)*

#### **User Access:**
```
Full Access
```

**Click:** "Create" ✅

---

## ✅ **STAP 4: App Information**

### **In App Store Connect:**

1. **Click:** your app "ScrollDeeds"
2. **Click:** "App Information" (left sidebar)

### **Fill In:**

#### **Subtitle (30 characters max):**
```
Mindful Islamic Screen Time
```

#### **Category:**
- **Primary:** Health & Fitness
- **Secondary:** Lifestyle

#### **Content Rights:**
```
☐ Contains third-party content
```
*(Leave unchecked - je hebt geen third-party content)*

#### **Age Rating:**
- **Click:** "Edit"
- **Answer questions:**
  - Violence: None
  - Sexual content: None
  - Profanity: None
  - Horror: None
  - Drugs: None
  - Gambling: None
  - Alcohol: None
- **Result:** 4+
- **Save**

#### **Privacy Policy URL:**
```
https://scrolldeeds.app/privacy
```
*(We maken deze later! Voor nu, laat leeg)*

---

## ✅ **STAP 5: Create Privacy Policy**

### **Optie A: Simple Website (Aanbevolen)**

#### **Use Carrd.co (Gratis):**

1. **Go to:** https://carrd.co
2. **Sign up** (free account)
3. **Create new site**
4. **Template:** "Profile"
5. **Edit content:**

```markdown
# Privacy Policy - ScrollDeeds

Last updated: November 2, 2025

## Overview
ScrollDeeds is committed to protecting your privacy. This app operates 
100% locally on your device with zero data collection.

## Data Collection
We DO NOT collect, store, or share any personal data:
- ❌ No user accounts
- ❌ No email addresses
- ❌ No personal information
- ❌ No usage analytics
- ❌ No tracking
- ❌ No third-party services

## Local Storage
All app data stays on your device:
- ✅ Selected apps
- ✅ Progress statistics
- ✅ Settings
- ✅ Unlock times

This data never leaves your device.

## Permissions
ScrollDeeds requires these iOS permissions:
- **Family Controls:** To manage screen time and lock apps
- **Microphone:** To listen to dhikr recitation (processed locally)
- **Speech Recognition:** To verify dhikr pronunciation (processed locally)
- **Notifications:** To alert you about unlock timers

All audio processing happens on your device. Nothing is recorded or uploaded.

## Children's Privacy
ScrollDeeds does not collect data from anyone, including children under 13.

## Changes
We may update this policy. Changes will be posted here with a new date.

## Contact
Questions? Email: support@scrolldeeds.app

---

This app respects your privacy. Alhamdulillah. 🌙
```

6. **Customize:** Colors (green/gold theme)
7. **Publish**
8. **Get URL:** `https://scrolldeeds.carrd.co`
9. **Copy this URL!**

#### **Optie B: GitHub Pages (Free, Tech-Savvy)**

Create `privacy.html` and host on GitHub Pages

#### **Optie C: Buy Domain (Professional)**

Buy `scrolldeeds.app` ($10-15/year) and host both privacy + terms

---

## ✅ **STAP 6: Terms of Service**

### **Same Process as Privacy Policy:**

**Create page with:**

```markdown
# Terms of Service - ScrollDeeds

Last updated: November 2, 2025

## Acceptance
By using ScrollDeeds, you agree to these terms.

## Description
ScrollDeeds helps you manage screen time through Islamic practices.

## User Responsibilities
- You must be 13+ to use this app
- You're responsible for your device and app usage
- Use the app in accordance with Islamic values

## App Functionality
- ScrollDeeds uses iOS Family Controls to lock apps
- You can unlock apps by completing dhikr recitation
- Unlock periods last 15 minutes
- The app operates entirely on your device

## Limitations
- ScrollDeeds is provided "as is"
- We don't guarantee 100% blocking (iOS limitations)
- You're responsible for your own self-control
- The app is a tool to help, not a complete solution

## Account & Data
- No account required
- No data collection
- All data stays on your device
- Uninstalling the app removes all data

## Religious Content
- Dhikr phrases are authentic Islamic remembrances
- We respect all Islamic practices
- Not affiliated with any specific organization

## Disclaimer
- Not responsible for time management decisions
- Not responsible for iOS system limitations
- Use at your own discretion

## Changes
We may update these terms. Check this page regularly.

## Termination
You can stop using the app anytime by uninstalling.

## Contact
Questions? Email: support@scrolldeeds.app

## Governing Law
These terms are governed by the laws of [Your Country].

---

May Allah make this app beneficial. Ameen. 🤲
```

**Get URL** and save it!

---

## ✅ **STAP 7: Update App Store Connect**

1. **Go back to:** App Store Connect
2. **Click:** App Information
3. **Add URLs:**
   - Privacy Policy: `https://scrolldeeds.carrd.co/privacy`
   - Terms: `https://scrolldeeds.carrd.co/terms`
4. **Save**

---

## ✅ **STAP 8: Create App Store Screenshots**

### **Required Sizes:**

**6.7" Display (iPhone 15 Pro Max):**
- 1290 x 2796 pixels
- Minimum 3 screenshots

**6.5" Display (iPhone 11 Pro Max / XS Max):**
- 1242 x 2688 pixels
- Minimum 3 screenshots

**5.5" Display (iPhone 8 Plus):**
- 1242 x 2208 pixels
- Minimum 3 screenshots

### **How to Create:**

#### **Optie 1: Xcode Simulator (Makkelijk)**

1. **Open Xcode**
2. **Select simulator:** iPhone 15 Pro Max
3. **Run app** (Cmd + R)
4. **Navigate** to screen you want
5. **Screenshot:** Cmd + S (saves to Desktop)
6. **Repeat** for all screens

**Suggested Screenshots:**
1. Onboarding welcome screen
2. App selection (Family Controls picker)
3. Dashboard with locked apps + timer
4. Practice session (dhikr screen)
5. Unlocked state with countdown

#### **Optie 2: Physical iPhone (Better Quality)**

1. **Install app on iPhone**
2. **Take screenshots:** Volume Up + Power button
3. **AirDrop to Mac**
4. **Use Preview** to check size (should be correct automatically)

#### **Optie 3: Marketing Screenshots (Professional)**

Use **Figma** or **Canva**:
1. Create 1290x2796 canvas
2. Add iPhone frame mockup
3. Add app screenshot inside
4. Add text overlay: "Lock Distracting Apps"
5. Add decorative elements
6. Export as PNG

---

## ✅ **STAP 9: Upload to TestFlight**

### **Build & Archive:**

1. **Open Xcode**
2. **Select:** "Any iOS Device (arm64)" in top bar
3. **Clean:** Product → Clean Build Folder (Shift + Cmd + K)
4. **Archive:** Product → Archive
5. **Wait:** 2-5 minutes
6. **Window** → Organizer opens automatically

### **In Organizer:**

1. **Select** your archive (most recent)
2. **Click:** "Distribute App"
3. **Select:** "App Store Connect"
4. **Click:** Next
5. **Select:** "Upload"
6. **Click:** Next
7. **Check:**
   - ✅ Strip Swift symbols
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (automatic)
8. **Click:** Next
9. **Review:** Signing options
10. **Click:** Upload
11. **Wait:** 5-10 minutes

### **Check Upload:**

1. **Go to:** App Store Connect
2. **Click:** "TestFlight" tab
3. **Wait:** 10-20 minutes for "Processing"
4. **Status changes to:** "Ready to Submit"

---

## ✅ **STAP 10: TestFlight Testing**

### **Add Internal Testers:**

1. **In TestFlight tab**
2. **Click:** "App Store Connect Users" (left side)
3. **Click:** "+" button
4. **Add** yourself
5. **Add** vrienden/familie (max 100 testers)
6. **Click:** "Add"

### **Install TestFlight:**

1. **On iPhone:** Download "TestFlight" app from App Store
2. **Open** TestFlight
3. **Sign in** (same Apple ID)
4. **You'll see** ScrollDeeds
5. **Click:** "Install"
6. **Test everything!**

### **Beta Testing Checklist:**

- [ ] App launches correctly
- [ ] Onboarding works
- [ ] Can select apps
- [ ] Can complete dhikr session
- [ ] Apps unlock for 15 minutes
- [ ] Timer counts down
- [ ] Apps relock after 15 min
- [ ] Notifications work
- [ ] Settings work
- [ ] No crashes

**Test for 3-7 days minimum!**

---

# DEEL 2: FAMILY CONTROLS APPROVAL (KRITIEK!)

## ⚠️ **STAP 11: Request Distribution Approval**

### **Waarom Dit Belangrijk Is:**

Je hebt nu **development** Family Controls.
Voor **App Store** heb je **distribution** approval nodig!

### **How To Request:**

1. **Go to:** https://developer.apple.com/contact/request/family-controls-distribution

2. **Fill in Form:**

```
Apple ID: [Your developer email]
App Name: ScrollDeeds
Bundle ID: com.scrolldeeds.app
App Store Connect Team ID: [Find in App Store Connect → Users & Access → Keys]

Description:
ScrollDeeds helps Muslims reduce screen time through Islamic mindfulness. 
Users select distracting apps to lock. To unlock, they must recite Islamic 
dhikr (remembrance of Allah) 33 times using speech recognition. This 
encourages mindfulness before scrolling.

The app uses Family Controls to:
- Lock user-selected apps by default
- Unlock them for 15 minutes after completing dhikr
- Automatically relock when time expires

This promotes healthier phone habits while strengthening Islamic practice.
Target audience: Muslims struggling with phone addiction.

App Store URL: [Leave blank for now, or add after submission]
Privacy Policy: https://scrolldeeds.carrd.co/privacy
```

3. **Submit**

4. **Wait:** 1-2 weeks for Apple response

5. **You'll receive email:**
   - ✅ Approved → Continue to Stap 12!
   - ❌ Denied → They'll explain why, fix and resubmit

---

## ✅ **STAP 12: Update Entitlements (After Approval)**

### **When You Get Approval Email:**

1. **Open Xcode**
2. **Open:** `scrolldeeds/scrolldeeds.entitlements`
3. **Find:**
```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

4. **Change to:**
```xml
<key>com.apple.developer.family-controls</key>
<array>
    <string>distribution</string>
</array>
```

5. **Save** (Cmd + S)

6. **Build new version:**
   - Product → Clean
   - Product → Archive
   - Upload to TestFlight again
   - This is your **PRODUCTION build!**

---

# DEEL 3: APP STORE SUBMISSION

## ✅ **STAP 13: Complete App Store Listing**

### **In App Store Connect:**

1. **Click:** Your app
2. **Click:** "+ Version" (or "1.0 Prepare for Submission")
3. **Fill in ALL fields:**

#### **App Information:**

**Name:**
```
ScrollDeeds
```

**Subtitle:**
```
Mindful Islamic Screen Time
```

**Description:**
```
🕌 Transform Screen Time into Spiritual Time

ScrollDeeds helps Muslims reduce screen time through Islamic mindfulness. 
Lock distracting apps and unlock them by reciting dhikr.

✨ KEY FEATURES

🔒 Smart App Locking
Choose which apps to lock. Apps stay locked by default using iOS Family 
Controls technology.

📿 Dhikr-Based Unlocking
Recite beautiful Islamic remembrances to unlock your apps:
• Subhanallah (Glory be to Allah)
• Alhamdulillah (All praise to Allah)
• Allahu Akbar (Allah is the Greatest)
• Astaghfirullah (I seek forgiveness from Allah)

Say each phrase 33 times with proper pronunciation, verified by speech 
recognition.

⏰ Timed Access
Earn 15 minutes of mindful screen time per session. A countdown timer 
keeps you aware. Apps automatically lock when time expires.

📊 Progress Tracking
Track your dhikr sessions, see time saved, and build better digital habits.

🎯 WHY SCROLLDEEDS?

"Every soul will taste death. And you will only receive your full reward 
on the Day of Judgment." (Quran 3:185)

We'll be asked about how we spent our time. ScrollDeeds makes you pause 
and remember Allah before endless scrolling. Turn wasted time into worship.

🔐 PRIVACY FIRST

• 100% local - no cloud, no accounts
• Zero data collection
• No tracking or analytics
• Your data never leaves your device
• All audio processing happens locally

💚 PERFECT FOR

• Muslims struggling with phone addiction
• Parents teaching kids healthy screen time
• Anyone seeking mindful phone usage
• Those wanting to increase dhikr in daily life

🌙 ISLAMIC VALUES

All dhikr are authentic Islamic remembrances. The app promotes mindfulness, 
self-discipline, and remembrance of Allah - core Islamic values for the 
digital age.

Download ScrollDeeds today and make every moment count. 

May Allah accept our efforts and make this app beneficial for the Ummah. 
Ameen. 🤲

---

Privacy Policy: https://scrolldeeds.carrd.co/privacy
Terms of Service: https://scrolldeeds.carrd.co/terms
Support: support@scrolldeeds.app
```

**Keywords (100 chars max):**
```
islam,muslim,dhikr,screen time,app blocker,mindfulness,productivity,digital wellness,prayer,focus
```

**Support URL:**
```
https://scrolldeeds.carrd.co/support
```
*(Create this page or use email: support@scrolldeeds.app)*

**Marketing URL (optional):**
```
https://scrolldeeds.app
```

---

#### **App Pricing:**

**Price:**
```
Free
```

**Availability:**
```
☑️ All countries
```
*(Or select specific countries)*

---

#### **App Privacy:**

**Click:** "Manage" next to "App Privacy"

**Answer Questions:**

**Does this app collect data from its users?**
```
○ No, this app does not collect data from users
```

That's it! Your privacy story is simple. ✅

---

#### **App Review Information:**

**Sign-in required:**
```
☐ No (unchecked)
```

**Contact Information:**
```
First Name: [Your name]
Last Name: [Your last name]
Phone: [Your phone]
Email: support@scrolldeeds.app
```

**Notes:**
```
Testing Instructions:

1. Complete onboarding (select 1-2 apps to lock)
2. On dhikr session screen, say any of these phrases 33 times:
   - "Subhanallah"
   - "Alhamdulillah"  
   - "Allahu Akbar"
   - "Astaghfirullah"
3. Apps will unlock for 15 minutes
4. Timer countdown shows on dashboard
5. Apps automatically relock after 15 minutes

Notes:
- Microphone permission required for dhikr recognition
- Family Controls permission required for app locking
- Speech recognition processes audio locally (not sent to servers)
- All data stored locally on device

If you need a demo account or have questions, email support@scrolldeeds.app
```

---

#### **Version Information:**

**Copyright:**
```
2025 [Your Name or Company Name]
```

**Routing App Coverage File:**
```
(Leave blank)
```

---

#### **Build:**

**Click:** "+" next to Build
**Select:** Your TestFlight build
**Click:** Done

---

#### **Screenshots:**

**Upload** your 3 screenshot sizes:
- 6.7" (iPhone 15 Pro Max)
- 6.5" (iPhone 11 Pro Max)
- 5.5" (iPhone 8 Plus)

Drag and drop in order you want them displayed.

---

## ✅ **STAP 14: Final Checks**

### **Before Submitting, Verify:**

- [x] Info.plist descriptions added?
- [x] Privacy Policy URL working?
- [x] Terms of Service URL working?
- [x] TestFlight tested (3+ days)?
- [x] Screenshots uploaded (all 3 sizes)?
- [x] App description complete?
- [x] Keywords added?
- [x] Family Controls **distribution** approval received?
- [x] Entitlements updated to distribution?
- [x] New build uploaded with distribution entitlement?
- [x] All fields in App Store Connect filled?
- [x] Contact email working?

---

## ✅ **STAP 15: SUBMIT!**

### **Ready? Let's Go:**

1. **In App Store Connect**
2. **Scroll to bottom**
3. **Click:** "Add for Review"
4. **Review** everything one last time
5. **Click:** "Submit for Review"

### **You'll See:**

```
✅ Waiting for Review
```

### **Timeline:**

- **Day 1:** "Waiting for Review" (24-48 hours)
- **Day 2-3:** "In Review" (1-3 days)
- **Day 4-5:** Decision:
  - ✅ **"Ready for Sale"** → APPROVED! 🎉
  - ❌ **"Rejected"** → They'll explain why

---

## 🎉 **IF APPROVED:**

### **Your App is LIVE!**

1. **Check App Store:**
   - Search "ScrollDeeds"
   - Your app appears!

2. **Share:**
   - Social media
   - Friends/family
   - Islamic communities
   - Reddit (r/islam, r/MuslimLounge)

3. **Monitor:**
   - Reviews
   - Crash reports
   - User feedback

---

## ❌ **IF REJECTED:**

### **Don't Panic!**

1. **Read rejection reason** carefully
2. **Common reasons:**
   - Family Controls not approved → Request approval first
   - Privacy Policy missing → Add URL
   - Info.plist descriptions missing → Add them
   - Crash during review → Fix bug
   - Guideline violation → Adjust content

3. **Fix the issue**
4. **Reply to reviewer** (if clarification needed)
5. **Resubmit** (can take 1-2 days)

**Most apps get approved on 2nd try!**

---

## 📊 **TIMELINE SAMENVATTING:**

```
Week 1: 
- [TODAY] Info.plist updates
- [TODAY] App Store Connect setup
- [TODAY] Privacy Policy creation
- [TODAY] TestFlight upload
- [1-2 days] TestFlight testing starts

Week 2:
- [Ongoing] Beta testing
- [Ongoing] Create screenshots
- [Day 1] Request Family Controls approval

Week 3-4:
- [Waiting] Family Controls approval (1-2 weeks)
- [Meanwhile] Continue testing
- [Meanwhile] Refine screenshots
- [Meanwhile] Polish app description

Week 5:
- [✅] Approval arrives!
- [1 day] Update entitlements
- [1 day] Upload new build
- [1 day] Complete App Store listing
- [1 day] SUBMIT!

Week 6:
- [2-3 days] "Waiting for Review"
- [1-3 days] "In Review"
- [🎉] APPROVED & LIVE!
```

**Total: 5-6 weeks from now to App Store!**

---

## 💰 **COSTS:**

```
Apple Developer Account: $99/year
Privacy Policy hosting (Carrd): $0 (free tier)
Domain (optional): $10-15/year
Total: $99-114/year
```

---

## 🎯 **QUICK START (DO TODAY):**

### **Priority 1 (30 minutes):**
- [ ] Add Info.plist descriptions
- [ ] Create App Store Connect listing
- [ ] Upload to TestFlight

### **Priority 2 (1-2 hours):**
- [ ] Create Privacy Policy
- [ ] Create Terms of Service
- [ ] Request Family Controls approval

### **Priority 3 (2-3 hours):**
- [ ] Create screenshots
- [ ] Write app description
- [ ] Beta test

---

## ❓ **HULP NODIG?**

### **Stuck? Ask Me:**

- Info.plist help
- Screenshots guide
- Privacy Policy template
- App Store rejection help
- Marketing tips
- Anything else!

---

## 🚀 **YOU GOT THIS!**

Je hebt een **geweldige app** gemaakt.
Nu is het tijd om het met de wereld te delen!

**Volg deze guide** en binnen 5-6 weken ben je LIVE! 🎉

**May Allah make this app a source of continuous reward (sadaqah jariyah) for you. Ameen! 🤲**

---

**Vragen? Begin met Priority 1 en laat me weten als je vastloopt! 💪**

