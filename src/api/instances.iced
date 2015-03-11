_ = require('underscore')
conf = require('../config')
clusters = require('./clusters')

instances = {}

instances.create_instance = (client, opts, callback) ->
  instance_opts = {
    size: 't2.micro',
    tags: {},
  }
  user_instance_opts = _.pick(opts, 'name', 'size', 'user_data')
  _.extend(instance_opts, user_instance_opts)
  user_tags = opts.tags or {}
  required_tags = {}
  _.extend(instance_opts.tags, user_tags, required_tags)

  cluster_opts = _.pick(opts, 'name', 'halt_ttl', 'destroy_ttl')
  # TODO: create instance in db; worker watched db and creates instance  
  clusters.create_cluster()

instances.handle_create_instance = (req, resp) ->
  all_opts = req.body
  await instances.create_instance(req.couch, all_opts, defer(err, cluster_doc))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.status(201).send(JSON.stringify(cluster_doc))

instances.handle_get_instances = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

instances.handle_update_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

instances.handle_destroy_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

module.exports = instances
