# Backend — Express + MongoDB API

The API for the [fullstack-auth-boilerplate](https://github.com/GeorgeMichaelOpio/fullstack-auth-boilerplate) project. Handles user signup, login, and JWT-based authentication for the Flutter client in `../frontend`.

## Stack

Node.js · Express · MongoDB · JWT · bcrypt

## Prerequisites

- [Node.js](https://nodejs.org/)
- MongoDB (local instance or an Atlas connection string)

## Setup

Install dependencies:

```bash
npm install
```

Create a `.env` file in this folder (never commit this file — it's already covered by the root `.gitignore`):

```
PORT=3000
MONGODB_URI=your_mongodb_connection_string
SECRET_KEY=your_jwt_secret
```

Start the server:

```bash
npm start
```

## Endpoints

| Method | Endpoint | Description | Auth required |
|--------|-----------|--------------|----------------|
| POST | `/signup` | Register a new user | No |
| POST | `/login` | Authenticate and receive a JWT | No |
| GET | `/protected` | Sample endpoint gated behind a valid JWT | Yes |

Protected requests must include the token in the `Authorization` header, either as `Bearer <token>` or the raw token.

## Security notes

- Passwords are hashed with bcrypt (10 salt rounds) before being stored — the database never holds plaintext passwords, and responses never include the password hash.
- Login returns a generic "Invalid email or password" message whether the email doesn't exist or the password is wrong, so the API doesn't leak which emails are registered.
- Emails are enforced as unique at the database level via a MongoDB index, not just in application code.
- JWTs expire after 1 hour (`SECRET_KEY` must be set — the server refuses to start without it).

## Known limitations

- No refresh tokens — once a token expires, the user must log in again.
- No rate limiting on `/login` or `/signup` — brute-force protection isn't implemented yet.
- No token revocation — a token is valid until it expires; there's no way to invalidate it early (e.g. on logout-everywhere or a compromised account).

See the [root README](../README.md) for the full project overview and roadmap.