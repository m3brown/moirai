_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
ec2Client = require('../ec2Client')
couch_utils = require('../couch_utils')
uuid = require('node-uuid')

doAction = require('pantheon-helpers/lib/doAction')

CLUSTER_MISSING_NAME_ERROR = "Cluster name not provided"

clusters = {}

clusters.getCluster = (client, cluster_id, callback) ->
  cluster_id = 'cluster_' + cluster_id
  client.use('moirai').get(cluster_id, callback)

clusters.handleGetCluster = (req, resp) ->
  clusters.getCluster(req.couch, req.params.cluster_id).pipe(resp)

clusters.getClusters = (client, callback) ->
  params = {include_docs: true}
  client.use('moirai').viewWithList('moirai', 'active_clusters', 'get_docs', params, callback)

clusters.handleGetClusters = (req, resp) ->
  clusters.getClusters(req.couch).pipe(resp)

clusters.createCluster = (client, record) ->
  if not record.name?
    return Promise.reject(CLUSTER_MISSING_NAME_ERROR)

  record.instances.forEach((instance) -> instance.id = uuid.v4())
  return doAction(client.use('moirai'), 'moirai', null, {a: 'c+', record: record}, 'promise')

clusters.handleCreateCluster = (req, resp) ->
  cluster_opts = req.body or {}
  clusters.createCluster(req.couch, cluster_opts).then((clusterData) ->
    return resp.status(201).send(JSON.stringify(clusterData))
  ).catch((err) ->
    if err == CLUSTER_MISSING_NAME_ERROR
      return resp.status(400).send(JSON.stringify({error: 'Bad Request', msg: err}))
    else
      return resp.status(500).send(JSON.stringify({error: 'Internal Error', msg: String(err)}))
  )


clusters.destroyCluster = (client, cluster_id, callback) ->
  cluster_id = "cluster_" + cluster_id
  return doAction(client.use('moirai'), 'moirai', cluster_id, {a: 'c-'}, callback)

clusters.handleDestroyCluster = (req, resp) ->
  clusters.destroyCluster(req.couch, req.params.cluster_id).pipe(resp)

clusters.handleAddInstance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handleUpdateCluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.setKeys = (client, cluster_id, keys, callback) ->
  cluster_id = 'cluster_' + cluster_id
  return doAction(client.use('moirai'), 'moirai', cluster_id, {a: 'k', keys: keys}, callback)

clusters.handleSetKeys = (req, resp) ->
  keys = req.body or []
  clusters.setKeys(req.couch, req.params.cluster_id, keys).pipe(resp)

clusters.startCluster = (client, cluster_id, callback) ->
  clusters.getCluster(client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.startInstances(awsIds)
  )

clusters.handleStartCluster = (req, resp) ->
  clusters.startCluster(req.couch, req.params.cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.stopCluster = (client, cluster_id, callback) ->
  clusters.getCluster(client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.stopInstances(awsIds)
  )

clusters.handleStopCluster = (req, resp) ->
  clusters.stopCluster(req.couch, req.params.cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

module.exports = clusters
