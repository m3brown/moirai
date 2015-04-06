actions = require('../../../../lib/design_docs/moirai/lib/actions')

describe 'do_actions c-', () ->
    it 'adds a terminate flag to every instance in the cluster', () ->
        cut = actions.do_actions.cluster['c-']
        doc = {
            instances: [
                {
                    name: "instance1",
                },
                {
                    name: "instance2",
                }
            ]
        }
        action = { a: 'c-' }
        cut(doc, action, 'actor')
        expect(doc.instances[0].state).toEqual('terminate')
        expect(doc.instances[1].state).toEqual('terminate')
 
describe 'do_actions c+', () ->
    beforeEach () ->
        this.action = {
            a: 'c+',
            record: {
              name: "cluster-name",
              instances: [
                  {
                      id: 'instance1.id',
                      InstanceType: 't1.micro',
                      tags: {
                          Name: 'webserver',
                      },
                      unsaved_prop: 'test',
                  },
                  {
                      id: 'instance2.id',
                      InstanceType: 'm1.medium',
                      tags: {
                          Name: 'dbserver',
                      }
                  }
              ]
            }
        }
        this.doc = {_id: 'xxx'}

    it 'creates a doc with name, cluster type prempended to _id, created timestamp', () ->
        cut = actions.do_actions.create['c+']
        cut(this.doc, this.action, 'actor')
        expect(this.doc.name).toEqual('cluster-name')
        expect(this.doc._id).toEqual('cluster_xxx')
        expect(this.doc.created).toEqual(jasmine.any(Number))
        
    it 'creates instances with only id, name, and size', () ->
        cut = actions.do_actions.create['c+']
        cut(this.doc, this.action, 'actor')
        expect(this.doc.instances).toEqual([
            {
                id: 'instance1.id',
                size: 't1.micro',
                name: 'webserver',
            },
            {
                id: 'instance2.id',
                size: 'm1.medium',
                name: 'dbserver',
            }
        ])
