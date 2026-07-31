// Import required packages and modules
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');

// Load environment variables from a .env file
require('dotenv').config();

// Create an instance of the Express application
const app = express();
const PORT = process.env.PORT || 3000;

// Enable Cross-Origin Resource Sharing (CORS) for the Express app
app.use(cors());

// Set up the secret key for JWT and parse JSON requests
const secretKey = process.env.SECRET_KEY;
if (!secretKey) {
  throw new Error('SECRET_KEY is not set in the environment');
}
app.use(express.json());

// Number of bcrypt salt rounds — 10 is a reasonable default balance of security vs. speed
const SALT_ROUNDS = 10;

// How long issued JWTs stay valid
const TOKEN_EXPIRY = '1h';

// Set up MongoDB connection details
const uri = process.env.MONGODB_URI;
const client = new MongoClient(uri);
let db;

// Function to connect to the MongoDB database
async function connectToDatabase() {
  await client.connect();
  console.log('Connected to MongoDB');
  db = client.db('auth_demo');

  // Enforce unique emails at the database level, not just in application code
  await db.collection('users').createIndex({ email: 1 }, { unique: true });
}

// Connect to the MongoDB database
connectToDatabase().catch((err) => {
  console.error('Failed to connect to MongoDB:', err);
  process.exit(1);
});

// Strip sensitive fields before sending a user object back to the client
function sanitizeUser(user) {
  const { password, ...safeUser } = user;
  return safeUser;
}

// Middleware to authenticate users using JWT
const authenticateUser = async (req, res, next) => {
  // Extract JWT token from the Authorization header
  // Supports both "Bearer <token>" and a raw token for convenience
  const authHeader = req.header('Authorization');
  if (!authHeader) return res.status(401).json({ message: 'Unauthorized' });
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

  try {
    // Verify the JWT token and retrieve user information from the database
    const decoded = jwt.verify(token, secretKey);
    const user = await db.collection('users').findOne({ _id: new ObjectId(decoded.id) });
    if (!user) {
      return res.status(401).json({ message: 'Invalid token' });
    }
    // Attach user information to the request object for further use
    req.user = sanitizeUser(user);
    next();
  } catch (error) {
    // Handle invalid or expired tokens
    res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// Endpoint for user registration (signup)
app.post('/signup', async (req, res) => {
  try {
    // Extract user information from the request body
    const { email, password, first_name, last_name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    // Check if the user already exists in the database
    const existingUser = await db.collection('users').findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'A user with that email already exists' });
    }

    // Hash the password before storing it — never store or log plaintext passwords
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

    // Create a new user object
    const newUser = {
      email,
      password: hashedPassword,
      first_name,
      last_name,
    };

    // Insert the new user into the database
    const result = await db.collection('users').insertOne(newUser);

    // Create a JWT token for the new user
    const token = jwt.sign({ id: result.insertedId, email: newUser.email }, secretKey, {
      expiresIn: TOKEN_EXPIRY,
    });

    // Respond with the token and sanitized user information (no password hash)
    res.status(201).json({ token, user: sanitizeUser({ ...newUser, _id: result.insertedId }) });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Something went wrong during signup' });
  }
});

// Endpoint for user login
app.post('/login', async (req, res) => {
  try {
    // Extract login credentials from the request body
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find the user in the database based on email only — never query by raw password
    const user = await db.collection('users').findOne({ email });

    // Compare the submitted password against the stored bcrypt hash.
    // Same generic error whether the email doesn't exist or the password is wrong,
    // so an attacker can't use the response to enumerate valid emails.
    const passwordMatches = user ? await bcrypt.compare(password, user.password) : false;
    if (!user || !passwordMatches) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Create a JWT token for the authenticated user
    const token = jwt.sign({ id: user._id, email: user.email }, secretKey, {
      expiresIn: TOKEN_EXPIRY,
    });

    // Respond with the token and sanitized user information
    res.json({ token, user: sanitizeUser(user) });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Something went wrong during login' });
  }
});

// Protected endpoint that requires user authentication
app.get('/protected', authenticateUser, (req, res) => {
  // Respond with the user information obtained from the authentication middleware
  res.json({ user: req.user });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});