_ = require('underscore')
conf = require('./config')
ec2Client = require('./ec2Client')
couch_utils = require('./couch_utils')
ec2KeyManagement = require('./ec2KeyManagement')
Promise = require('pantheon-helpers/lib/promise')

handlers = {
  cluster:

    # Create a new cluster
    'c+': (event, doc) ->
      instance_promises = {}
      _.each(event.record.instances, (event_instance) ->
        instance = _.findWhere(doc.instances, {id: event_instance.id})
        if instance and
            (not instance.state or instance.state.indexOf('terminate') < 0) and
            not instance.aws_id?
          event_instance.ClientToken = instance.id
          instance_promises[event_instance.id] = ec2Client.createInstance(event_instance)
      )

      # if for some reason all the instances were already created, mark the job as complete
      if _.isEmpty(instance_promises)
        return Promise.resolve()

      Promise.hashResolveAll(instance_promises).then((results) ->
        failed = false
        _.each(results, (result, instance_id) ->
          instance = _.findWhere(doc.instances, {id: instance_id})
          if result.state == 'resolved'
            instance.aws_id = result.value.InstanceId
            instance.ip = result.value.PrivateIpAddress
            delete instance.error
          else
            instance.state = 'create_failed'
            instance.error = result.error
            failed = true
        )
        if failed
          return Promise.reject({error: results, data: {instances: doc.instances}, path: []})
        else
          return Promise.resolve({data: {instances: doc.instances}, path: []})
      )
      
    # Terminate a cluster
    'c-': (event, doc) ->
      # if for some reason all the instances were already destroyed, mark the job as complete
      if _.isEmpty(doc.instances)
        return Promise.resolve()

      instance_promises = {}
      _.each(doc.instances, (instance) ->
        if instance.aws_id != undefined
          instance_promises[instance.id] = ec2Client.destroyInstance(instance.aws_id)
        else
          # potential case where the worker hasn't created the instance yet
          instance_promises[instance.id] = Promise.resolve()
      )

      Promise.hashResolveAll(instance_promises).then((results) ->
        failed = false
        _.each(results, (result, instance_id) ->
          instance = _.findWhere(doc.instances, {id: instance_id})
          # don't remove the instance if aws_id doesn't exist yet
          if not instance.aws_id?
            null # do nothing
          else if result.state == 'resolved'
            doc.instances.splice(doc.instances.indexOf(instance), 1)
          else
            instance.error = result.error
            instance.state = 'terminate_failed'
            failed = true
        )
        if failed
          return Promise.reject({error: results, data: {instances: doc.instances}, path: []})
        else
          return Promise.resolve({data: {instances: doc.instances}, path: []})
      )
      
    # set cluster keys
    'k': (event, doc) ->
      promiseList = _.each(doc.instances, (instance) ->
        # If the create instance worker hasn't resolved yet, the aws_id
        # and ip may not exist yet
        if instance.aws_id?
          return ec2KeyManagement.setSSHKeys(instance, doc.keys)
        else
          Promise.setTimeout(60*1000).then(() ->
            couch_utils.nano_system_user.use('moirai').get(doc._id, 'promise')
          ).then((doc) ->
            if not instance.aws_id?
              return Promise.reject('Instance has no aws_id defined')
            ec2KeyManagement.setSSHKeys(instance, doc.keys)
          )
      )
      Promise.all(promiseList).then(() ->
        return Promise.resolve()
      )

}

module.exports = handlers
