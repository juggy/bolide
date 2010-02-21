# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_bolide_session',
  :secret      => '79b7c6fa179d98ea8a8d9edf020a5207b7aea3456a398680c26394466aee6981f5f8cc9dceea0577cb0e934609641b78c68b8226053837257f97ebac3eda50c6'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
