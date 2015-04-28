_ = require('underscore')
config_secret = require('./config_secret')

config = 
  COUCHDB:
    HOST: 'localhost'
    PORT: 5984
    HTTPS: false
    SYSTEM_USER: 'admin'
  APP:
    PORT: 5001
  PRIVATE_KEY_FILE: process.env.HOME + '/.ssh/moirai-dev'
  AUTHORIZED_KEY_DEFAULTS: []
  SSH_USER: 'ec2-user'

_.extend(config, config_secret)

module.exports = config
