#-----------------------------------
 Name		UdpBroker
 Task 		UDP message broker

public methods
--------------

publish(topic,value)		publish the value to the given topic
subscribe(topic,closure)    susbscribe to a specific topic with callback-function(topic,payload)
unsubscribe(topic)          unsubscribe from specific topic
deinit()                    unitialize the broker
init(name)                  create an initialize the broker

Tasmota Commands
----------------
udppub <topic> <payload>    publish a message with topic/payload
udpsub <topic>              subscribe for a topic; on receive perfrom command : event <topic>=<payload>
udpunsub <topic>            unsubscribe topic

-----------------------------------#
import string
import json
import undefined
import xtool

#@ solidify:TopicNames
class TopicNames

    static CcuThermostat = "CCU/thermostat"  
    static CcuButton = "CCU/button"  # payload : {"ButtonShort":true}
    static CcuOutside = "CCU/outside"

    static CentralFan = "global/centralFan"

    static ExcessCoordination = "global/controller/excess"

     static MeterPowerAVOld = "SM.PowerAV"
     static MeterPowerAV = "meter/power/average"    
     static Mi32Sensors="global/mi32Sensors/temperature"

     static OpenMeteo="global/meteo"

     static RoomK1 = "room/K1"

     static Testing = "global/testing"
end

#@ solidify:UdpTopic
class UdpTopic
    var topic
    var closure
    var isCmd
end	

