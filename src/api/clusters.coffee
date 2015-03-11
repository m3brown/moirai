_ = require('underscore')
Promise = require('promise')
instances = require('./instances')
couch_utils = require('../couch_utils')

clusters = {}

clusters.get_cluster = (client, cluster_id, callback) ->
  return client.get(cluster_id, callback)

clusters.handle_get_cluster = (req, resp) ->
  cluster_id = req.params.cluster_id
  client = req.couch
  return clusters.get_cluster(client, cluster_id).pipe(resp)

clusters.create_cluster = (client, opts) ->
  # TODO validate opts

  console.log(opts.instances)

  Promise.all(
    # submit request(s) to AWS
    opts.instances.map(instances.create_instance)
  ).then((created_instances) ->
    # After successfully creating in AWS, insert record DB
    cluster = {
      # TODO add more opts
      instances: created_instances
    }

    #client.db.destroy('moirai')
    #console.log("destroyed moirai")
    moirai_db = client.use('moirai')
    ensure_db = Promise.denodeify(couch_utils.ensure_db)
    ensure_db(moirai_db, 'insert', cluster).then((couch_resp) ->
      Promise.resolve(_.extend(cluster, {_id: couch_resp.id, _rev: couch_resp.rev}))
    ).catch((err) ->
      # TODO if there's an error, do we delete the machine or reattempt DB insert?
      Promise.reject(new Error(err))
    )
  ).catch(() ->
    # TODO recovery on failure 
    Promise.reject(new Error('Failed to create at least one instance'))
  )


clusters.handle_create_cluster = (req, resp) ->
  cluster_opts = req.body or {}
  create_cluster = Promise.denodeify(clusters.create_cluster)
  create_cluster(req.couch, cluster_opts).then((cluster_doc) ->
    return resp.status(201).send(JSON.stringify(cluster_doc))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: err}))
  )

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
