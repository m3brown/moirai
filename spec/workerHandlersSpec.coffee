Promise = require('pantheon-helpers/lib/promise')
conf = require('../lib/config')
conf.AWS.STARTUP_SECONDS = .01
handlers = require('../lib/workerHandlers')
ec2Client = require('../lib/ec2Client')
ec2KeyManagement = require('../lib/ec2KeyManagement')
_ = require('underscore')

describe 'c+', () ->
    beforeEach () ->
        spyOn(ec2Client, 'createInstance').andCallFake((instance) ->
            if instance.id == 'bad-instance'
                return Promise.reject('There was an error creating the instance')
            else
                return Promise.resolve({
                    InstanceId: 'instanceid-' + instance.id
                    InstanceType: 't1.micro'
                    PrivateIpAddress: 'ip-' + instance.id # dummy value 
                    KeyName: 'moirai'
                    Tags: [
                        {Key: 'Name', Value: 'awsdevtestname'}
                    ]
                })
        )
        spyOn(ec2KeyManagement, 'addSSHKeys').andCallFake((host, pubkeys) ->
            for pubkey in pubkeys
                if pubkey == 'failing_key'
                    return Promise.reject('failing_key')
            return Promise.resolve()
        )
        this.event = {
            a: 'c+'
            record:
                instances: [
                        InstanceType: 't1.micro'
                        tags:
                            Name: 'awsdevtestname'
                        id: 'passing-instance'
                    ,
                        InstanceType: 't1.medium'
                        tags:
                            Name: 'awsdevtestname2'
                        id: 'bad-instance'
                ],
                keys: [
                    'key1'
                    'key2'
                    'key3'
                ],
                name: 'a_cluster'
        }
        this.doc =
            instances: [
                    id: 'passing-instance'
                    name: 'awsdevtestname'
                    size: 't1.micro'
                ,
                    id: 'bad-instance'
                    name: 'awsdevtestname2'
                    size: 't1.medium'
            ]

    it 'passes each instance to createInstance', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(ec2Client.createInstance.calls.length).toEqual(2)
            done()
        )

    it 'rejects if one or more instances failed', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            done()
        )

    it 'marks successful instances as resolved', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(_.where(err.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            instance = _.findWhere(err.data.instances, {aws_id: 'instanceid-passing-instance'})
            expect(instance.id).toEqual('passing-instance')
            expect(instance.state).toEqual(undefined)
            done()
        )

    it 'marks failed instances as create_failed', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('bad-instance')
            done()
        )

    it 'resolves if no instances failed', (done) ->
        cut = handlers.cluster['c+']
        failing_instance = _.findWhere(this.event.record.instances, {id: 'bad-instance'})
        passing_event = this.event
        passing_event.record.instances = _.without(this.event.record.instances, failing_instance)
        cut(passing_event, this.doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(_.where(result.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            instance = _.findWhere(result.data.instances, {aws_id: 'instanceid-passing-instance'})
            expect(instance.id).toEqual('passing-instance')
            expect(instance.state).toEqual(undefined)
            done()
        )

    it 'returns updated instance status in data when rejecting', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            expect(instance.aws_id).toEqual(undefined)
        for instance in this.event.record.instances
            expect(instance.aws_id).toEqual(undefined)

        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(_.where(err.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            done()
        )

    it 'returns updated instance status in data when resolving', (done) ->
        cut = handlers.cluster['c+']
        failing_instance = _.findWhere(this.event.record.instances, {id: 'bad-instance'})
        passing_event = this.event
        passing_event.record.instances = _.without(this.event.record.instances, failing_instance)
        for instance in this.doc.instances
            expect(instance.aws_id).toEqual(undefined)
        for instance in passing_event.record.instances
            expect(instance.aws_id).toEqual(undefined)

        cut(passing_event, this.doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(_.where(result.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            done()
        )

    it 'does not execute createInstance on a successful instance twice', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).catch((err) =>
            expect(ec2Client.createInstance.calls.length).toEqual(2)
            expect(err.data.instances.length).toEqual(2)
            expect(_.where(err.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('bad-instance')
            new_doc = _.clone(this.doc)
            new_doc.instances = err.data.instances
            cut(this.event, new_doc)
        ).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            # the second time cut is run, expect the call count to increment by one
            expect(ec2Client.createInstance.calls.length).toEqual(3)
            expect(err.data.instances.length).toEqual(2)
            expect(_.where(err.data.instances, {aws_id: 'instanceid-passing-instance'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('bad-instance')
            done()
        )

    it 'does not create an instance if the state is terminate', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            instance.state = 'terminate'
        cut(this.event, this.doc).catch(() ->
            done('Test failed, promise should have resolved but was rejected')
        ).then(() ->
            expect(ec2Client.createInstance.calls.length).toEqual(0)
            done()
        )

    it 'does not create an instance if the state is terminate_failed', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            instance.state = 'terminate'
        cut(this.event, this.doc).catch(() ->
            done('Test failed, promise should have resolved but was rejected')
        ).then(() ->
            expect(ec2Client.createInstance.calls.length).toEqual(0)
            done()
        )

    it 'creates an instance if the state is a random value', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            instance.state = 'do_term'
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch(() ->
            expect(ec2Client.createInstance.calls.length).toEqual(2)
            done()
        )

    it 'does not create an instance if the aws_id already exists', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            instance.aws_id = 'some_aws_id'
        cut(this.event, this.doc).catch(() ->
            done('Test failed, promise should have resolved but was rejected')
        ).then(() ->
            expect(ec2Client.createInstance.calls.length).toEqual(0)
            done()
        )

    it 'creates an instance if the aws_id does not exist', (done) ->
        cut = handlers.cluster['c+']
        for instance in this.doc.instances
            instance.aws_id = undefined
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch(() ->
            expect(ec2Client.createInstance.calls.length).toEqual(2)
            done()
        )

    it 'runs addSSHKeys if keys are provided', (done) ->
        cut = handlers.cluster['c+']
        passing_instance = _.findWhere(this.event.record.instances, {id: 'passing-instance'})
        this.event.record.instances = [passing_instance]
        cut(this.event, this.doc).catch(() ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) =>
            expect(ec2KeyManagement.addSSHKeys.calls.length).toEqual(1)
            expect(ec2KeyManagement.addSSHKeys).toHaveBeenCalledWith('ip-passing-instance', this.event.record.keys)
            done()
        )

    # TODO discuss the best way to handle this scneario
    it 'resolves even if addSSHKeys fails', (done) ->
        cut = handlers.cluster['c+']
        passing_instance = _.findWhere(this.event.record.instances, {id: 'passing-instance'})
        this.event.record.instances = [passing_instance]
        this.event.record.keys = [
            'failing_key',
        ]
        cut(this.event, this.doc).catch(() ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) =>
            expect(ec2KeyManagement.addSSHKeys.calls.length).toEqual(1)
            expect(ec2KeyManagement.addSSHKeys).toHaveBeenCalledWith('ip-passing-instance', this.event.record.keys)
            done()
        )

    it 'only runs addSSHKeys for hosts that were created', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) =>
            expect(ec2KeyManagement.addSSHKeys.calls.length).toEqual(1)
            expect(ec2KeyManagement.addSSHKeys).toHaveBeenCalledWith('ip-passing-instance', this.event.record.keys)
            done()
        )

    it 'does not run addSSHKeys if keys are not provided', (done) ->
        cut = handlers.cluster['c+']
        this.event.record.keys = []
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(ec2KeyManagement.addSSHKeys.calls.length).toEqual(0)
            done()
        )

describe 'c-', () ->
    beforeEach () ->
        spyOn(ec2Client, 'destroyInstance').andCallFake((aws_id) ->
            if aws_id == 'bad-instanceid'
                return Promise.reject('There was an error destroying the instance')
            else
                return Promise.resolve()
        )
        this.event = {
            a: 'c-'
        }
        this.doc =
            instances: [
                    id: 'passing-instance'
                    name: 'awsdevtestname'
                    size: 't1.micro'
                    aws_id: 'instanceid-passing-instance'
                ,
                    id: 'incomplete-instance'
                    name: 'awsdevtestname2'
                    size: 't1.medium'
                ,
                    id: 'bad-instance'
                    name: 'awsdevtestname3'
                    size: 't1.large'
                    aws_id: 'bad-instanceid'
            ]

    it 'passes instances with aws_id to destroyInstance', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch(() ->
            expect(ec2Client.destroyInstance.calls.length).toEqual(2)
            done()
        )

    it 'rejects if one or more instances failed', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch(() ->
            done()
        )

    it 'deletes successfully destroyed instances', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(_.where(err.data.instances, {id: 'passing-instance'}).length).toEqual(0)
            expect(_.where(err.data.instances, {id: 'incomplete-instance'}).length).toEqual(1)
            expect(_.where(err.data.instances, {id: 'bad-instance'}).length).toEqual(1)
            done()
        )

    it 'marks failed instances as terminate_failed', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            instance = _.findWhere(err.data.instances, {id: 'bad-instance'})
            expect(instance.state).toEqual('terminate_failed')
            done()
        )

    it 'does not modify an instance that has no aws_id', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            instance = _.findWhere(err.data.instances, {id: 'incomplete-instance'})
            expect(instance.aws_id).toEqual(undefined)
            expect(instance.state).toEqual(undefined)
            done()
        )

    it 'resolves if no instances failed', (done) ->
        cut = handlers.cluster['c-']
        passing_doc = this.doc
        passing_doc.instances = _.reject(this.doc.instances, (instance) ->
            return instance.id == 'bad-instance'
        )
        expect(passing_doc.instances.length).toEqual(2)
        cut(this.event, passing_doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(result.data.instances.length).toEqual(1)
            expect(_.where(result.data.instances, {id: 'incomplete-instance'}).length).toEqual(1)
            done()
        )
