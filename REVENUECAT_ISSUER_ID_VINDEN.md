# Waar Vind Je Issuer ID?

## 📍 Locatie: Apple Developer Portal

### Stap 1: Ga naar Keys Pagina

1. **Open:** [developer.apple.com](https://developer.apple.com)
2. **Login** met je Apple Developer account
3. **Klik op:** "Certificates, Identifiers & Profiles"
4. **In het linker menu**, klik op **"Keys"**

---

### Stap 2: Vind Issuer ID

**Issuer ID staat BOVENAAN de Keys pagina!**

1. **Kijk naar de TOP van de pagina**
2. **Je ziet een sectie met:**
   - **"Issuer ID"** label
   - Gevolgd door een UUID (lange code met streepjes)
   - Bijvoorbeeld: `57246542-96fe-1a63-e053-0824d0110`

3. **Dit is je Issuer ID!**
   - Kopieer het of schrijf het op
   - Je hebt het nodig in RevenueCat

---

## 📸 Wat Je Ziet

Op de Keys pagina zie je bovenaan:

```
┌─────────────────────────────────────┐
│ Issuer ID                            │
│ 57246542-96fe-1a63-e053-0824d0110   │
└─────────────────────────────────────┘
```

**Dit is je Issuer ID!**

---

## 🔍 Alternatieve Locaties

### Optie 1: In App Store Connect

1. **Ga naar:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Klik op je naam** (rechtsboven)
3. **Selecteer:** "Users and Access"
4. **Klik op tab:** "Keys" (als het er is)
5. **Bovenaan zie je:** Issuer ID

---

### Optie 2: Via API

Als je het niet kunt vinden:

1. **Issuer ID is hetzelfde voor alle keys in je account**
2. **Het staat altijd bovenaan de Keys pagina**
3. **Format:** `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` (UUID)

---

## ⚠️ Belangrijk

- **Issuer ID is hetzelfde voor alle keys** in je Apple Developer account
- **Je hoeft het maar 1x te noteren**
- **Format:** UUID met streepjes (bijvoorbeeld: `57246542-96fe-1a63-e053-0824d0110`)
- **Het verandert niet** (tenzij je account wordt gewijzigd)

---

## 📋 Checklist

- [ ] Ga naar developer.apple.com
- [ ] Login
- [ ] Certificates, Identifiers & Profiles → Keys
- [ ] Kijk bovenaan de pagina
- [ ] Issuer ID is zichtbaar
- [ ] Kopieer of noteer het

---

## 🆘 Als Je Het Niet Vindt

### Check:

1. **Ben je ingelogd?**
   - Check of je Apple Developer account actief is

2. **Heb je toegang tot Keys?**
   - Je moet Account Holder of Admin zijn

3. **Probeer deze directe link:**
   ```
   https://developer.apple.com/account/resources/authkeys/list
   ```

4. **Scroll naar boven:**
   - Issuer ID staat altijd bovenaan de Keys pagina
   - Soms moet je scrollen als je veel keys hebt

---

**Issuer ID staat bovenaan de Keys pagina in Apple Developer!** 🚀

