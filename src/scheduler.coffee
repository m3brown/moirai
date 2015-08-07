clusters = require('./api/clusters')
couch_utils = require('pantheon-helpers/lib/couch_utils')
conf = require('./config')

utils = {}

utils.shutdownOldInstances = () ->
  client = couch_utils.nano_user(conf.COUCHDB.SYSTEM_USER)
  instancesToShutdown = clusters.getInstancesToShutdown(client)
  clusters.stopInstances(instancesToShutdown)

utils.shutdownTimer = () ->
  # Shut down old instances
  # wait until 3AM, then run every 24 hours

  firstRun = new Date()
  firstRun.setDate(firstRun.getDate() + 1)
  firstRun.setHours(3,0,0,0)

  DAY_IN_MILLIS=24*60*60*1000
  setTimeout(firstRun - new Date())
      .setInterval(shutdownOldInstances, DAY_IN_MILLIS)

module.exports = utils
