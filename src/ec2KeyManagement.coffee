Promise = require('pantheon-helpers/lib/promise')
conf = require('./config')
ec2Client = require('./ec2Client')
child_process = require('child_process')

keys = {}

PRIVATE_KEY = conf.AWS.PRIVATE_KEY_FILE or (process.env.HOME+'/.ssh/id_rsa')
USERNAME = conf.AWS.SSH_USER or 'ec2-user'
DEFAULT_KEYS = conf.AWS.AUTHORIZED_KEY_DEFAULTS or []

keys.exec = Promise.denodeify(child_process.exec)

getSSHCommand = (host, pubkeys) ->
  remoteCommand = getRemoteCommand(pubkeys)
  cmd = 'ssh -o StrictHostKeyChecking=no -i '+PRIVATE_KEY+' '+USERNAME+'@'+host+' '+remoteCommand

getRemoteCommand = (pubkeys) ->
  allKeys = DEFAULT_KEYS.concat(pubkeys)
  return '"echo -e \''+allKeys.join('\\n')+'\' > .ssh/authorized_keys"'

keys.setSSHKeys = (instance, pubkeys) ->
  ec2Client.getSingleInstance(instance.aws_id).then((data) ->
    initialState = data.State.Name
    attempts = 0

    makeAttempt = () ->
      sshCommand = getSSHCommand(instance.ip, pubkeys)
      return keys.exec(sshCommand).catch((err) ->
        if attempts++ < 4
          return Promise.setTimeout(60*1000).then(makeAttempt)
        else
          return Promise.reject(err)
      )

    if initialState in ['running', 'pending']
      return makeAttempt()
    else
      return ec2Client.startInstances([instance.aws_id])
          .then(makeAttempt)
          .then(() ->
            ec2Client.stopInstances([instance.aws_id])
          )
  )

module.exports = keys
