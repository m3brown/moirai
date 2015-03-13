_ = require('underscore')
Promise = require('promise')
instances = require('./instances')
couch_utils = require('../couch_utils')

clusters = {}

clusters.get_cluster = (db_client, cluster_id) ->
  Promise.denodeify(couch_utils.ensure_db)(db_client, 'get', cluster_id)

clusters.handle_get_cluster = (req, resp) ->
  cluster_id = req.params.cluster_id
  client = req.couch.use('moirai')
  clusters.get_cluster(client, cluster_id).then((couch_resp) ->
    return resp.status(201).send(JSON.stringify(couch_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.create_cluster = (db_client, opts) ->
  # TODO validate opts

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
    ensure_db = Promise.denodeify(couch_utils.ensure_db)
    ensure_db(db_client, 'insert', cluster).then((couch_resp) ->
      Promise.resolve(_.extend(cluster, {_id: couch_resp.id, _rev: couch_resp.rev}))
    ).catch((err) ->
      # TODO if there's an error, do we delete the machine or reattempt DB insert?
      Promise.reject(err)
    )
  ).catch((err) ->
    # TODO recovery on failure to create at least one instance
    Promise.reject(err)
  )


clusters.handle_create_cluster = (req, resp) ->
  cluster_opts = req.body or {}
  create_cluster = Promise.denodeify(clusters.create_cluster)
  create_cluster(req.couch.use('moirai'), cluster_opts).then((cluster_doc) ->
    return resp.status(201).send(JSON.stringify(cluster_doc))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.get_clusters = (db_client) ->
  params = {include_docs: true, limit: 10}
  Promise.denodeify(couch_utils.ensure_db)(db_client, 'list', params).then((data) ->
    cluster = data.rows.map((row) ->
      return row.doc
    )
    Promise.resolve(cluster)
  )

clusters.handle_get_clusters = (req, resp) ->
  client = req.couch.use('moirai')
  clusters.get_clusters(client).then((couch_resp) ->
    return resp.status(201).send(JSON.stringify(couch_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.handle_update_cluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.destroy_cluster = (db_client, cluster_id) ->
  clusters.get_cluster(db_client, cluster_id).then((cluster) ->
    Promise.all(
      cluster.instances.map((instance) ->
        instances.destroy_instance(instance.InstanceId)
        instance.State = {
            Code: 48
            Name: "terminated"
        }
        Promise.resolve(instance)
      )
    ).then((updated_instances) ->
      # Update the doc to denote that the cluster is terminated
      cluster.state = 'terminated'
      cluster.instances = updated_instances
      Promise.denodeify(couch_utils.ensure_db)(db_client, 'insert', cluster)
    ).catch((err) ->
      # TODO handle error in one or more destroy requests
      Promise.reject(err)
    )
  ).catch((err) ->
    # TODO handle error when getting cluster info from DB
    Promise.reject(err)
  )

clusters.handle_destroy_cluster = (req, resp) ->
  cluster_id = req.params.cluster_id
  client = req.couch.use('moirai')
  clusters.destroy_cluster(client, cluster_id).then((couch_resp) ->
    return resp.status(201).send(JSON.stringify(couch_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.handle_add_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

module.exports = clusters
