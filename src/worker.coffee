worker = require('pantheon-helpers/lib/worker')
_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
get_doc_type = require('./design_docs/moirai/lib/actions').get_doc_type
ec2Client = require('./ec2Client')
Promise = require('pantheon-helpers/lib/promise')
handlers = require('./workerHandlers')

#handlers = {
#  cluster:
#
#    # Create a new cluster
#    'c+': (event, doc) ->
#      instance_promises = {}
#      _.each(event.record.instances, (event_instance) ->
#        instance = _.findWhere(doc.instances, {id: event_instance.id})
#        if instance?.state and
#            instance.state.indexOf('terminate') < 0 and
#            not instance.aws_id?
#          event_instance.ClientToken = instance.id
#          instance_promises[event_instance.id] = ec2Client.createInstance(event_instance)
#      )
#
#      # if for some reason all the instances were already created, mark the job as complete
#      if _.isEmpty(instance_promises)
#        return Promise.resolve()
#
#      Promise.hashResolveAll(instance_promises).then((results) ->
#        failed = false
#        _.each(results, (result, instance_id) ->
#          instance = _.findWhere(doc.instances, {id: instance_id})
#          if result.state == 'resolved'
#            instance.aws_id = result.value.InstanceId
##            delete instance.error
#          else
#            instance.state = 'create_failed'
#            instance.error = result.error
#            failed = true
#        )
#        if failed
#          return Promise.reject({error: results, data: {instances: doc.instances}, path: []})
#        else
#          return Promise.resolve({data: {instances: doc.instances}, path: []})
#      )
#      
#    # Terminate a cluster
#    'c-': (event, doc) ->
#      instance_promises = {}
#      _.each(event.record.instances, (event_instance) ->
#        instance = _.findWhere(doc.instances, {id: event_instance.id})
#        instance_promises[event_instance.id] = ec2Client.destroyInstance(instance.aws_id, instance.id)
#      )
#
#      # if for some reason all the instances were already destroyed, mark the job as complete
#      if _.isEmpty(instance_promises)
#        return Promise.resolve()
#
#      Promise.hashResolveAll(instance_promises).then((results) ->
#        failed = false
#        _.each(results, (result, instance_id) ->
#          instance = _.findWhere(doc.instances, {id: instance_id})
#          if result.state == 'resolved'
#            doc.instances.pop(instance)
#          else
#            instance.error = result.error
#            failed = true
#        )
#        if failed
#          return Promise.reject({error: results, data: {instances: doc.instances}, path: []})
#        else
#          return Promise.resolve({data: {instances: doc.instances}, path: []})
#      )
#      
#    
#}

#get_handler_data_path = (doc_type, rsrc) ->
#  return ['moirai']

#get_doc_type = (doc) ->
#  throw new Error('not implemented')

# _users worker
db = couch_utils.nano_system_user.use('moirai')
worker.start_worker(db,
                    handlers,
                    get_doc_type
                   )
