# 🎤 Voice Recording & AI Verification Setup

## ✅ What's Been Implemented

Your app now records user's dhikr/dua recitations and sends them to a webhook URL for AI verification!

### How It Works:

```
1. User taps "Start Recording" 
   ↓
2. App records audio (high quality M4A)
   ↓
3. User taps "Stop & Verify"
   ↓
4. Audio sent to your webhook URL
   ↓
5. AI analyzes the audio
   ↓
6. Webhook responds: Approved ✅ or Rejected ❌
   ↓
7. User gets 15 min access (if approved)
```

---

## 🎯 Setting Up Your Webhook

### Step 1: Create Your Webhook Endpoint

You need a server that can:
- Accept audio file uploads (multipart/form-data)
- Process/analyze the audio with AI
- Return JSON response

**Recommended Services:**
- **Replicate.com** - Run AI models (Whisper for speech-to-text)
- **AssemblyAI** - Audio transcription API
- **OpenAI Whisper API** - Speech recognition
- **Your own server** - Node.js/Python/etc.

### Step 2: Update Webhook URL in Code

Open `WebhookService.swift` and change this line:

```swift
private let webhookURL = "https://your-webhook-url.com/api/verify-dhikr"
```

Replace with your actual URL:

```swift
private let webhookURL = "https://your-api.com/verify-dhikr"
```

---

## 📡 Webhook API Specification

### Request Format

**Method:** `POST`  
**Content-Type:** `multipart/form-data`

**Form Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `audio` | File | M4A audio file of the recitation |
| `dhikr_type` | String | Type of dhikr (e.g., "Alhamdulillah") |
| `timestamp` | Number | Unix timestamp of recording |

**Example Request:**
```
POST /api/verify-dhikr HTTP/1.1
Host: your-api.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="dhikr_type"

Alhamdulillah
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="audio"; filename="dhikr.m4a"
Content-Type: audio/m4a

[audio file binary data]
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="timestamp"

1698765432.123
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

### Response Format

Your webhook must return JSON:

#### Success Response:
```json
{
  "approved": true,
  "confidence": 0.95,
  "detected_text": "Alhamdulillah Alhamdulillah..."
}
```

#### Rejection Response:
```json
{
  "approved": false,
  "reason": "Could not clearly hear the dhikr",
  "confidence": 0.45
}
```

#### Error Response:
```json
{
  "approved": false,
  "reason": "Audio processing failed"
}
```

---

## 🤖 Example Webhook Implementation

### Option 1: Node.js + OpenAI Whisper

```javascript
const express = require('express');
const multer = require('multer');
const OpenAI = require('openai');

const app = express();
const upload = multer({ dest: 'uploads/' });
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.post('/api/verify-dhikr', upload.single('audio'), async (req, res) => {
  try {
    const { dhikr_type } = req.body;
    const audioFile = req.file;
    
    // Transcribe audio with Whisper
    const transcription = await openai.audio.transcriptions.create({
      file: fs.createReadStream(audioFile.path),
      model: "whisper-1",
    });
    
    // Check if dhikr was recited
    const text = transcription.text.toLowerCase();
    const dhikrWord = dhikr_type.toLowerCase();
    const count = (text.match(new RegExp(dhikrWord, 'g')) || []).length;
    
    if (count >= 33) {
      res.json({
        approved: true,
        confidence: 0.95,
        detected_text: text
      });
    } else {
      res.json({
        approved: false,
        reason: `Only detected ${count} recitations, need 33`,
        confidence: 0.70
      });
    }
    
  } catch (error) {
    res.json({
      approved: false,
      reason: "Audio processing failed"
    });
  }
});

app.listen(3000);
```

### Option 2: Python + Flask + Whisper

```python
from flask import Flask, request, jsonify
import whisper
import tempfile

app = Flask(__name__)
model = whisper.load_model("base")

@app.route('/api/verify-dhikr', methods=['POST'])
def verify_dhikr():
    try:
        audio_file = request.files['audio']
        dhikr_type = request.form['dhikr_type']
        
        # Save temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.m4a') as tmp:
            audio_file.save(tmp.name)
            
            # Transcribe
            result = model.transcribe(tmp.name)
            text = result["text"].lower()
            
            # Count occurrences
            dhikr_word = dhikr_type.lower()
            count = text.count(dhikr_word)
            
            if count >= 33:
                return jsonify({
                    "approved": True,
                    "confidence": 0.95,
                    "detected_text": text
                })
            else:
                return jsonify({
                    "approved": False,
                    "reason": f"Only {count} recitations detected, need 33"
                })
                
    except Exception as e:
        return jsonify({
            "approved": False,
            "reason": "Processing failed"
        })

