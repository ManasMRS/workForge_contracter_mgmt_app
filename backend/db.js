const mongoose = require('mongoose');
require('dotenv').config(); // Load environment variables from .env file

//Define the Mongoose connection url
//const mongoURL = process.env.MONGODB_URL_LOCAL; //replace 'mydatabase' with your database name
const mongoURL = process.env.MONGODB_URL; // Use the DB_URL from environment variables

//set up mongoDB connection
mongoose.connect(mongoURL)


//Get the default connection
//Mongoose maintains a default connection object representing the MongoDB connection. 
const db = mongoose.connection;

//Default event listener for database connection
db.on('connected', () =>{
console.log('Connected to MongoDB server');
});

db.on('error', (err) =>{
console.log('Error in MongoDB connection: ' + err);
});

db.on('disconnected', () =>{
console.log('Disconnected MongoDB ');
});

//Export the connection object to use it in other files
module.exports = db;