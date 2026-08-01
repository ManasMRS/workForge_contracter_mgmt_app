const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const User = require('./models/User.js');

passport.use(new LocalStrategy(
    { usernameField: 'email' }, // change to 'phone' if you log in with phone instead
    async (email, password, done) => {
        try {
            const user = await User.findOne({ email });
            if (!user) {
                return done(null, false, { message: 'Incorrect email' });
            }

            const isMatch = await user.comparePassword(password);
            if (!isMatch) {
                return done(null, false, { message: 'Incorrect password' });
            }

            return done(null, user);
        } catch (err) {
            return done(err);
        }
    }
));

module.exports = passport;