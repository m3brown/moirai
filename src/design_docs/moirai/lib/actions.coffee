do_action = require('./shared/do_action')
validate_doc_update = require('./shared/validate_doc_update').validate_doc_update
_ = require('./underscore')

a = {}

a.get_doc_type = (doc) ->
    if doc._id.indexOf('_') < 0
        return undefined
    return doc._id.split('_')[0]

a.do_actions = {
    cluster: {
        'c-': (doc, action, actor) ->
            doc.instances.forEach((instance) ->
                instance.state = 'terminate'
            )
    },
    create: {
        'c+': (doc, action, actor) ->
            _.extend(doc, {
                _id: 'cluster_' + doc._id,
                name: action.record.name,
                created: +new Date(),
                instances: action.record.instances.map((instance) ->
                    return {
                        id: instance.id,
                        name: instance.tags.Name,
                        size: instance.InstanceType,
                    }
                ),
            })
    },
}

a.validate_actions = {
    cluster: {
        'c+': (event, actor, old_doc, new_doc) ->
        'c-': (event, actor, old_doc, new_doc) ->
    }
}

a.do_action = do_action(
                a.do_actions,
                a.get_doc_type,
              )

a.validate_doc_update = validate_doc_update(
                          a.validate_actions,
                          a.get_doc_type,
                        )

a.mixin = (dd) ->
  dd.validate_doc_update = a.validate_doc_update
  dd.updates.do_action = a.do_action

module.exports = a
