# GigBank - Fintech App for Gig Workers (MBA Project)

**GigWorker** is a comprehensive fintech ecosystem designed specifically for gig economy workers (Uber, Swiggy, Zomato, etc.). It helps them track daily earnings across platforms, manage a digital wallet, and access instant micro-loans based on their income history.

This project was built as a capstone for an MBA in Fintech to demonstrate **Product Management**, **Business Analytics**, and **Technical Execution**.

---

## 📱 Features

### 1. 🔐 Secure Authentication
* User Registration & Login using **Firebase Auth**.
* Secure cloud storage of user profiles.

### 2. 💰 Digital Wallet System
* Real-time **Wallet Balance**.
* **Add Money** functionality.
* Complete transaction history (Credits/Debits).
* **PDF Statement Generation** (Weekly & Monthly Reports).

### 3. 📊 Earnings Tracker & Analytics
* Track income from specific platforms (Uber, Ola, Swiggy, etc.).
* **Data Visualization:** Interactive Bar Chart showing last 7 days' performance.
* Detailed earning history log.

### 4. 🏦 Micro-Lending System
* **Eligibility Engine:** Analyzes earnings to approve/reject loans.
* **Instant Disbursal:** Loan amount credited to wallet immediately.
* **EMI Repayment:** Users can repay loans directly from their wallet.

### 5. 🛡️ Compliance (KYC)
* KYC Verification flow (Pending -> Approved).
* Document upload simulation.
* Risk profiling for loan applicants.

### 6. 🔔 Smart Notifications
* Local push notifications for "Money Added", "Loan Approved", and "EMI Paid".

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Firebase (Firestore Database, Authentication)
* **State Management:** `setState` & Streams
* **Architecture:** Feature-based folder structure

### Key Packages Used
* `firebase_core` / `cloud_firestore`: Backend integration.
* `fl_chart`: For Analytics and Earnings Bar Chart.
* `pdf` / `printing`: For generating professional bank statements.
* `flutter_local_notifications`: For system alerts.
* `intl`: For currency and date formatting.

---

## 📸 Screenshots

| Dashboard | Wallet | Analytics | Loans |

| | | | |  

*(Note: Add screenshots of your app in the folder and link them here)*

---

## 🚀 How to Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/JKalonewolf/GigWorker.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📄 License
This project is for educational purposes only as part of an MBA curriculum.

**Developed by: Jayakumar L**