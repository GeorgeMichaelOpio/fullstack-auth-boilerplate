// Import required packages and modules
const express = require('express');
const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
const cors = require('cors');

// Load environment variables from a .env file
require('dotenv').config();

// Create an instance of the Express application
const app = express();
const PORT = process.env.PORT;

// Enable Cross-Origin Resource Sharing (CORS) for the Express app
app.use(cors());

// Set up the secret key for JWT and parse JSON requests
const secretKey = process.env.SECRET_KEY;
app.use(express.json());

// Set up MongoDB connection details
const uri = process.env.MONGODB_URI;
const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });
let db;

// Function to connect to the MongoDB database
async function connectToDatabase() {
  await client.connect();
  console.log('Connected to MongoDB');
  db = client.db('auth_demo');
}

// Connect to the MongoDB database
connectToDatabase();

// Middleware to authenticate users using JWT
const authenticateUser = async (req, res, next) => {
  // Extract JWT token from the Authorization header
  const token = req.header('Authorization');
  if (!token) return res.status(401).json({ message: 'Unauthorized' });
  try {
    // Verify the JWT token and retrieve user information from the database
    const decoded = jwt.verify(token, secretKey);
    const user = await db.collection('users').findOne({ _id: decoded.id });
    if (!user) {
      return res.status(401).json({ message: 'Invalid token' });
    }
    // Attach user information to the request object for further use
    req.user = user;
    next();
  } catch (error) {
    // Handle invalid tokens
    res.status(401).json({ message: 'Invalid token' });
  }
};

// Endpoint for user registration (signup)
app.post('/signup', async (req, res) => {
  // Extract user information from the request body
  const { email, password, first_name, last_name } = req.body;

  // Check if the user already exists in the database
  const existingUser = await db.collection('users').findOne({ email });
  if (existingUser) {
    return res.status(400).sendStatus(400);
  }

  // Create a new user object
  const newUser = {
    email,
    password,
    first_name,
    last_name,
  };

  // Insert the new user into the database
  const result = await db.collection('users').insertOne(newUser);

  // Create a JWT token for the new user with a 1-hour expiration
  const token = jwt.sign({ id: result.insertedId, email: newUser.email }, secretKey, { expiresIn: '1h' });

  // Respond with the token and user information
  res.json({ token, user: newUser });
});

// Endpoint for user login
app.post('/login', async (req, res) => {
  // Extract login credentials from the request body
  const { email, password } = req.body;

  // Find the user in the database based on email and password
  const user = await db.collection('users').findOne({ email, password });
  if (!user) {
    return res.status(401).sendStatus(401);
  }

  // Create a JWT token for the authenticated user with a 1-second expiration (for testing purposes)
  const token = jwt.sign({ id: user._id, email: user.email }, secretKey, { expiresIn: 1 });

  // Respond with the token and user information
  res.json({ token, user });
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
