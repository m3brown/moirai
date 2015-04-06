Promise = require('pantheon-helpers/lib/promise')
handlers = require('../lib/workerHandlers')
ec2Client = require('../lib/ec2Client')
_ = require('underscore')

describe 'c+', () ->
    beforeEach () ->
        spyOn(ec2Client, 'createInstance').andCallFake((instance) ->
            if instance.id == 'ec855ef9-45c4-45bc-a4d3-f930e158579c'
                return Promise.resolve({
                    InstanceId: 'randominstanceid'
                    InstanceType: 'ti.micro'
                    KeyName: 'moirai'
                    Tags: [
                        {Key: 'Name', Value: 'awsdevtestname'}
                    ]
                })
            else
                return Promise.reject('There was an error creating the instance')
        )
        this.event = {
            a: 'c+'
            record:
                instances: [
                        InstanceType: 't1.micro'
                        tags:
                            Name: 'awsdevtestname'
                        id: 'ec855ef9-45c4-45bc-a4d3-f930e158579c'
                    ,
                        InstanceType: 't1.medium'
                        tags:
                            Name: 'awsdevtestname2'
                        id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'
                ],
                name: 'a_cluster'
        }
        this.doc =
            instances: [
                    id: 'ec855ef9-45c4-45bc-a4d3-f930e158579c'
                    name: 'awsdevtestname'
                    size: 't1.micro'
                ,
                    id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'
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
            expect(_.where(err.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            instance = _.findWhere(err.data.instances, {aws_id: 'randominstanceid'})
            expect(instance.id).toEqual('ec855ef9-45c4-45bc-a4d3-f930e158579c')
            expect(instance.state).toEqual(undefined)
            done()
        )

    it 'marks failed instances as create_failed', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('5d8fc7d9-6233-46c7-b71f-d59b4ba9098f')
            done()
        )

    it 'resolves if no instances failed', (done) ->
        cut = handlers.cluster['c+']
        failing_instance = _.findWhere(this.event.record.instances, {id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'})
        passing_event = this.event
        passing_event.record.instances = _.without(this.event.record.instances, failing_instance)
        cut(passing_event, this.doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(_.where(result.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            instance = _.findWhere(result.data.instances, {aws_id: 'randominstanceid'})
            expect(instance.id).toEqual('ec855ef9-45c4-45bc-a4d3-f930e158579c')
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
            expect(_.where(err.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            done()
        )

    it 'returns updated instance status in data when resolving', (done) ->
        cut = handlers.cluster['c+']
        failing_instance = _.findWhere(this.event.record.instances, {id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'})
        passing_event = this.event
        passing_event.record.instances = _.without(this.event.record.instances, failing_instance)
        for instance in this.doc.instances
            expect(instance.aws_id).toEqual(undefined)
        for instance in passing_event.record.instances
            expect(instance.aws_id).toEqual(undefined)

        cut(passing_event, this.doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(_.where(result.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            done()
        )

    it 'does not execute createInstance on a successful instance twice', (done) ->
        cut = handlers.cluster['c+']
        cut(this.event, this.doc).catch((err) =>
            expect(ec2Client.createInstance.calls.length).toEqual(2)
            expect(err.data.instances.length).toEqual(2)
            expect(_.where(err.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('5d8fc7d9-6233-46c7-b71f-d59b4ba9098f')
            new_doc = _.clone(this.doc)
            new_doc.instances = err.data.instances
            cut(this.event, new_doc)
        ).then(() ->
            done('Test failed, promise should have been rejected but was not')
        ).catch((err) ->
            # the second time cut is run, expect the call count to increment by one
            expect(ec2Client.createInstance.calls.length).toEqual(3)
            expect(err.data.instances.length).toEqual(2)
            expect(_.where(err.data.instances, {aws_id: 'randominstanceid'}).length).toEqual(1)
            expect(_.where(err.data.instances, {state: 'create_failed'}).length).toEqual(1)
            expect(_.findWhere(err.data.instances, {state: 'create_failed'}).id).toEqual('5d8fc7d9-6233-46c7-b71f-d59b4ba9098f')
            done()
        )

describe 'c-', () ->
    beforeEach () ->
        spyOn(ec2Client, 'destroyInstance').andCallFake((aws_id) ->
            if aws_id
                return Promise.resolve()
            else
                return Promise.reject('There was an error destroying the instance')
        )
        this.event = {
            a: 'c-'
        }
        this.doc =
            instances: [
                    id: 'ec855ef9-45c4-45bc-a4d3-f930e158579c'
                    name: 'awsdevtestname'
                    size: 't1.micro'
                    aws_id: 'randominstanceid'
                ,
                    id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'
                    name: 'awsdevtestname2'
                    size: 't1.medium'
            ]

    it 'passes instances with aws_id to destroyInstance', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(ec2Client.destroyInstance.calls.length).toEqual(1)
            done()
        )

    it 'rejects if one or more instances failed', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            done()
        )

    it 'deletes successfully destroyed instances', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(err.data.instances.length).toEqual(1)
            expect(err.data.instances[0].aws_id).toEqual(undefined)
            done()
        )

    it 'marks failed instances as terminate_failed', (done) ->
        cut = handlers.cluster['c-']
        cut(this.event, this.doc).then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(err.data.instances.length).toEqual(1)
            instance = err.data.instances[0]
            expect(err.data.instances[0].state).toEqual('terminate_failed')
            done()
        )

    it 'resolves if no instances failed', (done) ->
        cut = handlers.cluster['c-']
        #failing_instance = _.findWhere(this.doc.instances, {aws_id: '5d8fc7d9-6233-46c7-b71f-d59b4ba9098f'})
        passing_doc = this.doc
        passing_doc.instances = _.reject(this.doc.instances, (instance) ->
            return not instance.aws_id?
        )
        expect(passing_doc.instances.length).toEqual(1)
        cut(this.event, passing_doc).catch((err) ->
            done('Test failed, promise should have been resolved but was rejected')
        ).then((result) ->
            expect(result.data.instances.length).toEqual(0)
            done()
        )
