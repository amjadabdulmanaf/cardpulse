# Privacy Policy for CardPulse

**Effective Date:** September 26, 2026  
**Last Updated:** September 26, 2026  

**CardPulse** ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how CardPulse handles your information when you use our Android application.

CardPulse is designed from the ground up as a **100% offline, air-gapped, on-device financial management and spend analytics application**.

---

## 1. Zero Cloud & 100% Offline Architecture

CardPulse operates without any external servers or cloud databases. 
* **No Account Required:** You do not need to create an account, sign in, or provide any personal identification (such as name, email address, or phone number) to use CardPulse.
* **No Server Connections:** The app does not transmit, upload, or sync any data to external servers, cloud storage, or third-party analytical platforms.
* **No Network Permissions:** CardPulse does not request or require internet permissions (`android.permission.INTERNET`). Your data physically cannot leave your Android device.

---

## 2. Information Handled on Your Device

All financial data you input or auto-detect using CardPulse remains strictly within your device's encrypted local storage (`SharedPreferences` and local SQLite enclave).

### A. Credit Card Details
* You may log credit card nicknames, bank names, masked last 4 digits, monthly spend limits, and billing generation dates.
* **Security:** Full 16-digit card numbers, CVVs, PINs, or passwords are **never requested and never stored**.

### B. SMS Permission & Local On-Device Parsing
* **Use Case:** CardPulse includes an optional local SMS parsing engine to detect transactional bank debit alerts (e.g., spend amount, merchant name, and date).
* **100% On-Device Processing:** Reading and parsing of SMS messages occurs entirely on your device using local regular expressions.
* **No Transmission:** SMS body text and telemetry are processed in memory and are never uploaded, logged to cloud services, or shared with third parties.
* **Optional Control:** You can disable "Auto-read Bank SMS" at any time in the app Settings, or trigger scans manually via button press.

### C. EMI Schedules & Spend Logs
* Custom EMI installment schedules, interest allocations, and spend attributions (self vs. shared/peer) are stored exclusively in your local device vault.

---

## 3. Data Sharing & Third-Party Analytics

* **No Data Sharing:** We do not sell, rent, trade, or share any user data with any third party.
* **No Advertising SDKs:** CardPulse contains zero third-party advertising frameworks, tracking pixels, or marketing SDKs.
* **No Analytics:** We do not collect crash reports, usage metrics, or telemetry.

---

## 4. Data Security & Storage

All application data is encrypted at rest using Android's native local security framework. Your financial records remain isolated within the CardPulse local application sandbox on your device.

---

## 5. User Data Control & Deletion

Since all data is stored locally on your device, you have complete control over your data:
* **Clear Transaction Cache:** You can flush the parsed SMS cache at any time under `Settings -> Clear Transaction Cache`.
* **Purge All Data:** You can permanently erase all cards, transactions, and EMI schedules under `Settings -> Purge All Data`.
* **Uninstalling the App:** Uninstalling CardPulse automatically and permanently deletes all local data stored by the app.

---

## 6. Children's Privacy

CardPulse does not knowingly collect or solicit any personal information from children under the age of 13.

---

## 7. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. Any changes will be reflected by updating the "Last Updated" date at the top of this document.

---

## 8. Contact Us

If you have any questions or suggestions regarding this Privacy Policy, please contact us at:  
**Email:** support@cardpulse.app  
**Website:** https://cardpulse.app
