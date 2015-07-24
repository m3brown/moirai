_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
clusters = require('./api/clusters')
conf = require('./config')

scheduler = {}

scheduler.powerOffOldInstances = () ->

  instancesToPowerOff = clusters.getOldClusters()

  clusters.stopInstances(instanceisToPowerOff).catch((err) ->
  )

module.exports = scheduler
