_ = require('underscore')

clusters = {}

clusters.get_cluster = (client, cluster_id, callback) ->
  return client.get(cluster_id, callback)

clusters.handle_get_cluster = (req, resp) ->
  cluster_id = req.params.cluster_id
  client = req.couch
  return clusters.get_cluster(client, cluster_id).pipe(resp)

clusters.create_cluster = (client, opts, callback) ->
  await client.insert(opts, defer(err, resp))
  if err then return callback(err)
  out = _.extend({}, opts, {_id: resp.id, _rev: resp.rev})
  return callback(null, out)

clusters.handle_create_cluster = (req, resp) ->
  cluster_opts = req.body or {}
  await clusters.create_cluster(req.couch, cluster_opts, defer(err, cluster_doc))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.status(201).send(JSON.stringify(cluster_doc))

clusters.handle_get_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_update_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_destroy_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handle_add_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')