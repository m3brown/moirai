_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
ec2Client = require('../ec2Client')
couch_utils = require('../couch_utils')
uuid = require('node-uuid')

doAction = require('pantheon-helpers/lib/doAction')

CLUSTER_MISSING_NAME_ERROR = "Cluster name not provided"

clusters = {}

clusters.getCluster = (db_client, cluster_id, callback) ->
  db_client.use('moirai').get(cluster_id, callback)

clusters.handleGetCluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.getCluster(req.couch, cluster_id).pipe(resp)

clusters.getClusters = (db_client, callback) ->
  params = {include_docs: true}
  db_client.use('moirai').viewWithList('moirai', 'active_clusters', 'get_docs', params, callback)

clusters.handleGetClusters = (req, resp) ->
  clusters.getClusters(req.couch).pipe(resp)

clusters.createCluster = (db_client, record) ->
  if not record.name?
    return Promise.reject(CLUSTER_MISSING_NAME_ERROR)

  record.instances.forEach((instance) -> instance.id = uuid.v4())
  return doAction(db_client.use('moirai'), 'moirai', null, {a: 'c+', record: record}, 'promise')

clusters.handleCreateCluster = (req, resp) ->
  cluster_opts = req.body or {}
  db = req.couch.use('moirai')
  clusters.createCluster(req.couch, cluster_opts).then((clusterData) ->
    return resp.status(201).send(JSON.stringify(clusterData))
  ).catch((err) ->
    if err == CLUSTER_MISSING_NAME_ERROR
      return resp.status(400).send(JSON.stringify({error: 'Bad Request', msg: err}))
    else
      return resp.status(500).send(JSON.stringify({error: 'Internal Error', msg: String(err)}))
  )


clusters.destroyCluster = (db, cluster_id, callback) ->
  return doAction(db, 'moirai', cluster_id, {a: 'c-'}, callback)

clusters.handleDestroyCluster = (req, resp) ->
  cluster_id = "cluster_" + req.params.cluster_id
  db = req.couch.use('moirai')
  clusters.destroyCluster(db, cluster_id).pipe(resp)

clusters.handleAddInstance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handleUpdateCluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.setKeys = (db_client, cluster_id, keys, callback) ->
  db = db_client.use('moirai')
  return doAction(db, 'moirai', cluster_id, {a: 'k', keys: keys}, callback)

clusters.handleSetKeys = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  keys = req.body or []
  clusters.setKeys(req.couch, cluster_id, keys).pipe(resp)

clusters.startCluster = (db_client, cluster_id, callback) ->
  clusters.getCluster(db_client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.startInstances(awsIds)
  )

clusters.handleStartCluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.startCluster(req.couch, cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.stopCluster = (db_client, cluster_id, callback) ->
  clusters.getCluster(db_client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.stopInstances(awsIds)
  )

clusters.handleStopCluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.stopCluster(req.couch, cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

module.exports = clusters
