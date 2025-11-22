# Backend Setup Guide voor ScrollDeeds

## Overzicht

ScrollDeeds heeft een backend nodig om gebruikersdata op te slaan. Je hebt 3 opties:

## Optie 1: Firebase (Aanbevolen - Gemakkelijkst)

### Setup Stappen:

1. **Ga naar Firebase Console**: https://console.firebase.google.com/
2. **Maak een nieuw project** of gebruik bestaand project
3. **Voeg een iOS app toe**:
   - Bundle ID: `com.yourname.scrolldeeds`
   - Download `GoogleService-Info.plist`
   - Sleep het naar je Xcode project:
     1. Open Xcode
     2. Klik op de **scrolldeeds** folder in de linker sidebar (Project Navigator)
     3. Sleep het `GoogleService-Info.plist` bestand vanuit je Downloads folder naar de **scrolldeeds** folder in Xcode
     4. Zorg dat "Copy items if needed" is **aangevinkt**
     5. Zorg dat "Add to targets: scrolldeeds" is **aangevinkt**
     6. Klik "Finish"
     7. Het bestand zou nu zichtbaar moeten zijn naast `ContentView.swift` en andere bestanden

4. **Activeer Firestore Database**:
   - Ga naar Firestore Database
   - Klik "Create Database"
   - Kies "Start in production mode"
   - Selecteer locatie (europe-west voor Europa)

5. **Firestore Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users kunnen alleen hun eigen data lezen/schrijven
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /progress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

6. **Installeer Firebase SDK**:
```bash
# In je Xcode project, ga naar File > Add Packages
# Zoek naar: https://github.com/firebase/firebase-ios-sdk
# Selecteer: FirebaseFirestore, FirebaseAuth
```

### Firestore Data Structuur:

```
users/
  {userId}/
    - email: string
    - name: string
    - createdAt: timestamp
    - onboardingAnswers: map<int, int>
    - baselineScrollHours: int
    - lockedAppIdentifiers: array<string>

progress/
  {userId}/
    - totalSessions: int
    - totalMinutes: int
    - currentStreak: int
    - lastSessionDate: timestamp
    - dailyStats: map<string, object>
      - "2024-10-31": { sessions: 3, minutes: 45 }
```

## Optie 2: Supabase (Open Source Alternative)

### Setup Stappen:

1. **Ga naar Supabase**: https://supabase.com/
2. **Maak nieuw project**
3. **Maak tabellen aan**:

```sql
-- Users table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  onboarding_answers JSONB,
  baseline_scroll_hours INTEGER,
  locked_app_identifiers TEXT[]
);

-- Progress table
CREATE TABLE progress (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  total_sessions INTEGER DEFAULT 0,
  total_minutes INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  last_session_date TIMESTAMP,
  daily_stats JSONB
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;

-- Policies (users kunnen alleen hun eigen data zien)
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);
```

4. **Update FirebaseManager.swift**:
   - Verander `baseURL` naar je Supabase URL
   - Gebruik Supabase API key

## Optie 3: Custom Backend (Node.js + MongoDB)

### Minimale Express.js Backend:

```javascript
const express = require('express');
const mongoose = require('mongoose');
const app = express();

// MongoDB Schema
const UserSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  email: String,
  name: String,
  onboardingAnswers: Map,
  baselineScrollHours: Number,
  lockedAppIdentifiers: [String]
});

const ProgressSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  totalSessions: Number,
  totalMinutes: Number,
  currentStreak: Number,
  lastSessionDate: Date,
  dailyStats: Map
});

// API Routes
app.put('/api/users/:userId', async (req, res) => {
  // Save user profile
});

app.get('/api/users/:userId', async (req, res) => {
  // Get user profile
});

app.put('/api/progress/:userId', async (req, res) => {
  // Save progress
});

app.get('/api/progress/:userId', async (req, res) => {
  // Get progress
});

app.listen(3000);
```

## Integratie in de App

Na het opzetten van je backend:

1. **Update `FirebaseManager.swift`**:
   ```swift
   private let baseURL = "https://YOUR_ACTUAL_URL.com/api"
   ```

2. **Data wordt automatisch gesynchroniseerd**:
   - Bij login → Data wordt geladen van backend
   - Bij onboarding → Antwoorden worden opgeslagen
   - Bij app selectie → Locked apps worden opgeslagen
   - Bij dhikr sessie → Progress wordt bijgewerkt

3. **Offline Support**:
   - App werkt offline met UserDefaults
   - Synchroniseert wanneer internet beschikbaar is

## Testing

Test de backend met deze curl commands:

```bash
# Save user profile
curl -X PUT https://YOUR_URL/api/users/test123 \
  -H "Content-Type: application/json" \
  -d '{"userId":"test123","email":"test@test.com","name":"Test User"}'

# Get user profile
curl https://YOUR_URL/api/users/test123
```

## Belangrijke Notities

⚠️ **Security**: 
- Gebruik altijd authentication tokens
- Valideer alle requests server-side
- Implementeer rate limiting

🔐 **Privacy**:
- Encrypteer gevoelige data
- Comply met GDPR/privacy laws
- Geef users optie om data te verwijderen

📊 **Monitoring**:
- Log alle API calls
- Monitor errors en performance
- Set up alerts voor downtime

