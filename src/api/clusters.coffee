_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
ec2Client = require('../ec2Client')
couch_utils = require('../couch_utils')
uuid = require('node-uuid')

doAction = require('pantheon-helpers/lib/doAction')

clusters = {}

clusters.get_cluster = (db_client, cluster_id, callback) ->
  db_client.use('moirai').get(cluster_id, callback)

clusters.handle_get_cluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.get_cluster(req.couch, cluster_id).pipe(resp)

clusters.get_clusters = (db_client, callback) ->
  params = {include_docs: true}
  db_client.use('moirai').viewWithList('moirai', 'active_clusters', 'get_docs', params, callback)

clusters.handle_get_clusters = (req, resp) ->
  clusters.get_clusters(req.couch).pipe(resp)

clusters.create_cluster = (db, record, callback) ->
  record.instances.forEach((instance) -> instance.id = uuid.v4())
  record.name = "a_cluster"
  return doAction(db, 'moirai', null, {a: 'c+', record: record}, callback)

clusters.handle_create_cluster = (req, resp) ->
  cluster_opts = req.body or {}
  db = req.couch.use('moirai')
  clusters.create_cluster(db, cluster_opts).pipe(resp)


clusters.destroy_cluster = (db, cluster_id, callback) ->
  return doAction(db, 'moirai', cluster_id, {a: 'c-'}, callback)

clusters.handle_destroy_cluster = (req, resp) ->
  cluster_id = "cluster_" + req.params.cluster_id
  db = req.couch.use('moirai')
  clusters.destroy_cluster(db, cluster_id).pipe(resp)

clusters.handle_add_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_update_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.set_keys = (db_client, cluster_id, keys, callback) ->
  db = db_client.use('moirai')
  return doAction(db, 'moirai', cluster_id, {a: 'k', keys: keys}, callback)

clusters.handle_set_keys = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  keys = req.body or []
  clusters.set_keys(req.couch, cluster_id, keys).pipe(resp)

clusters.start_cluster = (db_client, cluster_id, callback) ->
  clusters.get_cluster(db_client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.startInstances(awsIds)
  )

clusters.handle_start_cluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.start_cluster(req.couch, cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.stop_cluster = (db_client, cluster_id, callback) ->
  clusters.get_cluster(db_client, cluster_id, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.stopInstances(awsIds)
  )

clusters.handle_stop_cluster = (req, resp) ->
  cluster_id = 'cluster_' + req.params.cluster_id
  clusters.stop_cluster(req.couch, cluster_id).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

module.exports = clusters
