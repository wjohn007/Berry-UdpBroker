#-----------------------------------
 Name		UdpBroker
 Task 		UDP message broker

public methods
--------------

publish(topic,value)		publish the value to the given topic
subscribe(topic,closure)    susbscribe to a specific topic
unsubscribe(topic)          unsubscribe from specific topic
deinit()                    unitialize the broker


-----------------------------------#
import string
import json
import undefined

class UdpTopic
    var topic
    var closure
end	

#------  the PwmDriver implements PWM for mains-power ------#
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

    #-
    callback          if broker is stopped
    para              (self)
    -#
    var onStarted

    #-
    callback          if broker is started
    para              (self)
    -#
    var onStopped

     # log with level INFO
     def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "+self.name+"."+proc+" - "+info) end
     end

    # log with level WARN
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "+self.name+"."+proc+" - "+info)
    end

    #-
    function      publish the value to the given topic
    return        the message to be published 
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
        if self.udp  self.udp.send_multicast(bytes().fromstring(tele)) end

        self.info(cproc,tele)
        return true
    end

    #-
    function      susbscribe to a specific topic
    return        true, if all checks are ok
    -#
    def subscribe(topic,closure)
        var cproc="subscribe"

        # clousure must be  a function
        if type(closure) != 'function'
            self.warn(cproc," closure is not a function")
            return false
        end

        for m : self.topics
            if m.topic == topic && m.closure == closure
                self.info(cproc,"topic already subscribed:"+str(topic))
                return  false                                    
            end
        end

        var xtopic = UdpTopic()
        xtopic.topic = topic
        xtopic.closure = closure
        self.topics.push(xtopic)
        self.info(cproc,"subscribe to topic:"+str(topic))

        return true
    end

    #-
    function      unsubscribe a specific topic
    return        true, if all checks are ok
    -#
    def unsubscribe(topic)
        if self.topics == nil  return end 
        var i = 0

        while i < size(self.topics)
          if topic == nil || self.topics[i].topic == topic
            self.topics.remove(i)   # remove and don't increment
          else
            i += 1
          end
        end        
    end

    # forward the topic to all subscribers for it
    def process(topic,payload)
        var cproc="process"

        # loop over all subscribed topics
        for m : self.topics
            # on match, execute the associated closure and implement error handling
            if m.topic == topic
                try
                    m.closure(topic,payload)
                except .. as exname, exmsg
                    self.warn(cproc, exname + " - " + exmsg)
                end
            end
        end
    end

    #-
    function      checks whether value can be converted into a valid json
    return        true, if value is a valid json, otherwise false 
    -#
    def isJson(value)
        var data = json.load(value)
        if classname(data)=='map'
          return true
        else
          return false
        end 
    end

    #-
      check perodically new incomming messages
        forward the message to subscriber if topic matches
    -#
    def every_100ms()
        var cproc="every_poll"

        # shortcut, if listener is not started
        if self.udp==nil
            return
        end
        
        # only for deubugging issues
        self.tickCounter=self.tickCounter+1
        if self.tickCounter>=1000
            self.tickCounter=0
        end

        # try to read an udp packet
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

        # payload must be a json-string
        if !self.isJson(ss)
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

        self.info(cproc,"got valid message:"+ss)

        # further processing of the message
        self.process(msg.topic,msg.payload)
    end

    # start the udp-listener, publisher
    def start()
	   var cproc="start"
       if (self.udp!=nil)
         return
       end

       self.udp = udp()      
       var result = self.udp.begin_multicast(self.IP, self.PORT)
       self.warn(cproc,"broker started with result:"+str(result))

       if self.onStarted
            try
                self.onStarted(self)
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end  
       end

       return result
    end

    # stop the udp-listener
    def stop()
        var cproc="stop"
        if (self.udp==nil)
            return
        end  

        self.udp.close()
        self.udp=nil
        self.warn(cproc,"broker stopped")

        if self.onStopped
            try
                self.onStopped(self)
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end  
       end

    end

    #-
      the handler for the command udppub

      udppub <topic> <payload>

    -#
    def cmdHandler(cmd, idx, payload, payload_json)
        var cproc="cmdHandler"
        self.info(cproc,"cmd:" + cmd +" payload:"+payload)
      
        # get all arguments
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

		self.info(cproc,"parts:",parts.tostring()," count:"+str(size(parts)))

		# we need at least 2 args
		if size(parts)<2 
		    tasmota.resp_cmnd_failed()
		    return
		end
		
        # publish message using topic and payload
		self.publish(parts[0],parts[1]) 

        # return OK result to tasmota
		tasmota.resp_cmnd_done()
    end

    # add a new tasmota command named 'udppub'
    def addCommand()
        var cproc="addCommand"
        var cmd="udppub"
        tasmota.remove_cmd(cmd)
        tasmota.add_cmd(cmd,
            def (cmd, idx, payload, payload_json) self.cmdHandler(cmd, idx, payload, payload_json) end
        )
        self.info(cproc,"added command:"+cmd)
    end

    # destructor
    def deinit()
        var cproc="deinit"
        self.stop()

        tasmota.remove_driver(self)
        self.warn(cproc,"deinit done")    
    end

	# constructor	
	def init(name)
		var cproc="init"
	
        self.paketCounter=0
        self.tickCounter=0
        self.topics=[]

        self.name = name
        self.infoEnable = true
        self.info(cproc,"udp-broker created using IP:" + self.IP + " Port:"+ str(self.PORT))
        self.infoEnable = false	
        self.addCommand()
        tasmota.add_driver(self)

        tasmota.add_rule("Wifi#Connected", / -> self.start()) 
        tasmota.add_rule("Wifi#Disconnected", / -> self.stop()) 

        # in case of manual creation, follow the wifi state
        if tasmota.wifi()["up"]
            self.start()
        end

	end	   
 end      

