# RevenueCat Key - Na Continue Klikken

## ✅ Je hebt DeviceCheck geselecteerd - Dat is prima!

DeviceCheck blokkeert RevenueCat niet. Je kunt het gewoon gebruiken.

---

## 📋 Volgende Stappen

### Stap 1: Continue Klikken

1. **Klik op "Continue"** (rechtsboven)
2. Je ziet nu een nieuwe pagina met key details

---

### Stap 2: Download P8 Key

1. **Je ziet een waarschuwing:**
   - "You can download your key only once"
   - ⚠️ **BELANGRIJK:** Download het bestand direct!

2. **Klik op "Download"** knop
3. **Het bestand wordt gedownload:**
   - Bestandsnaam: `AuthKey_XXXXXXXX.p8`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`
   - **Bewaar dit bestand veilig!**

4. **Noteer de Key ID:**
   - Je ziet een **Key ID** (10 karakters)
   - Bijvoorbeeld: `YSYR6LN4R2`
   - **Schrijf dit op of kopieer het!**

---

### Stap 3: Noteer Issuer ID

1. **Ga terug naar de Keys lijst:**
   - Klik op "< All Keys" (bovenaan)
   - Of ga naar: Certificates, Identifiers & Profiles → Keys

2. **Bovenaan de Keys pagina zie je:**
   - **Issuer ID:** `691fae94-1da3-42e7-9ca6-f4bd4d13609b` (of jouw UUID)
   - **Dit is je Issuer ID**
   - **Schrijf dit op of kopieer het!**

---

### Stap 4: Upload in RevenueCat

Nu heb je:
- ✅ P8 bestand gedownload (`AuthKey_XXXXXXXX.p8`)
- ✅ Key ID genoteerd (10 karakters)
- ✅ Issuer ID genoteerd (UUID)

### Upload in RevenueCat:

1. **Ga naar RevenueCat Dashboard:**
   - [app.revenuecat.com](https://app.revenuecat.com)
   - Selecteer project: **Scrolldeeds**

2. **Ga naar "Apps & providers"**
   - Klik in linker menu

3. **Configureer je app:**
   - Klik op "Scrolldeeds (App Store)" of "+ New" → "App Store app"

4. **Vul in:**
   - **App name:** `Scrolldeeds (App Store)`
   - **App Bundle ID:** `com.scrolldeeds.app`

5. **Upload P8 Key:**
   - Klik op upload vak of "Choose File"
   - Selecteer: `AuthKey_XXXXXXXX.p8` (het bestand dat je downloadde)

6. **Vul Key ID in:**
   - **Key ID:** `YSYR6LN4R2` (jouw Key ID)

7. **Vul Issuer ID in:**
   - **Issuer ID:** `691fae94-1da3-42e7-9ca6-f4bd4d13609b` (jouw Issuer ID)

8. **Klik "Save changes"**

✅ **Error zou nu weg moeten zijn!**

---

## ⚠️ Belangrijke Waarschuwingen

### P8 Bestand:
- ⚠️ Je kunt het **maar 1x downloaden**
- ⚠️ **Bewaar het veilig!** (bijvoorbeeld in een password manager)
- ⚠️ Als je het verliest, moet je een nieuwe key maken

### Key ID en Issuer ID:
- ⚠️ **Noteer beide!** Je hebt ze nodig in RevenueCat
- ⚠️ Key ID: 10 karakters (bijvoorbeeld `YSYR6LN4R2`)
- ⚠️ Issuer ID: UUID format (bijvoorbeeld `691fae94-1da3-42e7-9ca6-f4bd4d13609b`)

### DeviceCheck:
- ✅ **Geen probleem!** DeviceCheck blokkeert RevenueCat niet
- ✅ Je kunt het gewoon gebruiken
- ✅ RevenueCat heeft DeviceCheck niet nodig, maar het doet geen kwaad

---

## ✅ Checklist

- [ ] "Continue" geklikt
- [ ] P8 bestand gedownload (`AuthKey_XXXXXXXX.p8`)
- [ ] Key ID genoteerd (10 karakters)
- [ ] Issuer ID genoteerd (UUID)
- [ ] P8 bestand veilig bewaard
- [ ] In RevenueCat geüpload
- [ ] Key ID ingevuld in RevenueCat
- [ ] Issuer ID ingevuld in RevenueCat
- [ ] "Save changes" geklikt
- [ ] Error is weg!

---

## 🎯 Volgende Stap

Na het oplossen van de error in RevenueCat:

1. **Products toevoegen:**
   - Ga naar "Product catalog" → "Products"
   - Klik "+ New"
   - Voeg `com.scrolldeeds.premium.monthly` toe
   - Voeg `com.scrolldeeds.premium.yearly` toe

2. **Entitlement maken:**
   - Ga naar "Entitlements"
   - Maak `Scrolldeeds Pro` entitlement
   - Koppel beide products

---

**Laat weten als je klaar bent of als je hulp nodig hebt!** 🚀

