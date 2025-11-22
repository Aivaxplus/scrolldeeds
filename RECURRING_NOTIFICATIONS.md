# 🔔 Recurring Notifications - Every 5 Minutes

## ✅ WHAT'S IMPLEMENTED

When the 15-minute unlock period expires, the app now:

### **1. Immediate Lock + Notification**
- ✅ Apps are locked immediately
- ✅ User receives: **"Apps Locked Again 🔒"**

### **2. Recurring Notifications Every 5 Minutes**
- ✅ **6 notifications** scheduled automatically
- ✅ Sent at: **5, 10, 15, 20, 25, and 30 minutes** after lock
- ✅ Each notification says: **"⏰ Apps Still Locked"**
- ✅ Body: **"Exit this app and complete dhikr in ScrollDeeds to unlock"**

### **3. Smart Cancellation**
- ✅ When user completes dhikr and unlocks → **all recurring notifications are cancelled**
- ✅ New unlock period starts with fresh notification schedule

---

## 📱 HOW IT WORKS

### **Timeline Example:**

```
Time 0:00  → User unlocks with dhikr
Time 0:15  → 15 minutes expire
            ✅ IMMEDIATE: "Apps Locked Again 🔒"
            ✅ Shield reapplied
            ✅ 6 notifications scheduled

Time 0:20  → 🔔 Notification 1: "Apps Still Locked"
Time 0:25  → 🔔 Notification 2: "Apps Still Locked"
Time 0:30  → 🔔 Notification 3: "Apps Still Locked"
Time 0:35  → 🔔 Notification 4: "Apps Still Locked"
Time 0:40  → 🔔 Notification 5: "Apps Still Locked"
Time 0:45  → 🔔 Notification 6: "Apps Still Locked"

If user unlocks at Time 0:27:
            ✅ All remaining notifications (3-6) are CANCELLED
            ✅ New 15-minute unlock period starts
```

---

## 🎯 WHY THIS SOLUTION?

### **Apple Limitation:**
❌ **Cannot force-close apps** or lock them while user is actively using them

### **Our Workaround:**
✅ **Persistent reminders** every 5 minutes to nudge user to exit and unlock properly

---

## 🔍 WHAT'S CHANGED

### **NotificationManager.swift**
```swift
// NEW FUNCTIONS:
func scheduleRecurringTimeExpiredNotifications()
  → Schedules 6 notifications (every 5 min for 30 min)

func cancelRecurringTimeExpiredNotifications()
  → Cancels all 6 scheduled notifications
```

### **ContentView.swift**

#### **1. When Time Expires:**
```swift
private func reapplyLock() {
    // ... existing code ...
    
    // NEW: Schedule recurring notifications
    notificationManager.scheduleRecurringTimeExpiredNotifications()
}
```

#### **2. When User Unlocks Again:**
```swift
PracticeSessionView(detector: detector) {
    // ... existing code ...
    
    // NEW: Cancel recurring notifications
    notificationManager.cancelRecurringTimeExpiredNotifications()
}
```

---

## 📋 TESTING CHECKLIST

### **✅ Step-by-Step Test:**

1. **Build & Run** (Cmd + R) on your iPhone
2. **Complete dhikr** → unlock apps
3. **Open TikTok** (or any locked app)
4. **Wait 15 minutes** (or change to 1 minute for testing)
5. **✅ You should receive:**
   - Immediate notification: "Apps Locked Again 🔒"
6. **Stay in TikTok** (keep scrolling)
7. **✅ After 5 minutes:** Notification 1
8. **✅ After 10 minutes:** Notification 2
9. **✅ After 15 minutes:** Notification 3
10. **Exit TikTok** → complete dhikr → unlock again
11. **✅ Remaining notifications (4-6) should be CANCELLED**

---

## ⚙️ CONFIGURATION

Want to change the notification frequency?

### **File:** `NotificationManager.swift`
### **Line:** 230

```swift
// Current: 6 notifications over 30 minutes (every 5 min)
for i in 1...6 {
    let timeInterval = Double(i * 5 * 60)
    // ...
}

// Example: 12 notifications over 60 minutes (every 5 min)
for i in 1...12 {
    let timeInterval = Double(i * 5 * 60)
    // ...
}

// Example: Every 3 minutes for 18 minutes
for i in 1...6 {
    let timeInterval = Double(i * 3 * 60) // Change to 3 minutes
    // ...
}
```

---

## 🚨 IMPORTANT NOTES

### **1. Notifications Must Be Enabled**
User must grant notification permissions in iOS Settings:
- **Settings** → **ScrollDeeds** → **Notifications** → **Allow**

### **2. Physical Device Required**
Notifications work best on a real iPhone, not the simulator.

### **3. Focus Modes**
If user has **Do Not Disturb** enabled, notifications might be delayed.

### **4. Badge Count**
Each notification sets `badge = 1` to show a red badge on the app icon.

---

## 🎉 BENEFITS

✅ **Persistent reminders** without overwhelming the user (only 6 over 30 min)
✅ **Smart cancellation** when user unlocks (no spam)
✅ **Non-intrusive** but effective (standard notifications, not critical)
✅ **Consistent with Islamic values** (gentle reminders, not forceful)

---

## 🔄 NEXT STEPS

1. **Test on your iPhone**
2. **Adjust frequency** if needed (see Configuration section)
3. **Consider adding vibration** by changing `.default` to `.defaultCritical` if you want more aggressive reminders

---

**IMPLEMENTED BY:** AI Assistant
**DATE:** November 1, 2025
**STATUS:** ✅ READY FOR TESTING

