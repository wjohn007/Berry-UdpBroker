# play with functions of udp-Broker

# -----------------  Simple Example

# recreate udp-broker

if global.udpBroker
  global.udpBroker.deinit()
  global.udpBroker=nil
end

udpBroker=UdpBroker("udBroker")
udpBroker.infoEnable=true

# Controller-B:  prepare a rule
tasmota.cmd("rule1 ON udpBroker#SM.simple do var1 %value% ENDON"); 
tasmota.cmd("rule1 1")

# Controller-B:  subscribe the topic of interst
tasmota.cmd("udpsub SM.simple")


#### Controller-A: publish the value

tasmota.cmd("udppub SM.simple 22.23")


#### check the result


    # ...MQT: stat/tasmota_testing/RESULT = {"Var1":"22.23"}


# ----------------------------


if global.udpBroker
  global.udpBroker.deinit()
  global.udpBroker=nil
end
		
udpBroker=UdpBroker("udBroker")
udpBroker.infoEnable=true

# Tasmota commands
tasmota.cmd("udpsub SM.PowerAV")
tasmota.cmd("udpunsub SM.PowerAV")
tasmota.cmd("udppub SM.PowerAVx 123")

# Berry
udpBroker.subscribe("SM.PowerAV",def(topic,payload) print("done ",topic) end)
udpBroker.unsubscribe("SM.PowerAV")
udpBroker.publish("SM.PowerAVx",456)


# -----



topic="SM.PowerAV"
payload=1.23

dyn = DynClass()
dyn.xmap[topic] = payload
dyn[topic] = payload
print(dyn.toJson())


topic="SM.PowerAV"
payload=1.23
nested = DynClass()
nested[topic]=payload

dyn = DynClass()
dyn.udpBroker = nested.xmap
print(dyn.toJson())


# -------

tasmota.cmd("rule1 ON udpBroker#SM.enhanced#Power do var1 1234 ENDON"); 
tasmota.cmd("rule1 ON udpBroker#SM.enhanced#Power do var1 %value% ENDON"); 
tasmota.cmd("rule1 1")

if global.udpBroker
  global.udpBroker.deinit()
  global.udpBroker=nil
end

udpBroker=UdpBroker("udBroker")
udpBroker.infoEnable=true

udpBroker.triggerEvent("SM.enhanced",'{"Power":1000,"Voltage":220}')

tasmota.cmd('udpsub SM.enhanced')
tasmota.cmd('udppub SM.enhanced  {"Power":1000,"Voltage":220}')



