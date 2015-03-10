instances = require('./instances')
_ = require('underscore')
couch_utils = require('../couch_utils')

clusters = {}

clusters.get_cluster = (client, cluster_id, callback) ->
  return client.get(cluster_id, callback)

clusters.handle_get_cluster = (req, resp) ->
  cluster_id = req.params.cluster_id
  client = req.couch
  return clusters.get_cluster(client, cluster_id).pipe(resp)

clusters.create_cluster = (client, opts, callback) ->
  # TODO validate opts

  # submit request to AWS
  created_instances = []
  err = []
  console.log(opts.instances)
  await
    for instance,i in opts.instances
      instances.create_instance(client, instance, defer(err[i], created_instances[i]))

  # After successfully creating in AWS, insert record DB
  cluster = {
    # TODO add more opts
    instances: created_instances
  }

  #client.db.destroy('moirai')
  #console.log("destroyed moirai")
  moirai_db = client.use('moirai')
  await couch_utils.ensure_db(moirai_db, 'insert', cluster, defer(err, couch_resp))
#  moirai_db.insert(cluster).on('response', (couch_resp) ->
#    #if couch_resp.statusCode < 400
#    #  moirai_db.get(team_id).pipe(resp)
#    #else
  console.log(couch_resp)
#  )

#  #await client.insert(cluster, defer(err, resp))
  # TODO if there's an error, do we delete the machine or reattempt DB insert?
  if err then return callback(err)
  out = _.extend(cluster, {_id: couch_resp.id, _rev: couch_resp.rev})
  return callback(null, out)

clusters.handle_create_cluster = (req, resp) ->
  cluster_opts = req.body or {}
  await clusters.create_cluster(req.couch, cluster_opts, defer(err, cluster_doc))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.status(201).send(JSON.stringify(cluster_doc))

clusters.handle_get_clusters = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_get_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_update_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_destroy_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_add_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

module.exports = clusters
