deepExtend = require('pantheon-helpers').utils.deepExtend

try
    config_secret = require('./config_secret')
catch e
    config_secret = {}


config = 
  COUCHDB:
    HOST: 'localhost'
    PORT: 5984
    HTTPS: false
    SYSTEM_USER: 'admin'
  APP:
    PORT: 5001
  PRIVATE_KEY_FILE: __dirname + '/../moirai.key'
  SSH_USER: 'ec2-user'
  COUCH_PWD: '' # couchdb password
  AUTHORIZED_KEY_DEFAULTS: [] # SSH public key text (string)
  AWS:
    # PARAMS are passed to the AWS SDK's runInstances
    # Valid params are listed at the following site:
    # http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/EC2.html#runInstances-property
    DEFAULT_PARAMS:
      InstanceType: 't1.micro'
    ALLOWED_USER_PARAMS: [
      # Overrides DEFAULT_PARAMS
      # all user-specified parameters are filtered against this list
      'InstanceType'
    ]
    REQUIRED_PARAMS:
      # Overrides USER_PARAMS and DEFAULT_PARAMS
      KeyName: 'moirai'

    TAG_PARAMS: [
      # List of acceptable AWS tags (string)
      'Name'
    ] 
    ACCESS_KEY: undefined # AWS Access Key (not necessary if using roles)
    SECRET_KEY: undefined # AWS Secret Key (not necessary if using roles)
    REGION: 'us-east-1'
    APIVERSION: '2014-10-01'
    USERDATA: '' # AWS UserData (string); currently replaces '<HOSTNAME>' with the host name
  LOGGERS:
    WEB:
      streams: [{
        path: '/var/log/moirai/web-error.log',
        level: "error",
      },
      {
        path: '/var/log/moirai/web.log'
        level: "info",
      }]
    WORKER:
      streams: [{
        path: '/var/log/moirai/worker-error.log',
        level: "error",
      },
      {
        path: '/var/log/moirai/worker.log',
        level: "info",
      }]

  DEV: false

deepExtend(config, config_secret)

module.exports = config
