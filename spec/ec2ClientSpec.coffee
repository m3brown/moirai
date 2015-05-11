conf = require('../lib/config')
conf.AWS =
  DEFAULT_PARAMS:
    InstanceType: 'm3.large'
    KeyName: 'moirai'
  REQUIRED_PARAMS:
    ImageId: 'testImage'
  USER_PARAMS: [ 'InstanceType', 'SubnetId', 'ImageId' ]
  TAG_PARAMS: [ 'Name', 'Creator' ]
  USERDATA: '''
this is the test user data with
new lines and <HOSTNAME> variables
'''
ec2Client = require('../lib/ec2Client')
Promise = require('pantheon-helpers/lib/promise')

describe 'prepareInstances', () ->
    beforeEach () ->
        this.preparedInstance = {InstanceId: 'testid'}

    it 'returns an instance array when given a Reservation', () ->
        resp_object = {Instances: [this.preparedInstance]}
        cut = ec2Client.prepareInstances
        actual = cut(resp_object)
        expect(actual).toEqual([this.preparedInstance])

    it 'returns an instance array when given a Reservation List', () ->
        resp_object = {Reservations: [{Instances: [this.preparedInstance]}]}
        cut = ec2Client.prepareInstances
        actual = cut(resp_object)
        expect(actual).toEqual([this.preparedInstance])

describe 'generateParams', () ->
    it 'will only allow opts listed in USER_PARAMS', () ->
        opts = {
          InstanceType: 'overrideInstance',
          SubnetId: 'overrideSubnet',
          NewEntry: 'overrideEntry',
        }
        cut = ec2Client.generateParams
        actual = cut(opts)
        expect(actual.InstanceType).toEqual('overrideInstance')
        expect(actual.SubnetId).toEqual('overrideSubnet')
        expect(actual.NewEntry).toEqual(undefined)

    it 'will not allow opts to override required_params', () ->
        opts = {ImageId: 'overrideImage'}
        cut = ec2Client.generateParams
        actual = cut(opts)
        expect(actual.ImageId).toEqual('testImage')

    it 'will allow opts to override default params', () ->
        opts = {InstanceType: 'overrideInstance'}
        cut = ec2Client.generateParams
        actual = cut(opts)
        expect(actual.InstanceType).toEqual('overrideInstance')

    it 'will always return MaxCount = 1', () ->
        opts = {MaxCount: 2}
        cut = ec2Client.generateParams
        actual = cut(opts)
        expect(actual.MaxCount).toEqual(1)

describe 'generateTags', () ->
    it 'will only allow opts listed in TAG_PARAMS', () ->
        tags =
            Name: 'testName',
            Application: 'testApplication',
            NewEntry: 'testEntry'
        cut = ec2Client.generateTags
        actual = cut(tags)
        expect(actual.Name).toEqual('testName')
        expect(actual.Application).toNotEqual('testApplication')
        expect(actual.NewEntry).toEqual(undefined)

    it 'will not allow opts to override required_params', () ->
        opts = {}
        cut = ec2Client.generateTags
        actual = cut(opts)
        expect(actual.Domain).toEqual('dev')

        opts = {Domain: 'new domain'}
        cut = ec2Client.generateTags
        actual = cut(opts)
        expect(actual.Domain).toEqual('dev')

describe 'generateUserData', () ->
    it 'will honor newlines', () ->
        cut = ec2Client.generateUserData
        actual = cut({}, {}, {})
        expect(actual).toMatch(/^new lines/m)

    it 'will apply Name tag', () ->
        tags =
            Name: 'testName',
        cut = ec2Client.generateUserData

        actual = cut({}, {}, {})
        expect(actual).not.toMatch(new RegExp(tags.Name))

        actual = cut({}, {}, tags)
        expect(actual).toMatch(new RegExp(tags.Name))

describe 'createInstance', () ->
    beforeEach () ->
        this.transformed_tags = [{Key: 'tag1', Value: 'value1'}, {Key: 'tag2', Value: 'value2'}]
        spyOn(ec2Client, 'generateParams').andReturn('params')
        spyOn(ec2Client, 'generateTags').andReturn({tag1: 'value1', tag2: 'value2'})
        spyOn(ec2Client, 'generateUserData').andReturn('userData')
        spyOn(ec2Client.ec2, 'runInstances').andReturn(Promise.resolve(
          {Instances: [{InstanceId: 'testid', Tags: []}]}
        ))
        spyOn(ec2Client.ec2, 'createTags').andReturn(Promise.resolve())

    it 'passes the opts to generate params', (done) ->
        cut = ec2Client.createInstance
        cut("opts").then(() ->
          expect(ec2Client.generateParams).toHaveBeenCalledWith("opts")
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )

    it 'passes the tags to generate tags', (done) ->
        cut = ec2Client.createInstance
        cut({testparam: "ignoreme", tags: {tag1: 'value1', tag2: 'value2'}}).then(() ->
          expect(ec2Client.generateTags).toHaveBeenCalledWith({tag1: 'value1', tag2: 'value2'})
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )

    it 'passes the opts, transformed tags, and params to generate user data', (done) ->
        cut = ec2Client.createInstance
        opts = {testparam: "ignoreme", tags: {tag1: 'value1', tag2: 'value2'}}
        cut(opts).then(() =>
          expect(ec2Client.generateUserData).toHaveBeenCalledWith(
            opts,
            'params',
            this.transformed_tags
          )
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )

    it 'passes the params to runInstances', (done) ->
        cut = ec2Client.createInstance
        opts = {testparam: "ignoreme", tags: {tag1: 'value1', tag2: 'value2'}}
        cut(opts).then(() ->
          expect(ec2Client.ec2.runInstances).toHaveBeenCalledWith("params")
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )

    it 'passes the transformed tag params to createTags', (done) ->
        cut = ec2Client.createInstance
        opts = {testparam: "ignoreme", tags: {tag1: 'value1', tag2: 'value2'}}
        cut(opts).then(() =>
          tag_params = {Resources: ['testid'], Tags: this.transformed_tags}
          expect(ec2Client.ec2.createTags).toHaveBeenCalledWith(tag_params)
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )

    it 'prepares the return instance data from runInstances', (done) ->
        cut = ec2Client.createInstance
        opts = {testparam: "ignoreme", tags: {tag1: 'value1', tag2: 'value2'}}
        cut(opts).then((preparedInstance) =>
          expect(preparedInstance).toEqual({InstanceId: 'testid', Tags: this.transformed_tags})
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )
