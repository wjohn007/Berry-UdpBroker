
# creation 
bc=UdpBroker("udBroker")
bc.infoEnable=true
assert(bc.paketCounter==0,"create.1")
assert(bc.tickCounter==0,"create.2")
assert(size(bc.topics)==0,"create.3")
assert(bc.name=="udBroker","create.4")
assert(bc.udp!=nil,"create.5")

assert(bc.onStarted==nil,"create.6")
assert(bc.onStopped==nil,"create.7")

# ---- publish
gtopic = "topic.01"
gpayload="test-string"
erg = bc.publish(gtopic,gpayload)
assert(erg,"publish.1")

erg = bc.publish("",gpayload)
assert(!erg,"publish.2")

erg = bc.publish(gtopic)
assert(!erg,"publish.3")


# ---- subscribe
ttopic=nil
tpayload=nil
def myCallback(topic,payload)
    ttopic = topic
    tpayload = payload
end

erg = bc.subscribe(gtopic,myCallback)
assert(erg,"subscribe.1")
assert(size(bc.topics)==1,"subscribe.2")

## once again the same
erg = bc.subscribe(gtopic,myCallback)
assert(!erg,"subscribe.3")

## callback not a function
erg = bc.subscribe(gtopic,erg)
assert(!erg,"subscribe.4")
assert(string.find(bc.lastWarnInfo,"not a function")>=0,"subscribe.5")

# simulate publish and check callback
assert(ttopic==nil,"broker.1")
assert(tpayload==nil,"broker.2")

bc.process(gtopic,gpayload)
assert(ttopic==gtopic,"broker.3")
assert(tpayload==gpayload,"broker.4")

# ---- unsubscribe
bc.unsubscribe(gtopic)
assert(size(bc.topics)==0,"unsubscribe.1")

# ----- house keeping

bc.deinit()
bc=nil