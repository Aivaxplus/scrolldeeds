# 🎲 Random Dhikr Feature Documentation

## Overview
ScrollDeeds now randomly selects a dhikr type each time the user wants to unlock their apps. This keeps the spiritual practice fresh and ensures variety in remembrance of Allah.

---

## ✅ What Changed

### **1. Random Dhikr Selection** 🎲
Every time the user opens the unlock screen, a random dhikr is selected from 4 options.

### **2. Progress Bar Removed** ❌
The progress bar showing recitation count has been removed for a cleaner, more focused interface.

### **3. Dhikr Type Sent to Webhook** 📤
The selected dhikr type is now included in the webhook request so the AI knows what to verify.

---

## 🕌 Available Dhikr Types

### **1. Alhamdulillah** 🙏
- **Arabic**: الحمد لله
- **Translation**: "All praise is due to Allah"
- **Instruction**: Recite 'Alhamdulillah' 33 times
- **Icon**: hands.sparkles.fill

### **2. Astaghfirullah** ❤️
- **Arabic**: أستغفر الله
- **Translation**: "I seek forgiveness from Allah"
- **Instruction**: Recite 'Astaghfirullah' 33 times
- **Icon**: heart.fill

### **3. Allahu Akbar** ⭐
- **Arabic**: الله أكبر
- **Translation**: "Allah is the Greatest"
- **Instruction**: Recite 'Allahu Akbar' 33 times
- **Icon**: star.fill

### **4. Dua for Forgiveness** 🌙
- **Arabic**: أستغفر الله وأتوب إليه
- **Translation**: "I seek forgiveness and repent to Him"
- **Full Phrase**: "Astaghfirullah wa atubu ilayh"
- **Instruction**: Recite 'Astaghfirullah wa atubu ilayh' 33 times
- **Icon**: moon.stars.fill

---

## 🎯 Implementation Details

### **Code Structure**

#### **DhikrType Enum**
```swift
enum DhikrType: String, CaseIterable {
    case alhamdulillah = "Alhamdulillah"
    case astaghfirullah = "Astaghfirullah"
    case allahuAkbar = "Allahu Akbar"
    case duaForgiveness = "Dua for Forgiveness"
    
    var instruction: String { ... }
    var icon: String { ... }
    var description: String { ... }
    
    static func random() -> DhikrType {
        return DhikrType.allCases.randomElement() ?? .alhamdulillah
    }
}
```

#### **Random Selection**
```swift
// In PracticeSessionView init
init(detector: RecitationDetector, onCompleted: @escaping () -> Void) {
    self.detector = detector
    self.onCompleted = onCompleted
    _selectedDhikr = State(initialValue: DhikrType.random())
}
```

#### **Webhook Integration**
```swift
// Dhikr type is sent to webhook
webhookService.verifyDhikrRecording(
    audioData: audioData, 
    dhikrType: selectedDhikr.rawValue  // "Alhamdulillah", "Astaghfirullah", etc.
) { result in
    // Handle result
}
```

---

## 📱 UI Changes

### **Header**
```
┌─────────────────────────────────┐
│ Unlock with Dhikr        [X]    │
│ ⭐ Allahu Akbar                 │  ← Icon + Name
└─────────────────────────────────┘
```

### **Warning Badge**
```
┌─────────────────────────────────┐
│ ⚠️ You Are Accountable          │
│ Every second will be recorded   │
└─────────────────────────────────┘
```

### **Recording Card**
```
┌─────────────────────────────────┐
│                                  │
│        [Tap to Start]            │
│                                  │
└─────────────────────────────────┘
```

### **Dhikr Instruction Card** (NEW - Replaced Progress Bar)
```
┌─────────────────────────────────┐
│           ⭐                     │
│                                  │
│      Allahu Akbar               │
│   Allah is the Greatest         │
│                                  │
│  ─────────────────────          │
│                                  │
│  Recite 'Allahu Akbar' 33 times │
└─────────────────────────────────┘
```

### **Tips Card**
```
┌─────────────────────────────────┐
│ 💡 Tips for Best Results        │
│ • Find a quiet space            │
│ • Speak clearly                 │
│ • Recite at moderate pace       │
└─────────────────────────────────┘
```

---

## 🔗 Webhook Changes

### **Request Payload**

The webhook now receives the specific dhikr type:

```http
POST https://aivaxplus.app.n8n.cloud/webhook/7feb29f5-1a33-47f0-a8c7-9397e2d91e75
Content-Type: multipart/form-data

Fields:
- audio: [audio file]
- dhikr_type: "Alhamdulillah" | "Astaghfirullah" | "Allahu Akbar" | "Dua for Forgiveness"
- timestamp: [unix timestamp]
```

### **Previous Request** (OLD)
```
dhikr_type: "Alhamdulillah"  (always the same)
```

### **New Request** (NOW)
```
dhikr_type: "Alhamdulillah"     (25% chance)
dhikr_type: "Astaghfirullah"    (25% chance)
dhikr_type: "Allahu Akbar"      (25% chance)
dhikr_type: "Dua for Forgiveness" (25% chance)
```

---

## 🧠 AI Verification Requirements

Your n8n workflow must now:

