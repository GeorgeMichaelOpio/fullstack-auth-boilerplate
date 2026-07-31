# Flutter Auth Client

The Flutter client for the [fullstack-auth-boilerplate](https://github.com/GeorgeMichaelOpio/fullstack-auth-boilerplate) project. Handles user signup, login, and a protected profile page, talking to the Express/MongoDB API in `../backend`.

## Features

- User registration (signup)
- User login
- JWT-based authentication
- Protected profile page
- Basic profile information display

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart SDK (bundled with Flutter)
- Node.js and MongoDB (for the backend — see below)

## Installation

Clone the full repo (this is a client inside a larger project, not a standalone repo):

```bash
git clone https://github.com/GeorgeMichaelOpio/fullstack-auth-boilerplate.git
cd fullstack-auth-boilerplate/frontend
```

Install dependencies and run:

```bash
flutter pub get
flutter run
```

## Backend setup

This client needs the API running to function. From the repo root:

```bash
cd ../backend
npm install
npm start
```

See the [root README](../README.md) for full backend setup, including `.env` configuration.

## Technologies used

- Flutter
- Dart
- Dio (HTTP client)

## Contributing

Issues and PRs welcome — see the [root README](../README.md) for the full project overview.
