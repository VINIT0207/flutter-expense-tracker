<h1 align="center">FinPulse - Smart Expense Tracker 💸</h1>

<p align="center">
  A premium, feature-rich personal finance application built with Flutter. Designed with a modern, intuitive dark-mode interface to help users effortlessly track spending, analyze habits, and achieve their financial goals.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/UI-Dark%20Mode-212121?style=for-the-badge" alt="Dark Mode UI" />
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT" />
</p>

---

## 📑 Table of Contents

- [📱 App Preview](#-app-preview)
- [✨ Key Features](#-key-features)
- [🛠 Tech Stack](#-tech-stack)
- [📂 Folder Structure](#-folder-structure)
- [🚀 Getting Started](#-getting-started)
- [📝 License](#-license)
- [📬 Contact](#-contact)

---

## 📱 App Preview

<p align="center">
  <img src="https://github.com/user-attachments/assets/67313385-b28f-429f-98ca-ba3ff5fa3c37" width="150" alt="Dashboard" />
  <img src="https://github.com/user-attachments/assets/a0adb7dc-4967-42f2-b8f3-1bedf477cb77" width="150" alt="Analytics" />
  <img src="https://github.com/user-attachments/assets/edd0d9be-0089-48af-bf6e-a627b33b87a5" width="150" alt="Transaction History" />
  <img src="https://github.com/user-attachments/assets/e318da72-c949-4480-8e2c-862d78be1bbc" width="150" alt="New Transaction" />
  <img src="https://github.com/user-attachments/assets/22b526bb-b3f4-4a38-b20b-e62a8520e1b9" width="150" alt="Savings Goal" />
</p>

---

## ✨ Key Features

### 📊 Comprehensive Analytics
- Interactive charts and breakdowns of Weekly, Monthly, and Yearly spending patterns.
- Tracks Daily Burn Rate and average transaction sizes.
- Detailed financial insights to help improve spending habits.

### 🎯 Dynamic Savings Goals
- Create and manage savings targets.
- Set deadlines and savings frequencies (Weekly, Monthly, Yearly).
- Track progress toward goals such as vacations, gadgets, or emergency funds.

### 🏷️ Smart Categorization
- Quick-select categories such as:
  - 🍔 Food
  - 🚕 Transport
  - 🛍 Shopping
  - 💡 Bills
  - 🎉 Entertainment
- Mark transactions as:
  - Essential
  - Non-Essential

### 🔍 Advanced Filtering
- Search transaction history instantly.
- Filter by category, date, spending type, or amount.
- Quick filters:
  - Essential Only
  - High Value (> ₹500)

### 📄 Data Portability
- Export transaction history to CSV format.
- Easily back up and analyze data externally.

### 🌑 Premium Dark UI
- Modern dark theme designed for reduced eye strain.
- Clean typography and intuitive navigation.
- Material Design 3 inspired user experience.

---

## 🛠 Tech Stack

| Category | Technology |
|-----------|------------|
| **Framework** | Flutter (Dart) |
| **State Management** | Provider |
| **Local Database** | SQLite / Local Storage |
| **Architecture** | Feature-Based Structure |
| **Design System** | Material 3 Dark Theme |

---

## 📂 Folder Structure

```text
lib/
│
├── data/
│   └── database_helper.dart
│
├── logic/
│   ├── finance_provider.dart
│   └── decision_engine.dart
│
├── models/
│   ├── goal.dart
│   └── transaction.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── history_screen.dart
│   ├── analytics_screen.dart
│   ├── goals_screen.dart
│   └── add_transaction_screen.dart
│
├── utils/
│   └── import_export_helper.dart
│
├── widgets/
│   └── category_grid.dart
│
└── main.dart
```

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project running on your local machine.

### Prerequisites

- Flutter SDK
- Android Studio or VS Code
- Android Emulator / iOS Simulator / Physical Device

### Installation

#### 1. Clone the repository

```bash
git clone https://github.com/VINIT0207/flutter-expense-tracker.git
```

#### 2. Navigate to the project directory

```bash
cd flutter-expense-tracker
```

#### 3. Install dependencies

```bash
flutter pub get
```

#### 4. Run the application

```bash
flutter run
```

---

## License

This project is licensed under the MIT License.

See the LICENSE file for details.

---

## 📬 Contact

### Vinit

- GitHub: @VINIT0207
- Email: sharma.vinit.2007@gmail.com

---

<p align="center">
  Made with ❤️ using Flutter
</p>
