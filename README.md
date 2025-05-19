## ⚠️ Version 1.4 had some app-breaking bugs, so I removed it for now. I will upload it again later with fixes and an updated UI once they are complete. ⚠️

# 📱 Scrcpy-GUI

Scrcpy-GUI is a lightweight user interface built with .NET MAUI for interacting with [scrcpy v3.2](https://github.com/Genymobile/scrcpy) — one of my favorite and most used open-source tools. Scrcpy by itself is a command-line project that allows you to stream and control your **Android** device on your PC in several powerful ways. This app was created both as an experiment to explore .NET MAUI and to make scrcpy more user-friendly.

With Scrcpy-GUI, you can:
- Easily generate more complex scrcpy command-line arguments
- Get full control of the Virtual displays and the ability to launch apps in there like launchers or gaming frontends

<img src="https://github.com/user-attachments/assets/b8c39a27-ad50-4448-b6f5-848c7c3ee562" width="40%" />
<img src="https://github.com/user-attachments/assets/bceb0eb0-8eae-42af-a0ff-48ccad6600e8" width="40%" />
<img src="https://github.com/user-attachments/assets/02a241a7-2777-460d-bba0-28735659fa01" width="40%" />
<img src="https://github.com/user-attachments/assets/5c41fb03-2f37-4046-9944-a0e1a2dbbd6e" width="40%" />
<img src="https://github.com/user-attachments/assets/ff5f60e9-5356-4a19-9c17-5b74cccfb973" width="40%" />
<img src="https://github.com/user-attachments/assets/8ad9d747-f3a8-4706-a11b-7d8171418fef" width="40%" />


<h2>🛠️ Installation Steps (for windows):</h2>

### 1. Install Scrcpy</ul>
  ```
  winget install --exact Genymobile.scrcpy
  ```
### 2. Install ADB</ul>
  ```
  winget install --exact "Android SDK Platform-Tools"
  ```
### 3. In your Android device enable USB Debugging from Developer Options</ul>
### 4. Download and run the latest [release](https://github.com/GeorgeEnglezos/Scrcpy-GUI/releases/latest) from my repo</ul>

# ✅ TODO
- Improve error handling and user feedback