#@ solidify:UdpBroker
class UdpBroker
    
    static PORT = 12233
    static IP = "224.3.0.1"

    var paketCounter
    var tickCounter
    var udp
    var topics

    var name
    var infoEnable
    var lastLogInfo
    var lastWarnInfo
    var lastLogProc

    var sensorTopic

    var publishSensorEnable
    var lastTele

    #-
    callback          if broker is started
    para              (self)
    -#
    var onStarted

    #-
    callback          if broker is stopped
    para              (self)
    -#
    var onStopped

     # log with level 'INFO'
     def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "+self.name+"."+proc+" - "+info) end
     end

    # log with level 'WARN'
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "+self.name+"."+proc+" - "+info)
    end

    #-
    function      publish the value(string) to the given topic(string)
    return        true if successful, false otherwise
    -#
    def publish(topic,value)
        var cproc="publish"

        if type(topic)!="string" || size(topic)==0
            self.warn(cproc,"topic must be a non-null-string")
            return false
        end

        if value==nil
            self.warn(cproc,"value must not be null")
            return false
        end

        var msg = DynClass()
        msg.topic = topic
        msg.payload = value
        
        # convert message to json and send via UDP broadcast
        var tele = msg.toJson()
        if self.udp 
            self.info(cproc,tele)
            self.udp.send_multicast(bytes().fromstring(tele))
        else
            self.warn(cproc,"udp client not defined")
            return false
        end

        return true
    end

    #-
    function      susbscribe to a specific topic
    return        true, if all checks are ok, false otherwise
    -#
    def subscribe(topic,closure,isCmd)
        var cproc="subscribe"

        # closure must be  a function
        if type(closure) != 'function'
            self.warn(cproc," closure is not a function")
            return false
        end

        for m : self.topics
            var found=false

            if isCmd
                found=m.topic == topic && m.isCmd
            else
                found=m.topic == topic && !m.isCmd
            end

            if found
                self.info(cproc,"topic already subscribed:"+str(topic))
                return  false                                    
            end
        end

        var xtopic = UdpTopic()
        xtopic.topic = topic
        xtopic.closure = closure
        xtopic.isCmd = isCmd==true

        self.topics.push(xtopic)
        self.info(cproc,"subscribe to topic:"+str(topic))

        return true
    end

    #-
    function      unsubscribe a specific topic
    return        true, if all checks are ok, false otherwise
    -#
    def unsubscribe(topic,isCmd)

        if self.topics == nil  return end 
        ## convert to boolean
        isCmd = isCmd == true

        var i = 0
        while i < size(self.topics)
            var xtopic = self.topics[i]

            if xtopic.topic == topic && xtopic.isCmd == isCmd
                self.topics.remove(i)   # remove and don't increment
            else
                i += 1
            end
        end        
    end

    # forward the message to all subscribers for given topic
    def process(topic,payload)
        var cproc="process"

        # loop over all subscribed topics
        for m : self.topics
            # on match, execute the associated closure and implement error handling
            if m.topic == topic
                try
                    m.closure(topic,payload)
                except .. as exname, exmsg
                    self.warn(cproc, str(exname) + " - " + str(exmsg))
                end
            end
        end
    end

    def every_hour()
        var cproc="every_hour"
        self.info(cproc,"begin")

        self.restart()
    end

    #-
      - checks perodically for incomming udp-messages
      - checks the validity
      - forwards the message to the subscribers
    -#
    def every_100ms()
        var cproc="every_poll"

        # shortcut, if listener is not started
        if self.udp==nil
            return
        end
        
        # only for debugging issues
        self.tickCounter=self.tickCounter+1
        if self.tickCounter>=1000
            self.tickCounter=0
        end

        # try to read the udp packet
        var packet = self.udp.read()
        if packet == nil
            return
        end
        
        # packet counter runs till 1000
        self.paketCounter=self.paketCounter+1
        if self.paketCounter>=1000
            self.paketCounter=0
        end

        # get paket as string
        var ss = packet.asstring()

        # udp message must be a json-string
        if !xtool.isJson(ss)
            self.warn(cproc,"got a non-json-message:"+ss)
            return
        end

        # map json to a dynamic class; property topic must exist
        var msg = DynClass()
        msg.loadJson(ss)
        if msg.topic == undefined
            self.warn(cproc,"missing member topic:"+ss)
            return
        end

        # property payload must exist
        if msg.payload == undefined
            self.warn(cproc,"missing member payload:"+ss)
            return
        end  

        if self.infoEnable
            self.info(cproc,"got valid message:"+ss)
        end

        # further processing of the message
        self.process(msg.topic,msg.payload)
    end

    def restart()
        var cproc="restart"
        self.stop(true)
        self.start(true)
        self.info(cproc,"done")
    end

    # start the udp-listener
    def start(isRestart)
	   var cproc="start"

       if (self.udp != nil)
            self.warn(cproc,"udp client not null")
            return
       end

       isRestart = isRestart==true

       self.udp = udp()      
       var result = self.udp.begin_multicast(self.IP, self.PORT)
       self.warn(cproc,"broker started with result:"+str(result)+ " and isRestart="+ str(isRestart))

       if self.onStarted && !isRestart
            try
                self.onStarted(self)
            except .. as exname, exmsg
                self.warn(cproc, str(exname) + " - " + str(exmsg))
            end  
       end

       return result
    end

    # stops the udp-listener
    def stop(isRestart)
        var cproc="stop"
        if (self.udp==nil)
            return
        end  

        isRestart = isRestart==true

        self.udp.close()
        self.udp = nil
        self.warn(cproc,"broker stopped isRestart=" + str(isRestart))

        if self.onStopped  && !isRestart
            try
                self.onStopped(self)
            except .. as exname, exmsg
                self.warn(cproc, str(exname) + " - " + str(exmsg))
            end  
       end

    end

    # get command parts
    def getParts(payload)
        var parts = string.split(payload," ")

        # remove empty parts
	    var i=0
		while i < size(parts)
			if size(parts[i]) == 0
				parts.remove(i)   
			else
				i += 1
			end
		end
        return parts
    end

    # the handler for the command udppub
    def cmdHandlerPub(cmd, idx, payload, payload_json)
        var cproc="cmdHandlerPub"

        if self.infoEnable self.info(cproc,"cmd:" + cmd +" payload:"+payload) end

        var parts = self.getParts(payload)

		# we need at least 2 non-null args
		if size(parts)<2 
		    tasmota.resp_cmnd_failed()
            self.warn(cproc,"need at least 2 arguments")
		    return
		end

        # get the payload part of the command, wich is all after the topic
        var xtopic = parts[0]
        var xpayload = string.split(payload,size(xtopic)+1)[1]

        # publish message using broker
		self.publish(xtopic ,xpayload) 

        # return OK result to tasmota
		tasmota.resp_cmnd_done()
    end

    # triggers the rules-event
    def triggerEvent(topic, payload)
        var cproc="triggerEvent"
        var ss=nil

        if xtool.isJson(payload)
            # use the map instead of string
            if self.infoEnable self.info(cproc,"payload is json") end
            payload=xtool.lastJsonResult
        end

        # create nested json object like  {"udpBroker":{"SM.PowerAV":"2917.8"}}
        var nested = DynClass()
        nested[topic]=payload
        
        var dyn = DynClass()
        dyn.udpBroker = nested.toMap()
        ss = dyn.toJson()

        if self.infoEnable self.info(cproc,f"fire event {ss}") end

        # feed the rules engine
        tasmota.publish_rule(ss)
    end

    # the handler for the command udpsub
    def cmdHandlerSub(cmd, idx, payload, payload_json)
        var cproc="cmdHandlerSub"

        self.info(cproc,f"{cmd=} {payload=}")
      
        # get all arguments
		var parts = self.getParts(payload)

		# we need at least 1 non-null args
		if size(parts)<1 
		    tasmota.resp_cmnd_failed()
            self.warn(cproc,"need at least 1 arguments")
		    return
		end

        var xtopic = parts[0]

        # publish message using broker
		self.subscribe(xtopic,def(topic,payload) self.triggerEvent(topic,payload) end,true) 

        # return OK result to tasmota
		tasmota.resp_cmnd_done()
    end

    # the handler for the command udpunsub
    def cmdHandlerUnsub(cmd, idx, payload, payload_json)
        var cproc="cmdHandlerUnsub"

        self.info(cproc,f"{cmd=} {payload=}")
        
            # get all arguments
		var parts = self.getParts(payload)

		# we need at least 1 non-null args
		if size(parts)<1 
		    tasmota.resp_cmnd_failed()
            self.warn(cproc,"need at least 1 arguments")
		    return
		end

        var xtopic = parts[0]

        # unsubscribe topic 
		self.unsubscribe(xtopic,true)

        # return OK result to tasmota
		tasmota.resp_cmnd_done()
    end

    # add a new tasmota commands
    def addCommands()
        var cproc="addCommands"

        var cmd="udppub"
        tasmota.remove_cmd(cmd)
        tasmota.add_cmd(cmd,
            def (cmd, idx, payload, payload_json) self.cmdHandlerPub(cmd, idx, payload, payload_json) end
        )
        self.info(cproc,f"added {cmd=}")

        cmd="udpsub"
        tasmota.remove_cmd(cmd)
        tasmota.add_cmd(cmd,
            def (cmd, idx, payload, payload_json) self.cmdHandlerSub(cmd, idx, payload, payload_json) end
        )
        self.info(cproc,f"added {cmd=}")

        cmd="udpunsub"
        tasmota.remove_cmd(cmd)
        tasmota.add_cmd(cmd,
            def (cmd, idx, payload, payload_json) self.cmdHandlerUnsub(cmd, idx, payload, payload_json) end
        )
        self.info(cproc,f"added {cmd=}")
    end

    def teleHandler(value, trigger)
        # print ("teleHandler.01")
        self.lastTele = value

        if !value.contains("Wifi") && string.find(str(self.lastTele),"Time")==2
            # print ("publish sensor:",value)
            self.publish(self.sensorTopic,json.dump(value))
        end
    end

    def publishSensorMsg(value)

        self.publishSensorEnable = value == true

        tasmota.remove_rule("tele")

        if self.publishSensorEnable     
            tasmota.add_rule("tele",def(value,trigger) self.teleHandler(value,trigger) end)
        end

    end

    # destructor
    def deinit()
        var cproc="deinit"
        self.stop()

        tasmota.remove_driver(self)
        tasmota.remove_cron("udpBroker")
        self.warn(cproc,"deinit done")    

    end

	# constructor	
	def init(name)
		var cproc="init"
	
        if name==nil
            name="UdpBroker"
        end

        self.publishSensorEnable = false

        # -------- create sensor topic
        var fullTopic = tasmota.cmd('FullTopic')['FullTopic']

        # tasmota_boiler_pm
        var topic = tasmota.cmd('Topic')['Topic']

        # tele
        var prefix = tasmota.cmd('Prefix')['Prefix3']

         # %prefix%/tasmota_boiler_pm/
        var udpSensorTopic = string.replace(fullTopic, '%topic%', topic)
        udpSensorTopic = string.replace(udpSensorTopic, '%prefix%', prefix)
        udpSensorTopic += 'SENSOR'
        self.sensorTopic = udpSensorTopic

        # --------
        self.paketCounter=0
        self.tickCounter=0
        self.topics=[]

        self.name = name
        self.infoEnable = true
        self.info(cproc,f"udp-broker created using IP:{self.IP} Port:{self.PORT}")
        self.infoEnable = false	
        self.addCommands()
        tasmota.add_driver(self)
        tasmota.add_cron("0 0 * * * *", /-> self.every_hour(),"udpBroker") # each hour
        tasmota.add_rule("Wifi#Connected", / -> self.start()) 
        tasmota.add_rule("Wifi#Disconnected", / -> self.stop()) 

        # in case of manual creation, follow the wifi state
        if tasmota.wifi()["up"]
            self.start()
        end

	end	   
 end      



