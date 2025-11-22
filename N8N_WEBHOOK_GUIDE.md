# n8n Webhook Setup Guide

## ✅ Your Webhook URL is Connected!

### 🚀 Production URL (Active):
```
https://aivaxplus.app.n8n.cloud/webhook/7feb29f5-1a33-47f0-a8c7-9397e2d91e75
```

### 🧪 Test URL (Not in use):
```
https://aivaxplus.app.n8n.cloud/webhook-test/7feb29f5-1a33-47f0-a8c7-9397e2d91e75
```

**Status**: App is now using the **Production URL** ✅

---

## 📥 What Your n8n Workflow Receives

### HTTP Request Details:
- **Method**: POST
- **Content-Type**: multipart/form-data

### Form Fields:

| Field | Type | Example | Description |
|-------|------|---------|-------------|
| `audio` | File | dhikr.m4a | The recorded audio file |
| `dhikr_type` | String | "Alhamdulillah" | What dhikr should be recited |
| `timestamp` | Number | 1698765432.123 | When it was recorded |

---

## 📤 What Your n8n Workflow Must Return

### Success Response (User recited correctly):

```json
{
  "approved": true,
  "reason": "Dhikr verified successfully"
}
```

### Failure Response (User didn't recite correctly):

```json
{
  "approved": false,
  "reason": "Could not detect 33 recitations. Please try again."
}
```

### Optional Fields (for better feedback):

```json
{
  "approved": true,
  "confidence": 0.95,
  "count": 35,
  "detected_text": "alhamdulillah alhamdulillah..."
}
```

---

## 🔧 Example n8n Workflow

### Simple Workflow Structure:

```
1. Webhook Trigger (Receive audio)
   ↓
2. Save File (optional - save audio to storage)
   ↓
3. OpenAI Whisper / AssemblyAI (Transcribe audio)
   ↓
4. Function Node (Count dhikr occurrences)
   ↓
5. IF Node (Check if count >= 33)
   ↓
6. Respond to Webhook (Return JSON)
```

---

## 📝 n8n Node Examples

### 1. Webhook Node Setup

**Webhook Node Settings:**
- HTTP Method: POST
- Path: webhook-test/7feb29f5-1a33-47f0-a8c7-9397e2d91e75
- Response Mode: When Last Node Finishes
- Response Data: First Incoming Item

### 2. Function Node (Count Dhikr)

```javascript
// Get the transcribed text from previous node
const transcribedText = $input.first().json.text.toLowerCase();
const dhikrType = $input.first().json.dhikr_type.toLowerCase();

// Count occurrences
const regex = new RegExp(dhikrType, 'g');
const matches = transcribedText.match(regex);
const count = matches ? matches.length : 0;

// Determine if approved
const approved = count >= 33;

return {
  json: {
    approved: approved,
    count: count,
    reason: approved 
      ? "Dhikr verified successfully" 
      : `Only ${count} recitations detected. Need 33.`,
    confidence: 0.95,
    detected_text: transcribedText
  }
};
```

### 3. IF Node

**Condition:**
- Value 1: `{{$json["count"]}}`
- Operation: Larger or Equal
- Value 2: `33`

**True Branch:** Return success
**False Branch:** Return rejection

### 4. Respond to Webhook Node

**True Branch (Approved):**
```json
{
  "approved": true,
  "reason": "Great job! Dhikr verified.",
  "count": "{{$json['count']}}"
}
```

**False Branch (Rejected):**
```json
{
  "approved": false,
  "reason": "Only {{$json['count']}} recitations detected. Please recite 33 times.",
  "count": "{{$json['count']}}"
}
```

---

## 🤖 Recommended AI Services for n8n

### Option 1: OpenAI Whisper (Best!)
- Add OpenAI node
- Model: whisper-1
- Input: Audio file from webhook
- Output: Transcribed text

### Option 2: AssemblyAI
- Use HTTP Request node
- POST to https://api.assemblyai.com/v2/transcript
- Get transcription results

### Option 3: Google Speech-to-Text
- Use Google Cloud node
- Speech-to-Text operation
- Return text

---

## 🧪 Testing Your Webhook

### Quick Test (without audio):

**Using curl:**
```bash
curl -X POST \
  https://aivaxplus.app.n8n.cloud/webhook-test/7feb29f5-1a33-47f0-a8c7-9397e2d91e75 \
  -H "Content-Type: application/json" \
  -d '{"test": true, "dhikr_type": "Alhamdulillah"}'
```

**Simple Response Node:**
```javascript
return {
  json: {
    approved: true,
    reason: "Test successful!"
  }
};
```

---

## 🚨 Important Notes

### Response Format:
✅ **MUST include:** `approved` field (boolean)  
✅ **SHOULD include:** `reason` field (string)  
⚠️ **Don't change:** Field names must match exactly

### Common Issues:

**Issue:** "Invalid response format"
- **Fix:** Make sure you return `{"approved": true/false}`

**Issue:** "Network error"
- **Fix:** Check webhook is active in n8n
- **Fix:** Verify URL is correct

**Issue:** "Timeout"
- **Fix:** Webhook must respond within 60 seconds
- **Fix:** Process audio faster or increase timeout

---

## 📋 Checklist

Before going live, make sure:

- [ ] n8n workflow is activated
- [ ] Webhook URL is accessible (test with curl)
- [ ] Audio transcription service is configured
- [ ] Function node counts dhikr correctly
- [ ] Response format matches specification
- [ ] Error handling is in place
- [ ] Tested with real audio from app

---

## 🎯 Simple Starter Workflow

If you just want to test quickly:

**Simple n8n Workflow (No AI):**

1. **Webhook Node** - Receives request
2. **Function Node** - Returns this:
```javascript
return {
  json: {
    approved: true,
    reason: "Test mode - always approved",
    confidence: 1.0
  }
};
```
3. **Respond to Webhook** - Sends response

This will approve all recitations for testing!

---

## 🔄 Switching Between Test & Production

**In your app (`PracticeSessionView.swift`):**

**For TESTING (always approve):**
```swift
// Comment out real webhook
// webhookService.verifyDhikrRecording(audioData: audioData, dhikrType: title) { result in

// Use mock
webhookService.mockVerification(success: true) { result in
    handleVerificationResult(result)
}
```

**For PRODUCTION (real AI check):**
```swift
// Use real webhook (current setting)
webhookService.verifyDhikrRecording(audioData: audioData, dhikrType: title) { result in
    handleVerificationResult(result)
}
```

---

## 🎉 You're All Set!

Your app is now connected to your n8n webhook!

**Next steps:**
1. Build your n8n workflow (use examples above)
2. Test with the simple workflow first
3. Add AI transcription when ready
4. Test with real audio from your app
5. Go live! 🚀

Need help with the n8n workflow? Let me know! 💪

