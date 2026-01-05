# Waar vind je "Keys" in App Store Connect?

## 📍 Locatie van Keys

### Optie 1: In "Users and Access" (Meest Waarschijnlijk)

1. Je bent nu in **"Users and Access"** → **"People"** tab
2. Kijk naar de **tabs bovenaan** naast "People":
   - **People** (waar je nu bent)
   - **Sandbox**
   - **Integrations**
   - **Xcode Cloud**
   - **Keys** ← Hier staat het waarschijnlijk!

3. **Klik op tab "Keys"** (als het er is)

---

### Optie 2: Als aparte sectie in linker menu

1. Kijk in het **linker menu** (onder "Users and Access")
2. Scroll naar beneden
3. Zoek naar **"Keys"** of **"App Store Connect API"**
4. Klik erop

---

### Optie 3: Via Account Settings

1. Klik op je **naam** (rechtsboven)
2. Selecteer **"Preferences"** of **"Account Settings"**
3. Zoek naar **"Keys"** of **"API Keys"**

---

### Optie 4: Directe Link

Probeer deze link:
```
https://appstoreconnect.apple.com/access/api
```

Of:
```
https://appstoreconnect.apple.com/access/users
```
En klik dan op "Keys" tab

---

## 🔍 Als je "Keys" niet ziet

### Mogelijke redenen:

1. **Je hebt geen Admin rechten:**
   - Alleen Account Holder of Admin kan keys zien
   - Check je rol in de "People" tab
   - Je moet "Account Holder" of "Admin" zijn

2. **Keys sectie is verborgen:**
   - Probeer de pagina te refreshen (F5 of Cmd+R)
   - Log uit en log weer in

3. **Je account heeft geen toegang:**
   - Contact de Account Holder
   - Vraag om Admin rechten

---

## ✅ Alternatief: Via Developer Portal

Als je "Keys" niet vindt in App Store Connect:

1. Ga naar [developer.apple.com](https://developer.apple.com)
2. Login met je Apple Developer account
3. Klik op **"Certificates, Identifiers & Profiles"**
4. In het linker menu, klik op **"Keys"**
5. Klik op **"+"** om nieuwe key te maken

---

## 📋 Stap-voor-stap: Keys Maken

### Als je "Keys" hebt gevonden:

1. **Klik op "+" knop** (linksboven)
2. **Vul in:**
   - **Key Name:** `RevenueCat Subscription Key`
   - **Access:** Selecteer **"App Manager"** of **"Admin"**
3. **Klik "Generate"**
4. **Download het .p8 bestand** (je kunt het maar 1x downloaden!)
5. **Noteer:**
   - **Key ID:** (10 karakters, bijvoorbeeld `YSYR6LN4R2`)
   - **Issuer ID:** (UUID, staat bovenaan de Keys pagina)

---

## 🆘 Nog steeds niet gevonden?

### Probeer dit:

1. **Zoek in App Store Connect:**
   - Gebruik de zoekbalk (bovenaan)
   - Zoek naar: `keys` of `API keys`

2. **Check je rol:**
   - Ga naar "Users and Access" → "People"
   - Check of je "Account Holder" of "Admin" bent
   - Als je "App Manager" of lager bent, vraag Admin rechten

3. **Directe URL proberen:**
   ```
   https://appstoreconnect.apple.com/access/api
   ```

4. **Contact Apple Support:**
   - Als niets werkt, contact Apple Developer Support
   - Ze kunnen je helpen met toegang tot Keys

---

## 📸 Wat je zou moeten zien

Wanneer je "Keys" vindt, zie je:
- Een tabel met alle keys die je hebt gemaakt
- Een **"+"** knop om nieuwe key te maken
- Kolommen: Key Name, Key ID, Access, Created, etc.

---

**Laat weten wat je ziet, dan help ik je verder!** 🚀