### **1. Accept Variable Dhikr Types**
```javascript
// In your n8n workflow
const dhikrType = $input.item.json.dhikr_type;

// AI must verify based on dhikr_type
switch(dhikrType) {
  case "Alhamdulillah":
    // Verify "Alhamdulillah" 33 times
    break;
  case "Astaghfirullah":
    // Verify "Astaghfirullah" 33 times
    break;
  case "Allahu Akbar":
    // Verify "Allahu Akbar" 33 times
    break;
  case "Dua for Forgiveness":
    // Verify "Astaghfirullah wa atubu ilayh" 33 times
    break;
}
```

### **2. Response Format** (Same as before)
```json
{
  "approved": true,
  "reason": "Great! You completed your dhikr",
  "confidence": 0.95
}
```

---

## 🎯 Benefits

### **For Users:**
1. **Variety** 🔄
   - Different dhikr each time keeps practice fresh
   - Less monotonous, more engaging
   - Encourages different forms of remembrance

2. **Spiritual Growth** 📈
   - Exposure to multiple forms of dhikr
   - Balanced spiritual practice
   - Learn different du'as

3. **Surprise Element** 🎁
   - Users don't know which dhikr they'll get
   - Adds element of anticipation
   - Makes unlocking feel less routine

### **For the App:**
1. **Gamification** 🎮
   - Random selection adds game-like quality
   - Keeps users engaged longer
   - Reduces predictability

2. **Educational** 📚
   - Users learn 4 different dhikr types
   - Promotes broader Islamic knowledge
   - Encourages authentic practice

---

## 🔍 Testing Checklist

### **Manual Testing**

Test each dhikr type:
- [ ] **Alhamdulillah**: Record 33x, verify AI approves
- [ ] **Astaghfirullah**: Record 33x, verify AI approves
- [ ] **Allahu Akbar**: Record 33x, verify AI approves
- [ ] **Dua for Forgiveness**: Record full phrase 33x, verify AI approves

Test randomization:
- [ ] Open unlock screen 10 times
- [ ] Verify different dhikr appear
- [ ] Confirm roughly equal distribution

Test webhook:
- [ ] Verify `dhikr_type` field is sent
- [ ] Check webhook logs show correct dhikr
- [ ] Confirm AI verifies based on correct type

---

## 📊 Expected Distribution

With true randomization:
```
Over 100 unlock attempts:
- Alhamdulillah:     ~25 times (25%)
- Astaghfirullah:    ~25 times (25%)
- Allahu Akbar:      ~25 times (25%)
- Dua for Forgiveness: ~25 times (25%)
```

---

## 🚀 Deployment Notes

### **Before Deploying:**

1. **Update n8n Workflow** ⚠️
   - Modify AI verification to handle 4 dhikr types
   - Test each type individually
   - Ensure error handling for unknown types

2. **Test AI Models** 🤖
   - Train/test AI on all 4 dhikr types
   - Verify accuracy for each (>90%)
   - Test with various accents/speeds

3. **Test in App** 📱
   - Open unlock screen 20+ times
   - Record each dhikr type
   - Verify all work correctly

---

## 📝 Files Modified

### **1. PracticeSessionView.swift** ✅
**Changes:**
- Added `DhikrType` enum with 4 types
- Removed `title` parameter from init
- Added random dhikr selection in init
- Updated header to show dhikr icon + name
- Removed progress bar section (lines 272-296)
- Replaced with dhikr instruction card
- Updated webhook call to use `selectedDhikr.rawValue`
- Updated preview to not require title

**Lines Changed:** ~100+ lines

### **2. ContentView.swift** ✅
**Changes:**
- Removed `title: "Alhamdulillah"` from PracticeSessionView initialization
- Now uses `PracticeSessionView(detector: detector) { ... }`

**Lines Changed:** 1 line

---

## 🎨 Design Improvements

### **Removed:**
- ❌ Progress bar with percentage
- ❌ Static "Alhamdulillah" title
- ❌ Fixed dhikr description

### **Added:**
- ✅ Dynamic dhikr icon (changes per type)
- ✅ Dhikr name in header
- ✅ Beautiful instruction card with:
  - Large icon (42pt)
  - Dhikr name (28pt bold)
  - English translation (15pt)
  - Divider
  - Clear instruction (16pt semibold)

---

## 🌙 Islamic Significance

### **Why These 4 Dhikr?**

1. **Alhamdulillah** - Gratitude and praise
2. **Astaghfirullah** - Seeking forgiveness
3. **Allahu Akbar** - Affirming Allah's greatness
4. **Dua for Forgiveness** - Complete repentance formula

These cover the core aspects of Islamic remembrance:
- ✅ Praise (Hamd)
- ✅ Forgiveness (Istighfar)
- ✅ Glorification (Takbir)
- ✅ Repentance (Tawbah)

---

## ✅ Status: COMPLETE

**Implementation:**
- ✅ Random dhikr selection working
- ✅ 4 dhikr types implemented
- ✅ Progress bar removed
- ✅ Dhikr instruction card added
- ✅ Webhook integration updated
- ✅ UI polished and beautiful
- ✅ 0 linter errors

**Next Steps:**
1. Update n8n workflow to handle 4 types
2. Train/test AI on all 4 dhikr
3. Deploy and monitor

---

**Built with variety and wisdom! 🎲🌙✨**

