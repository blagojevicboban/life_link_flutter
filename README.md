# LifeLink - Advanced Fall Detection Companion App

LifeLink is a Flutter-based companion application designed to work seamlessly with the LifeLink ESP32 wearable device. It provides real-time health monitoring, fall detection, and automated emergency alerts to ensure user safety.

## 🚀 Key Features

### 📡 Real-Time Monitoring
- **Live Metrics**: Displays real-time Heart Rate (BPM), Blood Oxygen (SpO2), and Impact G-Force.
- **BLE Connectivity**: Low-latency Bluetooth Low Energy (BLE) connection to the LifeLink ESP32 wearable.
- **Connection Status**: Instant feedback on connection state and device battery level.

### 🛡️ Advanced Fall Detection
- **3-Stage Logic**: Intelligent detection system tracks states: **Safe** → **Warning** (Potential Fall) → **Alarm** (Fall Confirmed).
- **False Positive Prevention**: Uses impact patterns and post-fall stillness/orientation to verify genuine falls.
- **Countdown Timer**: 5-second (configurable) countdown allows users to cancel false alarms before help is contacted.

### 🆘 Emergency Response
- **Automated SOS**: Automatically executes pre-selected safety actions when a fall is confirmed.
- **Multiple Actions**:
  - **Call**: Directly calls a designated emergency contact.
  - **SMS**: Sends an urgent text message with precise GPS coordinates.
  - **SOS**: Triggers a system-wide SOS intent.
- **Location Tracking**: Captures exact location using phone GPS to help responders find the user.

### 🎨 Modern UI/UX
- **Dark Theme**: Battery-efficient, high-contrast dark interface optimized for visibility.
- **Visual Feedback**: Color-coded status cards (Cyan = Safe, Amber = Warning, Red = Alarm).
- **Intuitive Metrics**: Large, readable fonts and clear iconography for elderly accessibility.

## 🛠️ Installation & Setup

### Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Device**: Configured for development (BLE requires hardware support).

### Steps
1.  **Clone the Repository**
    ```bash
    git clone https://github.com/your-username/life_link.git
    cd life_link
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

4.  **Build for Release**
    ```bash
    flutter build apk --release
    ```
    The output APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Setup (Mac Required)
To build for iOS, you must use a macOS computer with Xcode installed.

1.  **Install CocoaPods**
    ```bash
    cd ios
    pod install
    cd ..
    ```

2.  **Run on Simulator/Device**
    ```bash
    flutter run -d ios
    ```

3.  **Build .ipa**
    ```bash
    flutter build ipa --release
    ```
    *Note: Ensure you have a valid Apple Developer account and signing certificates configured in Xcode.*

### Windows Setup
1.  **Enable Developer Mode**
    - Go to Windows Settings > Update & Security > For developers > Enable Developer Mode.

2.  **Build .exe**
    ```bash
    flutter build windows --release
    ```
    The output executable will be located at: `build/windows/x64/runner/Release/life_link.exe`

## ⚙️ Configuration

Access the **Settings** screen via the gear icon on the dashboard to configure:
- **Emergency Contact**: Name and Phone Number.
- **Fall Action**: Choose between Call, SMS, or SOS.
- **Countdown Duration**: Set the buffer time before alerts are sent.
- **Default Device**: Set a specific LifeLink device MAC address for auto-connection.

## 📱 Permissions
The app requires the following permissions for full functionality:
- `BLUETOOTH_SCAN` & `BLUETOOTH_CONNECT`: To communicate with the wearable.
- `ACCESS_FINE_LOCATION`: For BLE scanning and SOS location sharing.
- `SEND_SMS` & `CALL_PHONE`: To execute emergency actions.

## 🤝 Contribution
Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.
