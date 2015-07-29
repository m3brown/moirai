clusters = require('../../lib/api/clusters')
Promise = require('pantheon-helpers/lib/promise')
doAction = require('pantheon-helpers/lib/doAction')

describe 'cluster', () ->
    beforeEach () ->
        this.preparedInstance = {InstanceId: 'testid'}
        this.record = {name:'foo', instances :[{},{}]}
        this.cut = clusters
        spyOn(clusters, 'doAction').andReturn('userData')

        this.client ={
            use: (data) -> return 'moirai'
        }

    it 'should call doAction with correct params', () ->

        # given
        startTime = new Date('2000', '01', '01', '01', '00', '00', '00')
        expectedShutdownTime = new Date('2000', '01', '16', '01', '00', '00', '00')
        
        actionObj = {
            createdTimestamp: startTime, 
            scheduledShutdown:expectedShutdownTime
        }
        result = this.cut.createCluster(this.client, this.record, actionObj)
       
        expectedClusterObj = actionObj
        expectedClusterObj.record = this.record
        # assert
        expectedParams= ['moirai', 'moirai' , null, expectedClusterObj, 'promise']
        expect(clusters.doAction).toHaveBeenCalledWith(expectedParams...)

    
    it 'generates a shutdown timestamp', () ->
        startTime = new Date('2000', '01', '01', '01', '00', '00', '00')
        expectedShutdownTime = new Date('2000', '01', '16', '01', '00', '00', '00')

        result = this.cut.getCreateObject(startTime)
        expect(result.createdTimestamp).toEqual(startTime)
        expect(result.scheduledShutdown).toEqual(expectedShutdownTime)

        # ensure timestamps carry across months
        # Jan 25 + 15 = Feb 09
        startTime = new Date('2000', '00', '25', '01', '00', '00', '00')
        expectedShutdownTime = new Date('2000', '01', '09', '01', '00', '00', '00')

        result = this.cut.getCreateObject(startTime)
        expect(result.createdTimestamp).toEqual(startTime)
        expect(result.scheduledShutdown).toEqual(expectedShutdownTime)




    it 'creates actionObject when not provided', ()->
        spyOn(clusters, 'getCreateObject').andReturn({})
     
        result = this.cut.createCluster(this.client, this.record, null)
       
        expect(clusters.getCreateObject).toHaveBeenCalled()

    it 'assigns id to instances', ()->
      this.cut.createCluster(this.client, this.record)
      expect(this.record.instances[0].id).toBeDefined()
      expect(this.record.instances[1].id).toBeDefined()

    it 'should reject the promise if record name is null', (done)->
        promise =  this.cut.createCluster(this.client, {}, null)

        promise.then(() ->
            done('Test failed, promise should have been rejected but was resolved')
        ).catch((err) ->
            expect(err).toBe('Cluster name not provided')
            done()
        )