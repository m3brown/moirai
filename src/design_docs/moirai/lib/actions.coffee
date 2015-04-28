do_action = require('pantheon-helpers').design_docs.do_action
validate_doc_update = require('pantheon-helpers').design_docs.validate_doc_update.validate_doc_update
_ = require('underscore')

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
        'k': (doc, action, actor) ->
            doc.keys = action.keys
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
        'k': (event, actor, old_doc, new_doc) ->
          if not _.isArray(event.keys)
            throw({
              state: 'invalid',
              err: '`keys` should be an array, but got ' + JSON.stringify(event.keys)
            })

          isPubKeyValid = (key) ->
            return key.match(/^ssh-rsa AAAA[0-9A-Za-z+/]+[=]{0,3} [0-9A-Za-z.-]+(@[0-9A-Za-z.-]+)?$/)

          for key in event.keys
            if not isPubKeyValid(key)
              throw({
                state: 'invalid',
                err: 'invalid public key: '+key
              })
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
