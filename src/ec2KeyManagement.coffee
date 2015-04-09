Promise = require('pantheon-helpers/lib/promise')
conf = require('./config')
ssh = require('promised-ssh')
fs = require('fs')

keys = {}

isPubKeyValid = (pubkey) ->
  return pubkey.match(/^ssh-rsa AAAA[0-9A-Za-z+/]+[=]{0,3} [0-9A-Za-z.-]+(@[0-9A-Za-z.-]+)?$/)

getAddCommand = (pubkey) ->
  return 'grepl "'+pubkey+'" .ssh/authorized_keys || echo "'+pubkey+'" >> .ssh/authorized_keys'

getRemoveCommand = (pubkey) ->
  # ssh key may contain forward slashes, so use | for sed search/replace
  return 'sed -i "\\|' + pubkey + '|d" .ssh/authorized_keys'


sshConnect = (host) ->
  keyfile = conf.AWS.PRIVATE_KEY_FILE or (process.env.HOME+'/.ssh/id_rsa')
  ssh.connect({
    host: host
    username: conf.AWS.SSH_USER or 'ec2-user'
    privateKey: fs.readFileSync(keyfile)
  })

keys.addSSHKeys = (host, pubkeys) ->
  for pubkey in pubkeys
    console.log("GOT KEY " + pubkey)
    if not isPubKeyValid(pubkey)
      return Promise.reject('Invalid public key ' + pubkey)
      console.log("REJECTED " + pubkey)
  console.log("Attempting to log into " + host)

  sshConnect(host).then((connection) ->
    pubkeyCmds = pubkeys.map(getAddCommand)
    console.log("adding keys " + pubkeyCmds)
    connection.exec(pubkeyCmds)
  ).catch((err) ->
    # promised-ssh uses bluebird promise
    # convert back to pantheon-helpers promised
    console.log("Failure!! ")
    console.log(err)
    Promise.reject(err)
  )

keys.removeSSHKeys = (host, pubkeys) ->
  for pubkey in pubkeys
    if not isPubKeyValid(pubkey)
      return Promise.reject('Invalid public key ' + pubkey)

  sshConnect(host).then((connection) ->
    pubkeyCmds = pubkeys.map(getRemoveCommand)
    connection.exec(pubkeyCmds)
#  ).catch((err) ->
#    # promised-ssh uses bluebird promise
#    # convert back to pantheon-helpers promise
#    Promise.reject(err)
  )



module.exports = keys
