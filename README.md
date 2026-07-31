# Fullstack Auth Boilerplate

A production-style authentication starter kit: a Flutter client talking to a Node.js/Express API, with MongoDB for storage and JWTs for session security. Built as a reusable foundation for any app that needs sign-up/login out of the box, rather than a one-off tutorial project.

**Stack:** Flutter (Dart) · Node.js / Express · MongoDB · JWT · Dio

## Features

- User registration and login with hashed passwords
- JWT-based session authentication
- Middleware-protected API endpoint that validates the token before granting access
- Flutter client using Dio for HTTP requests, with token persistence across the auth flow
- MongoDB schema for user storage

## Architecture

```
frontend/       → Flutter client (UI, auth state, API calls via Dio)
backend/        → Express server (routes, JWT middleware, MongoDB models)
backend/seed/   → Sample data / seed files
```

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js
- MongoDB (local instance or Atlas connection string)

### Installation

Clone the repo:

```bash
git clone https://github.com/GeorgeMichaelOpio/fullstack-auth-boilerplate.git
cd fullstack-auth-boilerplate
```

**Backend setup:**

```bash
cd backend
npm install
```

Create a `.env` file in `backend/` with:

```
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_secret_key
```

Start the server:

```bash
npm start
```

**Frontend setup:**

```bash
cd ../frontend
flutter pub get
flutter run
```

## API Endpoints

| Method | Endpoint | Description | Auth required |
|--------|-----------|--------------|----------------|
| POST | `/signup` | Register a new user | No |
| POST | `/login` | Authenticate and receive a JWT | No |
| GET | `/protected` | Sample endpoint gated behind valid JWT | Yes |

## Roadmap / Ideas for extension

- [ ] Refresh token support
- [ ] Password reset flow
- [ ] Rate limiting on auth endpoints
- [ ] Unit tests for the Express routes

## Contributing

Issues and PRs welcome — this is meant to be a starting point others can build on.

## License

MIT
