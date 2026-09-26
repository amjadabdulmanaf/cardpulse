# Google Play Store Listing Copy for CardPulse

---

## 1. App Title (Max 30 Chars)
`CardPulse: Credit Card & EMIs`

---

## 2. Short Description (Max 80 Chars)
`100% offline credit card spend tracker, EMI schedule manager & SMS spend parser.`

---

## 3. Full Description (Max 4000 Chars)

```text
Take total control of your credit cards, monthly billing cycles, and EMI liabilities with CardPulse — the 100% offline, privacy-first credit card manager and spend analytics engine.

CardPulse operates entirely on your Android device without cloud databases, tracking SDKs, or internet connectivity. Your financial records, card limits, and EMI schedules remain strictly within your encrypted local vault.

========================================
KEY FEATURES
========================================

💳 CREDIT CARD CYCLE TRACKER
• Track active billing cycles, bill generation dates, and days remaining to reset for all your credit cards.
• Monitor combined credit limit utilization and available credit buffer in real-time.
• Custom alert thresholds notify you before reaching card limits.

📅 EMI LIABILITY & SCHEDULE MANAGER
• Plan and track custom month-by-month EMI repayment schedules.
• Auto-calculate principal sums, interest outflows, and first installment dues.
• Easily track shared/peer EMIs and family contributions.

📱 LOCAL ON-DEVICE SMS SPEND PARSER
• Auto-detect bank debit SMS alerts offline using intelligent local regex patterns.
• Instant local deduplication prevents double-counting transactions.
• Full control: Toggle auto-read on or off at any time, or scan manually on demand.

🎨 METRO LIVE TILE UI & ANIMATIONS
• Inspired by Windows 8 Metro Live Tile design with fluid 3D entrance flips, animated progress bars, and number count-up effects.
• Interactive bottom navigation with dynamic screen transitions.

🔒 100% PRIVACY & AIR-GAPPED VAULT
• Zero Internet Required: CardPulse operates 100% offline. Your data physically cannot leave your phone.
• No Account Required: No sign-up, no passwords, no email collection.
• Encrypted Local Storage: All data stays in your local device sandbox.

========================================
WHY CHOOSE CARDPULSE?
========================================
Unlike traditional expense managers that upload your sensitive financial bank SMS data to cloud servers, CardPulse guarantees 100% data sovereignty. Manage your financial health with complete peace of mind.

Download CardPulse today and master your credit cards and EMIs offline!
```

---

## 4. Google Play Data Safety Questionnaire Answers

### Section: Data Collection & Security
* **Does your app collect or share any of the required user data types?**  
  👉 **NO** (Select "No, the app does not collect or share user data").
* **Is all user data processed locally on the device?**  
  👉 **YES** (All data is processed strictly on-device in local memory/vault).
* **Is data encrypted in transit?**  
  👉 **N/A** (No data is transmitted over the network).
* **Do you provide a way for users to request that their data be deleted?**  
  👉 **YES** (Users can clear cache or purge all local data instantly inside app Settings, or uninstall the app).

---

## 5. Sensitive Permissions Declaration (READ_SMS)

When submitting the **Permissions Declaration Form** in Google Play Console for `android.permission.READ_SMS`:

* **Core Exemption Category:** Financial / Spend Management
* **Justification Statement:**  
  *"CardPulse uses READ_SMS solely on-device to auto-detect bank debit alerts and compute monthly credit card cycle spends and EMI dues. SMS parsing occurs 100% locally in memory using regular expressions. No SMS body or financial data is ever uploaded, transmitted, or shared with external servers or third parties."*

---

## 6. What's New / Release Notes (v1.0.0)
```text
• Initial release of CardPulse - Offline Credit Card & EMI Manager!
• Track credit card billing cycles, limit utilization, and reset days.
• Plan month-by-month EMI schedules with principal and interest distribution.
• Auto-parse bank SMS debits offline with local deduplication.
• Metro Live Tile theme with 3D tile flips, animated counters, and progress indicators.
• 100% offline local storage with zero cloud transmission.
```
