# RevenueCat Key Maken - Stap voor Stap

## ✅ Je bent op de juiste plek!

Je ziet nu "Register a New Key" in Apple Developer. Volg deze stappen:

---

## 📋 Stap 1: Vul Key Details In

### 1.1 Key Name

1. **Klik in het "Key Name" veld**
2. **Type:** `RevenueCat Subscription Key`
   - Of een andere naam die je wilt
   - ⚠️ **Geen speciale karakters:** @, &, *, ', `, .

### 1.2 Key Usage Description (optioneel)

1. **Klik in het "Key Usage Description" veld**
2. **Type:** `For RevenueCat subscription management`
   - Dit is optioneel, maar handig voor later

---

## 📋 Stap 2: Selecteer Services

### ⚠️ BELANGRIJK: Welke service heb je nodig?

Voor RevenueCat heb je **GEEN** van deze services nodig! 

**RevenueCat gebruikt de App Store Connect API**, die automatisch beschikbaar is wanneer je een key maakt.

### Wat te doen:

1. **Laat ALLE services UITGESCHAKELD** (geen radio buttons aanvinken)
2. **Klik direct op "Continue"** (rechtsboven)

---

## 📋 Stap 3: Download Key

Na het klikken op "Continue":

1. **Je ziet een waarschuwing:**
   - "You can download your key only once"
   - ⚠️ **BELANGRIJK:** Download het bestand direct!

2. **Klik op "Download"** knop
3. **Het bestand wordt gedownload:**
   - Bestandsnaam: `AuthKey_XXXXXXXX.p8`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`
   - **Bewaar dit bestand veilig!**

3. **Noteer de Key ID:**
   - Je ziet een **Key ID** (10 karakters)
   - Bijvoorbeeld: `YSYR6LN4R2`
   - **Schrijf dit op!**

---

## 📋 Stap 4: Noteer Issuer ID

### Waar vind je Issuer ID?

1. **Ga terug naar de Keys lijst:**
   - Klik op "< All Keys" (bovenaan)
   - Of ga naar: Certificates, Identifiers & Profiles → Keys

2. **Bovenaan de Keys pagina zie je:**
   - **Issuer ID:** `691fae94-1da3-42e7-9ca6-f4bd4d13609b` (of jouw UUID)
   - **Dit is je Issuer ID**
   - **Schrijf dit op!**

---

## 📋 Stap 5: Upload in RevenueCat

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

---

## 🆘 Troubleshooting

### "Continue" knop werkt niet?

**Check:**
- Key Name is ingevuld?
- Geen speciale karakters in Key Name?
- Alle services zijn uitgeschakeld? (niet nodig voor RevenueCat)

### Key ID niet zichtbaar?

**Oplossing:**
- Na het klikken op "Continue" en downloaden
- Ga terug naar "All Keys"
- Je ziet je key in de lijst met Key ID

### Issuer ID niet gevonden?

**Oplossing:**
- Ga naar: Certificates, Identifiers & Profiles → Keys
- Bovenaan de pagina staat "Issuer ID"
- Dit is hetzelfde voor alle keys in je account

---

## ✅ Checklist

- [ ] Key Name ingevuld: `RevenueCat Subscription Key`
- [ ] Geen services geselecteerd (alle uitgeschakeld)
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

**Volg deze stappen en laat weten als je klaar bent!** 🚀

