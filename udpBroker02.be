# --- this script is processed, after components are created

# our test topic
topicForUdpTest="global/test"


# define the handler for the topic of interest
def UdpMessageHandler(topic,payload)
  print("UdpMessageHandler received topic:",topic," payload:",payload)
end

# ====== create the udp-broker

udpBroker = UdpBroker("broker")

# set this for more verbose logging
# udpBroker.infoEnable=true

# preset value, can be changed
# udpBroker.PORT = 12233

# preset value, can be changed
# udpBroker.IP = "224.3.0.1"

# unsubscribe previous subscriptions
udpBroker.unsubscribe(topicForUdpTest)

# subscribe to topic and register callback-handler
udpBroker.subscribe(topicForUdpTest,UdpMessageHandler)

# install a callback for on-started, on-stopped if useful
udpBroker.onStarted = def(obj) print("udp broker has started") end

udpBroker.onStopped = def(obj) print("udp broker has stopped") end
