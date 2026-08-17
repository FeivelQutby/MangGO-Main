# MangGO

MangGO is an IoT-based grading assistant that combines an ESP32-powered hardware device with a native SwiftUI application for iPhone and iPad.

## Repository Structure

```
MangGO-main/
│
├── MangGO/            # SwiftUI application (iPhone & iPad)
│
├── MangGOESP/         # ESP32 firmware (Arduino IDE)
│   ├── firmware/
│   └── tests/
│
├── README.md
└── .gitignore
```

## Components

### 📱 MangGO
- Built with SwiftUI
- Supports iPhone and iPad
- Handles BLE communication with the ESP32
- Displays grading information and camera preview

### 🤖 MangGOESP
- Arduino-based firmware for ESP32-C6
- Interfaces with sensors and peripherals
- Sends data to the mobile application via Bluetooth Low Energy (BLE)

## Development Environment

### Mobile App
- Xcode
- SwiftUI
- iOS / iPadOS

### Firmware
- Arduino IDE
- ESP32 Arduino Core
- ESP32-C6 Dev Module

## Team Workflow

This repository uses a **monorepo** structure, meaning both the mobile application and the ESP32 firmware are maintained in a single repository.

Benefits:
- Single source of truth
- Easier version control
- Easier collaboration between mobile and embedded teams
- Keeps app and firmware versions synchronized

## Status

🚧 Currently under development.
