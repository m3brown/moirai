_ = require('underscore')
actions = require('./actions')
audit = require('pantheon-helpers').design_docs.audit

dd =
  views: {
    active_clusters: {
       map: (doc) ->
         # can't import from outside views
         # dupe of function in './actions'
         get_doc_type = (doc) ->
             if doc._id.indexOf('_') < 0
                 return undefined
             return doc._id.split('_')[0]

         if get_doc_type(doc) == 'cluster' and doc.instances.length
           for instance in doc.instances
             if instance.state != 'terminate'
               emit(doc._id)
               return
    },
    cluster_scheduled_shutdown: {
       map: (doc) ->
         # can't import from outside views
         # dupe of function in './actions'
         get_doc_type = (doc) ->
             if doc._id.indexOf('_') < 0
                 return undefined
             return doc._id.split('_')[0]

         if get_doc_type(doc) == 'cluster' and doc.instances.length
           for instance in doc.instances
             if instance.state? == 'terminate'
               return
           if doc.shutdown?
             awsIds = doc.instances.map((instance) ->
               return instance.aws_id
             )
             #underscore doesn't work!
             #awsIds = _.chain(clusters)
             #          .pluck('aws_id')
             #          .compact()
             emit(doc.shutdown, awsIds)
           return
    }
  }

  lists: {
    get_docs: (header, req) ->
      out = []
      while(row = getRow())
        val = row.doc
        out.push(val)
      return JSON.stringify(out)
    get_docs_without_audit: (header, req) ->
      out = []
      while(row = getRow())
        val = row.doc
        delete val.audit
        out.push(val)
      return JSON.stringify(out)
  }
  shows: {}

  updates: {}

  rewrites: []

audit.mixin(dd)
actions.mixin(dd)

try
  require('underscore')
  dd.emitted = []
  emit = (k, v) -> dd.emitted.push({k: k, v: v}) 

module.exports = dd
