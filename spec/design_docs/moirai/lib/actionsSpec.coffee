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
 
describe 'do_actions k', () ->
    it 'adds the keys to the cluster', () ->
        cut = actions.do_actions.cluster['k']
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
        action = {
            a: 'c-',
            keys: [
                'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost1.company',
                'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF6 Username2@RandomHost2.company'
            ]
        }
        cut(doc, action, 'actor')
        expect(doc.keys).toEqual(action.keys)

describe 'do_actions c+', () ->
    beforeEach () ->
        this.action = {
            a: 'c+',
            record: {
              name: "cluster-name",
              createdTimestamp: +new Date(),
              scheduledShutdown: (+new Date()).getDate() + 15,
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
        expect(this.doc.created).toEqual(this.action.createdTimestamp)
        expect(this.doc.shutdown).toEqual(this.action.scheduledShutdown)
        
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


describe 'validate_actions k', () ->
    beforeEach () ->
        this.event = {
            a: 'k',
            keys: [
                'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost1.company',
                'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF6 Username2@RandomHost2.company'
            ]
        }
        this.bad_pubkeys = [
            "AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company",
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5",
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1!",
            "ssh-rsa AAAA Username1"
        ]

    it 'does not throw error for well-formatted keys', () ->
        cut = actions.validate_actions.cluster['k']
        cut_wrapper = () =>
          cut(this.event, 'actor', 'old_doc', 'new_doc')
        expect(cut_wrapper).not.toThrow()

    it 'throws invalid error if a key is missing ssh-rsa', () ->
        cut = actions.validate_actions.cluster['k']
        this.event.keys = [this.bad_pubkeys[0]]
        cut_wrapper = () =>
          cut(this.event, 'actor', 'old_doc', 'new_doc')
        expect(cut_wrapper).toThrow()

    it 'throws invalid error if a key is missing username', () ->
        cut = actions.validate_actions.cluster['k']
        this.event.keys = [this.bad_pubkeys[1]]
        cut_wrapper = () =>
          cut(this.event, 'actor', 'old_doc', 'new_doc')
        expect(cut_wrapper).toThrow()

    it 'throws invalid error if a key has an invalid character', () ->
        cut = actions.validate_actions.cluster['k']
        this.event.keys = [this.bad_pubkeys[2]]
        cut_wrapper = () =>
          cut(this.event, 'actor', 'old_doc', 'new_doc')
        expect(cut_wrapper).toThrow()

    it 'throws invalid error if a key has an invalid hash string', () ->
        cut = actions.validate_actions.cluster['k']
        this.event.keys = [this.bad_pubkeys[3]]
        cut_wrapper = () =>
          cut(this.event, 'actor', 'old_doc', 'new_doc')
        expect(cut_wrapper).toThrow()
