_ = require('underscore')
Promise = require('pantheon-helpers/lib/promise')
aws = require('aws-sdk')
conf = require('./config')

instances = {}

# Get only the fields we want from an instance object
# Instances from aws-sdk are bundled inside of a list
# of reservation objects
instances.prepareInstances = (resp_object) ->
  if resp_object.Reservations?
    for reservation in resp_object.Reservations
      return reservation.Instances
  else
      return resp_object.Instances


ec2PromiseClient = (ec2_opts) ->
  ec2 = new aws.EC2(ec2_opts)
  client = {}
  ['createTags', 'describeInstances', 'runInstances', 'terminateInstances'].forEach((method) ->
    client[method] = Promise.denodeify(ec2[method]).bind(ec2)
  )
  return client

instances.ec2 = ec2PromiseClient({
  apiVersion: conf.AWS.APIVERSION,
  accessKeyId: conf.AWS.ACCESS_KEY,
  secretAccessKey: conf.AWS.SECRET_KEY,
  region: conf.AWS.REGION
})

instances.generateParams = (opts) ->
  params = {}

  requiredParams =
    MaxCount: 1
    MinCount: 1
  userParams = _.pick(opts, conf.AWS.USER_PARAMS...)
  _.extend(params,
           conf.AWS.DEFAULT_PARAMS,
           userParams,
           conf.AWS.REQUIRED_PARAMS,
           requiredParams
          )
  return params


instances.generateTags = (userTags) ->
  # TODO should there be config defaults? none of these
  # should be hardcoded
  tags =
    Name: "AWSDEVMOIRAI", # TODO generate this
    Application: '',
    Creator: 'default.user@example.com', # TODO figure this out
    Software: '',
    BusinessOwner: '',
    Description: '',

  # what if there are more than 10?
  userTags = _.pick(userTags, conf.AWS.TAG_PARAMS...)

  # TODO should there be config defaults? none of these
  # should be hardcoded
  requiredTags =
    Domain: 'dev',
    PuppetRole: '',
    SysAdmin: 'SE',
    # TODO Timezone?
    CreateDate: new Date().toISOString()

  _.extend(tags, userTags, requiredTags)
  return tags


instances.generateUserData = (opts, params, tags) ->
  # TODO find a better way to insert values to user data
  userData = conf.AWS.USERDATA
  userData = userData.replace('<HOSTNAME>', tags.Name)
  return userData


instances.createInstance = (opts) ->

  params = instances.generateParams(opts)
  tagsHash = instances.generateTags(opts.tags)
  tags = ({'Key': key, 'Value': value} for key,value of tagsHash)
  userDataText = instances.generateUserData(opts, params, tags)
  userData = new Buffer(userDataText).toString('base64')


  # create instance via AWS API
  instances.ec2.runInstances(params).then((data) ->
    preparedInstance = instances.prepareInstances(data)[0]
    tag_params = 
      Resources: [preparedInstance.InstanceId],
      Tags: tags

    instances.ec2.createTags(tag_params).catch((err) ->
      # What do we do here? delete the instance?
      Promise.reject(err)
    ).then(() ->
      preparedInstance.Tags = tags
      Promise.resolve(preparedInstance)
    )
  )


instances.get_instances = () ->
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
      },
      {
          Name: 'instance-state-name',
          Values: ['pending', 'running', 'stopping', 'stopped']
      }
    ]
  }
  instances.ec2.describeInstances(params).then((data) ->
    Promise.resolve(instances.prepareInstances(data))
  )

instances.handle_get_instances = (req, resp) ->
  instances.get_instances().then((data) ->
    return resp.status(201).send(JSON.stringify(data))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )

instances.get_instance = (instance_id) ->
  params = {
    InstanceIds: [instance_id]
    Filters: [
      {
          Name: 'key-name',
          Values: [
            # TODO consider a better way of pulling moirai machines.
            # With this solution, changing the config key will "lose"
            # any existing instances
            conf.AWS.KEYNAME
          ]
      },
      {
          Name: 'instance-state-name',
          Values: ['pending', 'running', 'stopping', 'stopped']
      }
    ]
  }

  instances.ec2.describeInstances(params).then((data) ->
    if not data.Reservations.length
      return Promise.reject('Unrecognized instance ID: ' + instance_id)
    Promise.resolve(instances.prepareInstances(data)[0])
  )

instances.handle_get_instance = (req, resp) ->
  instance_id = req.params.instance_id
  instances.get_instance(instance_id).then((data) ->
    return resp.status(201).send(JSON.stringify(data))
  ).catch((err) ->
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: String(err)}))
  )


instances.handle_update_instance = (req, resp) ->
  # TODO determine what updates are available
  # name
  # instance type (requires shutdown)
  resp.send('NOT IMPLEMENTED')

instances.destroyInstance = (aws_id) ->
  params = {
    InstanceIds: [aws_id]
  }

  instances.ec2.terminateInstances(params)


module.exports = instances
