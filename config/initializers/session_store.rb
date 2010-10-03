# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_fb_assignments_session',
  :secret      => '8f219dd31d5a25527ec65796d5e9f13d7713367dedf0482f01790893207ed1817993d96e73d986de15a0623e037c42de63cc8d14fab543184c4bed2a9d29f91f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
