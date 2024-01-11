# play with functions of udp-Broker

# ----------------- test udpsub
#-  define rule for testing command udpsub
    
rule1 
ON event#SM.PowerAV do var1 %value% ENDON 
rule1 1 


udpsub SM.PowerAV

event SM.PowerAV 123
-#

if global.bc
  bc.deinit()
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






