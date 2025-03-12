# PillMate: Smart Pill Dispenser & Reminder

## 📌 Overview

PillMate is an IoT-powered smart pill dispenser and reminder system designed to help users manage their medication intake efficiently. The system consists of a hardware-based pill dispenser and a mobile application built using Flutter.

Users can assign pills to different compartments in the hardware dispenser, set pill counts in the app, and configure reminder schedules based on dosage frequency. When it's time to take a pill, the app triggers an alarm ringtone and sends a notification. It also alerts users when their pill stock is running low.

## 🚀 Features

- **Pill Management**: Assign pills to designated compartments and set initial pill count.
- **Smart Reminders**: Schedule reminders for daily, weekly, and multiple daily dosages.
- **Low Stock Alerts**: Receive notifications when pills in a compartment are running low.
- **Automated Dispensing**: Hardware releases pills at scheduled times.
- **Alarm & Notifications**: Plays an alarm ringtone and shows a notification when it’s time to take a pill.
- **User-Friendly UI**: Built using Flutter for a seamless experience across devices.

## 🏗️ Tech Stack

- **Hardware**: Microcontroller (ESP32), Servo motors for dispensing, Sensors for stock monitoring.
- **Software**:
  - Mobile App: **Flutter (Dart)**
  - Backend: **Firebase / Node.js** (for notifications and data storage)
  - IoT Communication: **HTTP API**

## 📱 How It Works

1. **Setup Hardware**: Place pills in their respective compartments.
2. **Configure App**: Add pill details, set count, and define reminder schedules.
3. **Receive Alerts**: The app notifies the user when it's time to take a pill.
4. **Dispensing**: The hardware releases the pill automatically at the scheduled time.
5. **Monitor Stock**: The app notifies the user when pill levels are low.

## 🛠️ Installation

```sh
# Clone the repository
git https://github.com/OmarAtef0/PillMate-Smart-Pill-Dispenser-Reminder.git

# Navigate to the project folder
cd PillMate-Smart-Pill-Dispenser-Reminder

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🔗 Future Enhancements

- Integration with voice assistants like Alexa & Google Assistant.
- Cloud backup for pill history & reminders.
- Multi-user support for caregivers.
- AI-based dosage recommendations.

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.


