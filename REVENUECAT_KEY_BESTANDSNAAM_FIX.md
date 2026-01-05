# RevenueCat Key Bestandsnaam Error Oplossen

## ⚠️ Error

**"Invalid file name, it should be SubscriptionKey_XXXXXXXXXX.p8"**

Dit betekent dat RevenueCat een subscription key verwacht, maar je hebt waarschijnlijk een gewone App Store Connect API key gedownload.

---

## ✅ Oplossing: Hernoem het Bestand

### Stap 1: Check Bestandsnaam

Je bestand heet waarschijnlijk:
- `AuthKey_YSYR6LN4R2.p8` ❌

RevenueCat verwacht:
- `SubscriptionKey_YSYR6LN4R2.p8` ✅

---

### Stap 2: Hernoem het Bestand

#### Optie A: Via Finder (Mac)

1. **Vind het bestand:**
   - Meestal in: Downloads folder
   - Bestandsnaam: `AuthKey_YSYR6LN4R2.p8`

2. **Hernoem het bestand:**
   - Klik met rechts op het bestand
   - Selecteer "Rename" of druk F2
   - Verander `AuthKey_` naar `SubscriptionKey_`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8` → `SubscriptionKey_YSYR6LN4R2.p8`

3. **Druk Enter** om op te slaan

#### Optie B: Via Terminal (Mac)

1. **Open Terminal**
2. **Ga naar Downloads folder:**
   ```bash
   cd ~/Downloads
   ```

3. **Hernoem bestand:**
   ```bash
   mv AuthKey_YSYR6LN4R2.p8 SubscriptionKey_YSYR6LN4R2.p8
   ```
   (Vervang `YSYR6LN4R2` met jouw Key ID)

---

### Stap 3: Upload Opnieuw in RevenueCat

1. **Ga terug naar RevenueCat**
2. **Verwijder het oude bestand:**
   - Klik op het X icoon naast het geüploade bestand
   - Of klik op "Remove" / "Delete"

3. **Upload het hernoemde bestand:**
   - Klik op upload vak
   - Selecteer: `SubscriptionKey_YSYR6LN4R2.p8` (het hernoemde bestand)
   - Check of de bestandsnaam correct is

4. **Vul Key ID in:**
   - Key ID: `YSYR6LN4R2` (jouw Key ID)

5. **Vul Issuer ID in:**
   - Issuer ID: `57246542-96fe-1a63-e053-0824d0110` (jouw Issuer ID)

6. **Klik "Save changes"**

✅ **Error zou nu weg moeten zijn!**

---

## 🔍 Waarom Dit Gebeurt

Apple downloadt subscription keys soms als `AuthKey_` in plaats van `SubscriptionKey_`. RevenueCat controleert de bestandsnaam om te verifiëren dat het een subscription key is.

**Oplossing:** Hernoem het bestand naar `SubscriptionKey_` prefix.

---

## ⚠️ Belangrijk

- **Bestandsnaam moet beginnen met:** `SubscriptionKey_`
- **Gevolgd door:** Je Key ID (10 karakters)
- **Extensie:** `.p8`
- **Voorbeeld:** `SubscriptionKey_YSYR6LN4R2.p8`

---

## 🆘 Als Error Blijft

### Check:

1. **Bestandsnaam klopt?**
   - ✅ `SubscriptionKey_YSYR6LN4R2.p8`
   - ❌ `AuthKey_YSYR6LN4R2.p8`
   - ❌ `YSYR6LN4R2.p8`

2. **Key ID klopt?**
   - Check of Key ID in bestandsnaam overeenkomt met Key ID veld

3. **Bestand is echt een subscription key?**
   - Als je een gewone App Store Connect API key hebt gemaakt (niet subscription), moet je een nieuwe subscription key maken

---

## 📋 Checklist

- [ ] Bestand hernoemd naar `SubscriptionKey_XXXXXXXXXX.p8`
- [ ] Oude upload verwijderd in RevenueCat
- [ ] Hernoemde bestand geüpload
- [ ] Key ID ingevuld (10 karakters)
- [ ] Issuer ID ingevuld (UUID)
- [ ] "Save changes" geklikt
- [ ] Error is weg!

---

**Hernoem het bestand en probeer opnieuw! Laat weten of het werkt!** 🚀

