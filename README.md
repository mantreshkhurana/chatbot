<img src="./images/app-logo.png" width="50" height="50">

# ChatBot

A cross-platform chatbot app using OpenAI API, built with Flutter. This project enables users to create and customize a chatbot application for Android, iOS, and the Web. Perfect for task automation, personal assistants, or experimental AI integration.

## Table of Contents

- [Screenshots](#screenshots)
- [Features](#features)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Customizing the App](#customizing-the-app)
    - [Change App Name & Package ID](#1-change-app-name--package-id)
    - [Change App Icon](#2-change-app-icon)
- [Flutter Dependencies](#flutter-dependencies)
- [Contributing](#contributing)
- [Author](#author)

## Prerequisites

- Flutter SDK

## Screenshots

![Screenshot 1](/screenshots/screenshot-1.png)

## Features

- Cross-platform support (Android, iOS, Web)
- Uses OpenAI API for conversational AI
- Easy configuration for app name, package ID, and icon
- Flutter-based with support for rapid UI development

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/mantreshkhurana/chatbot.git
cd chatbot
flutter pub get
```

Create a `.env` file in the root directory and add your OpenAI API key:

```env
OPENAI_API=YOUR_OPENAI_API_KEY
```

> **Note:** Replace `YOUR_OPENAI_API_KEY` with your actual OpenAI API key.

---

## Customizing the App

### 1. Change App Name & Package ID

This project uses [`rename`](https://pub.dev/packages/rename) to simplify renaming:

Install the package:

```bash
flutter pub global activate rename
```

Run the command:

```bash
flutter pub global run rename --appname "Your App Name" --bundleId com.yourdomain.yourapp
```

### 2. Change App Icon

We use [`icons_launcher`](https://pub.dev/packages/icons_launcher) to update app icons.

Ensure the following exists in your `pubspec.yaml`:

```yaml
icons_launcher:
  image_path: "assets/images/app-logo.png"
  platforms:
    android:
      enable: true
    ios:
      enable: true
```

Then run:

```bash
flutter pub run icons_launcher:create
```

Replace `assets/images/app-logo.png` with your custom logo file.

---

## Flutter Dependencies

- [rename](https://pub.dev/packages/rename)
- [icons_launcher](https://pub.dev/packages/icons_launcher)

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## Author

- [Mantresh Khurana](https://github.com/mantreshkhurana)
