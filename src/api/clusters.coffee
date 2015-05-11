_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
ec2Client = require('../ec2Client')
couch_utils = require('../couch_utils')
uuid = require('node-uuid')

doAction = require('pantheon-helpers/lib/doAction')

CLUSTER_MISSING_NAME_ERROR = "Cluster name not provided"

clusters = {}

formatClusterId = (clusterId) ->
  if clusterId.indexOf('cluster_') == 0
    return clusterId
  else
    return 'cluster_' + clusterId

clusters.getCluster = (client, clusterId, callback) ->
  client.use('moirai').get(formatClusterId(clusterId), callback)

clusters.handleGetCluster = (req, resp) ->
  clusters.getCluster(req.couch, req.params.clusterId).pipe(resp)

clusters.getClusters = (client, opts) ->
  # This only returns a promise
  params = {include_docs: true}
  opts ?= {}
  if opts.clusterIds
    params.keys = opts.clusterIds.map(formatClusterId)
  client.use('moirai').viewWithList('moirai', 'active_clusters', 'get_docs_without_audit', params, 'promise').then((clusters) ->
    if _.isEmpty(clusters)
      return Promise.resolve([])
    awsIds = _.chain(clusters)
              .pluck('instances')
              .flatten(true)
              .pluck('aws_id')
              .compact()
              .value()
    ec2Client.getInstances(awsIds).then((ec2Instances) ->
      ec2InstanceLookup = {}
      _.each(ec2Instances, (ec2Instance) ->
        instanceTags = {}
        _.each(ec2Instance.Tags, (tag) ->
          instanceTags[tag.Key] = tag.Value
        )
        ec2InstanceLookup[ec2Instance.InstanceId] = {
          instanceType: ec2Instance.InstanceType
          ip: ec2Instance.PrivateIpAddress
          state: ec2Instance.State.Name
          tags: instanceTags
        }
      )
      clusters.forEach((cluster) ->
        cluster.instances.forEach((instance) ->
          if instance.aws_id
            _.extend(instance, ec2InstanceLookup[instance.aws_id] or {state: 'instance does not exist'})
        )
      )
      Promise.resolve(clusters)
    )
  )

clusters.handleGetClusters = (req, resp) ->
  clusterOpts = req.query or {}
  if _.isString(clusterOpts.clusterIds)
    clusterOpts.clusterIds = clusterOpts.clusterIds.split(',')
  clusters.getClusters(req.couch, clusterOpts).then((clusters) ->
    return resp.send(JSON.stringify(clusters))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.createCluster = (client, record) ->
  if not record.name?
    return Promise.reject(CLUSTER_MISSING_NAME_ERROR)

  record.instances.forEach((instance) -> instance.id = uuid.v4())
  return doAction(client.use('moirai'), 'moirai', null, {a: 'c+', record: record}, 'promise')

clusters.handleCreateCluster = (req, resp) ->
  clusterOpts = req.body or {}
  clusters.createCluster(req.couch, clusterOpts).then((clusterData) ->
    return resp.status(201).send(JSON.stringify(clusterData))
  ).catch((err) ->
    if err == CLUSTER_MISSING_NAME_ERROR
      return resp.status(400).send(JSON.stringify({error: 'Bad Request', msg: err}))
    else
      return resp.status(500).send(JSON.stringify({error: 'Internal Error', msg: String(err)}))
  )


clusters.destroyCluster = (client, clusterId, callback) ->
  return doAction(client.use('moirai'), 'moirai', formatClusterId(clusterId), {a: 'c-'}, callback)

clusters.handleDestroyCluster = (req, resp) ->
  clusters.destroyCluster(req.couch, req.params.clusterId).pipe(resp)

clusters.handleAddInstance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.handleUpdateCluster = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

clusters.setKeys = (client, clusterId, keys, callback) ->
  return doAction(client.use('moirai'), 'moirai', formatClusterId(clusterId), {a: 'k', keys: keys}, callback)

clusters.handleSetKeys = (req, resp) ->
  keys = req.body or []
  clusters.setKeys(req.couch, req.params.clusterId, keys).pipe(resp)

clusters.startCluster = (client, clusterId, callback) ->
  clusters.getCluster(client, clusterId, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.startInstances(awsIds)
  )

clusters.handleStartCluster = (req, resp) ->
  clusters.startCluster(req.couch, req.params.clusterId).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

clusters.stopCluster = (client, clusterId, callback) ->
  clusters.getCluster(client, clusterId, 'promise').then((cluster) ->
    awsIds = _.pluck(cluster.instances, 'aws_id')
    ec2Client.stopInstances(awsIds)
  )

clusters.handleStopCluster = (req, resp) ->
  clusters.stopCluster(req.couch, req.params.clusterId).then((aws_resp) ->
    return resp.status(201).send(JSON.stringify(aws_resp))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

module.exports = clusters
