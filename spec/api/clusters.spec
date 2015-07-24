clusters = require('../lib/api/clusters')
Promise = require('pantheon-helpers/lib/promise')
doAction = require('pantheon-helpers/lib/doAction')

describe 'cluster', () ->
    beforeEach () ->
        this.preparedInstance = {InstanceId: 'testid'}, 
        this.record = {name:'foo', instances :[]}
        this.cut = clusters
        spyOn(clusters, 'doAction').andReturn('userData')

    it 'generates a startup timestamp', () ->

        //given
        date =new Date()
        client ={
        	use: function(data){return 'moirai';}
        }
        actionObj = {
        	createdTimestamp: date
        }
        //then
        this.cut.createCluster(client, this.record,actionObj )
        expectedClusterObj = actionObj
        expectedClusterObj.record =recod
        //assert
        expectedParams= ['moirai', 'moirai' , null, expectedClusterObj, 'promise']
       	expect(clusters.doAction).toHaveBeenCalledWith(expectedParams)


    it 'generates a shutdown timestamp', (done) ->
        cut = ec2Client.createInstance
        cut("opts").then(() ->
          expect(ec2Client.generateParams).toHaveBeenCalledWith("opts")
          done()
        ).catch((error) ->
          done("Test failed, promise should've been resolved but was rejected")
        )    