# 📄 DocuSign Connector for Business Central

This Business Central extension integrates **DocuSign** with **Sales Documents** (Quotes, Orders, Invoices, etc.), allowing users to send documents for digital signature, track their status, and download signed files directly within Business Central.

---

## 🚀 Features

- 🔐 **OAuth 2.0 Authorization** with DocuSign (Authorization Code + Refresh Token flow)  
- 📤 **Send Sales Documents** (e.g., Sales Orders) as PDFs to DocuSign for signing  
- 📑 **Automatic Log Tracking** in a custom **DocuSign Log** table  
- ⏳ **Check Envelope Status** (Sent, Delivered, Completed, Declined, etc.)  
- 📥 **Download Signed Documents** directly into Business Central  
- 🛠️ **Configurable Setup** for DocuSign credentials and redirect URI  

---

## 📂 Project Structure

- **Codeunit 50100 "DocuSign Management"** → Handles DocuSign API calls (Send, Status, Download)  
- **Table 50100 "DocuSign Setup"** → Stores account credentials, tokens, redirect URI  
- **Table 50101 "DocuSign Log"** → Tracks each envelope request, recipients, envelope ID, status  

---

## ⚙️ Setup

1. **Create a DocuSign Developer Account**  
   👉 [https://developers.docusign.com](https://developers.docusign.com)

2. **Register an App in DocuSign Admin**  
   - Generate **Client ID (Integration Key)** and **Client Secret**  
   - Configure **Redirect URI** (same as your BC environment)

3. **Configure Business Central Setup**  
   - Navigate to **DocuSign Setup**  
   - Fill in:  
     - Client ID  
     - Client Secret  
     - Redirect URI  
     - Account ID  

4. **Get Authorization Code**  
   - Run **Get Authorization Code** action in BC  
   - Login to DocuSign & grant access  
   - Copy & paste the generated **Authorization Code** into BC setup  

5. **Access Token Fetch**  
   - The extension exchanges **Authorization Code** for **Access Token** & **Refresh Token**  
   - Tokens are refreshed automatically before expiry  

---

## 🖥️ Usage

1. **Send Document**  
   - Open a **Sales Order** → Action **Send with DocuSign**  
   - Log entry created in **DocuSign Log**  
   - Envelope sent to DocuSign  

2. **Track Status**  
   - Run **Get Envelope Status** on the log  
   - See live updates (Sent, Delivered, Completed, etc.)  

3. **Download Signed PDF**  
   - Run **Download Signed Document**  
   - Signed file retrieved & stored in BC  

---

## 🧪 Testing

- Create a **Sales Order** with customer email  
- Send using **DocuSign** → Verify log entry  
- Open DocuSign email & sign document  
- Run **Get Status** → Should show *Completed*  
- Run **Download Document** → PDF available in BC  

---

## 🔒 Security Notes

- Tokens securely stored in **DocuSign Setup**  
- Access Token auto-refresh implemented  
- HTTPS with Bearer authentication used in all API calls  

---

## 📌 API Endpoints Used

- **OAuth Token** → `https://account-d.docusign.com/oauth/token`  
- **Envelope Creation** → `https://demo.docusign.net/restapi/v2.1/accounts/{accountId}/envelopes`  
- **Envelope Status** → `.../envelopes/{envelopeId}`  
- **Signed Document Download** → `.../envelopes/{envelopeId}/documents/{documentId}`  

---

## 🛠️ Requirements

- Microsoft Dynamics 365 Business Central (SaaS/OnPrem)  
- DocuSign Developer Account with API access  
- AL Development Environment (VS Code + AL Language Extension)  

---

## 📖 Future Enhancements

- ✅ Multi-recipient support with signing order  
- ✅ Automatic attachment of signed PDFs to Sales Orders  
- ✅ Retry mechanism for failed API calls  
- ✅ Extended support for Quotes, Invoices, Credit Memos  

---

👨‍💻 **Author:** Premkumar
📅 **Version:** 1.0.0.0