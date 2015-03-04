_ = require('underscore')
aws = require('aws-sdk')
conf = require('../config')
clusters = require('./clusters')

utils = {}
# Get only the fields we want from an instance object
utils.prepare_instance = (instance) ->
  fields = [
    'InstanceId',
    'InstanceType',
    'PrivateIpAddress',
    'Tags',
  ]
  return _.pick(instance, fields...)

# Trim and regroup all instances in a response
# Instances from aws-sdk are bundled inside of a list
# of reservation objects
utils.prepare_instances = (resp_object) ->
  instances = []
  for reservation in resp_object.Reservations
    for instance in reservation.Instances
      instances.push utils.prepare_instance(instance)
  return instances

instances = {}
ec2 = new aws.EC2({
  apiVersion: conf.AWS.APIVERSION,
  accessKeyId: conf.AWS.ACCESS_KEY,
  secretAccessKey: conf.AWS.SECRET_KEY,
  region: conf.AWS.REGION
})

instances.create_instance = (client, opts, callback) ->
  instance_params = {
    InstanceType: conf.AWS.INSTANCETYPE,
    UserData: ''
  }
  required_params = {
    ImageId: conf.AWS.IMAGEID,
    MaxCount: 1,
    MinCount: 1,
    KeyName: conf.AWS.KEYNAME,
    SubnetId: conf.AWS.SUBNETID,
    SecurityGroupIds: conf.AWS.SECURITYGROUPIDS
  }
  user_params = _.pick(opts, 'InstanceType', 'UserData')
  _.extend(instance_params, user_params, required_params)

  # TODO should there be config defaults? none of these
  # should be hardcoded
  tags = {
    Name: "AWSDEVMOIRAI", # TODO generate this
    Application: '',
    Creator: 'default.user@example.com', # TODO figure this out
    Software: '',
    BusinessOwner: '',
    Description: '',
  }

  # TODO should we blindly accept tags? Only tags we plan on
  # Using? what if there are more than 10?
  user_tags = _.pick(opts.tags, 'Application', 'Name')

  # TODO should there be config defaults? none of these
  # should be hardcoded
  required_tags = {
    Domain: 'dev',
    PuppetRole: '',
    SysAdmin: 'SE',
    CreateDate: new Date().toISOString().split('T')[0]
  }
  _.extend(tags, user_tags, required_tags)

  # create instance via AWS API
  await ec2.runInstances(instance_params, defer(err, data))
  if err
    return callback(err)

  tag_params = 
    Resources: [data.Instances[0].InstanceId],
    Tags: ({'Key': key, 'Value': value} for key,value of tags)

  await ec2.createTags(tag_params, defer(err, tag_data))
  if err
    # What do we do here? delete the instance?
    return callback(err)
  return callback(null, data)

  # TODO: 2 create instance in db if 1 successful
  # TODO: 3 worker watched db?

instances.handle_create_instance = (req, resp) ->
  all_opts = req.body
  await instances.create_instance(req.couch, all_opts, defer(err, cluster_doc))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: err}))
  return resp.status(201).send(JSON.stringify(cluster_doc))

instances.get_instances = (client, callback) ->
  params = {
    Filters: [
      {
          Name: 'key-name',
          Values: [
            # TODO consider a better way of pulling moirai machines.
            # With this solution, changing the config key will "lose"
            # any existing instances
            conf.AWS.KEYNAME
          ]
      }
    ]
  }
  await ec2.describeInstances(params, defer(err, data))
  if err
    return callback(err)
  return callback(null, utils.prepare_instances(data))

instances.handle_get_instances = (req, resp) ->
  await instances.get_instances(req.couch, defer(err, data))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: err}))
  return resp.status(201).send(JSON.stringify(data))

instances.get_instance = (client, instance_id, callback) ->
  params = {
    InstanceIds: [instance_id]
  }

  await ec2.describeInstances(params, defer(err, data))
  if err
    return callback(err)
  return callback(null, utils.prepare_instances(data))

instances.handle_get_instance = (req, resp) ->
  instance_id = req.params.instance_id
  await instances.get_instance(req.couch, instance_id, defer(err, data))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.status(201).send(JSON.stringify(data))


instances.handle_update_instance = (req, resp) ->
  resp.send('NOT IMPLEMENTED')

instances.destroy_instance = (client, instance_id, callback) ->
  params = {
    InstanceIds: [instance_id]
  }

  await ec2.terminateInstances(params, defer(err, data))
  if err
    return callback(err)
  return callback(null, data)


instances.handle_destroy_instance = (req, resp) ->
  instance_id = req.params.instance_id
  await instances.destroy_instance(req.couch, instance_id, defer(err, data))
  if err
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.status(201).send(JSON.stringify(data))

module.exports = instances