if __name__ == '__main__':
    app.run(port=5000)
```

---

## 🧪 Testing Mode

The app currently uses **mock verification** for testing!

In `PracticeSessionView.swift`:

```swift
// CURRENTLY ACTIVE (for testing):
webhookService.mockVerification(success: true) { result in
    handleVerificationResult(result)
}

// SWITCH TO THIS FOR PRODUCTION:
// webhookService.verifyDhikrRecording(audioData: audioData, dhikrType: title) { result in
//     handleVerificationResult(result)
// }
```

**Mock mode** simulates a 2-second AI check and always approves.

---

## 🎬 User Experience Flow

### 1. Ready State
- Shows microphone icon
- "Tap to start"

### 2. Recording State
- Red pulsing dot 🔴
- Live timer (00:15)
- "Recite your dhikr clearly"

### 3. Verifying State
- Spinning progress indicator
- "Verifying..."
- "AI is checking your recitation"

### 4. Result
**If Approved ✅:**
- Alert: "Great! Your dhikr has been verified"
- User gets 15 minutes access
- Sheet dismisses

**If Rejected ❌:**
- Alert: Shows reason from webhook
- "Please try again and speak clearly"
- Can record again

---

## 📱 Permissions Required

The app automatically requests these:

1. **Microphone Permission** - To record audio
2. **Speech Recognition** - For on-device processing (optional)

These are requested on first use.

---

## 🔒 Privacy & Security

### Audio Storage:
- ✅ Recorded locally in app's Documents folder
- ✅ Deleted after verification
- ✅ Never stored permanently
- ✅ Only sent to your webhook (you control it)

### Security Best Practices:
1. Use HTTPS for your webhook (required for production)
2. Add API key authentication to webhook
3. Implement rate limiting
4. Validate audio file size/type
5. Set timeout (currently 60 seconds)

---

## 🚀 Quick Start Guide

### For Testing (Right Now):
1. ✅ App is ready to test!
2. Tap "Start Practice Session"
3. Tap "Start Recording"
4. Speak for a few seconds
5. Tap "Stop & Verify"
6. After 2 seconds → Approved! ✅

### For Production:
1. Create webhook endpoint (see examples above)
2. Deploy to server (Heroku, Railway, Vercel, etc.)
3. Update webhook URL in `WebhookService.swift`
4. Comment out mock, uncomment real webhook
5. Test with real audio
6. Deploy app! 🎉

---

## 🛠 Advanced Configuration

### Change Timeout:
```swift
request.timeoutInterval = 60 // seconds
```

### Add Authentication:
```swift
request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
```

### Custom Audio Format:
In `AudioRecorderManager.swift`:
```swift
let settings = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // or kAudioFormatAppleL ossless
    AVSampleRateKey: 44100,  // or 48000
    AVNumberOfChannelsKey: 1, // mono (stereo = 2)
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

---

## 📊 Webhook Response Examples

### Successful Verification:
```json
{
  "approved": true,
  "confidence": 0.98,
  "detected_text": "alhamdulillah alhamdulillah alhamdulillah...",
  "count": 35,
  "duration": 12.5
}
```

### Failed - Not Enough Recitations:
```json
{
  "approved": false,
  "reason": "Only detected 15 recitations. Please recite 33 times.",
  "confidence": 0.87,
  "count": 15
}
```

### Failed - Audio Quality:
```json
{
  "approved": false,
  "reason": "Audio quality too low. Please find a quieter environment.",
  "confidence": 0.32
}
```

### Failed - Wrong Dhikr:
```json
{
  "approved": false,
  "reason": "Different dhikr detected. Please recite 'Alhamdulillah'.",
  "confidence": 0.75
}
```

---

## ❓ Troubleshooting

### "Failed to get audio data"
- Check microphone permissions
- Restart app

### "Network error"
- Check webhook URL is correct
- Verify server is running
- Check internet connection

### "Verification taking too long"
- Default timeout is 60 seconds
- Check webhook server performance
- Consider increasing timeout

### Audio not recording
- Grant microphone permission in Settings
- Check if another app is using microphone
- Restart device

---

## 🎉 You're All Set!

Your app now has:
- ✅ High-quality audio recording
- ✅ Webhook integration for AI verification
- ✅ Beautiful UI with loading states
- ✅ Error handling and user feedback
- ✅ Mock mode for testing
- ✅ Production-ready architecture

**Next Steps:**
1. Test with mock mode (already works!)
2. Build your webhook (use examples above)
3. Deploy webhook to cloud
4. Update webhook URL in app
5. Test with real AI verification
6. Ship it! 🚀

Need help setting up your webhook? Let me know! 💪

