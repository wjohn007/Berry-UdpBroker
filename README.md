# Berry-UdpBroker
A lightweight messaging solution for Tasmota devices.


## Mission

This application implements a message broker functionality using Multicast-UDP.


## Motivation

There are scenarios in which one or more of the following conditions apply:

* There should be as few technical dependencies as possible
* No MQTT-Broker is available
* MQTT messages are used for monitoring only, not for prodcutive mechanisms
* MQTT-Broker is located in the Cloud and not useful for productive local usage


## How it works

- the application opens a Multicast-UDP-Port on IP="224.3.0.1" and PORT=12233.
- now it is able to receive all corresponding broadcast messages
- if there exists a 'subscriber' the message is forwarded 
- the controller can send a broadcast message using Berry or Tasmota-Commands


## Available Commands

Command                       | Example               | Comment
---                           |---                    |---
udppub \<topic\> \<payload\>  |udppub SM.simple 22.23 | publish value '22.23' with topic 'SM.simple'
udpsub \<topic\>              |udpsub SM.simple       | subscribe for topic 'SM.simple'
udpunsub \<topic\>            |udpunsub SM.simple     |  unsubscribe topic 'SM.simple'

*Remarks*

As a convention: The rule-trigger must begin with 'udpBroker#...'


You can subscribe the same topic for using 'Commands' by 'udpsub'  and using 'Berry' by 'udpBroker.subscribe(\<topic\>).

Both subscriptions exist independently of each other.
This also applies to unsubscribing to a topic.


-------------------------


### A simple 'rule' example

Controller-A publishes a value via udpBroker with topic 'SM.simple'.<br>
Controller-B ist interested on that value and wants to store it in the variable 'var1'.


#### Controller-B:  prepare a rule

The topic of the message is 'SM.simple'. 

To distinguish it from other namespaces the prefix 'udpBroker' is always required within a rule definition.

```
rule1 
  ON udpBroker#SM.simple do var1 %value% ENDON 	
      
rule1 1
```

#### Controller-B:  subscribe the the topic of interst

```
udpsub SM.simple 
```

#### Controller-A: publish the value

```
udppub SM.simple  22.23
```

#### Check the result

Check the output of the Console.

```
..MQT: stat/tasmota_testing/RESULT = {"Var1":"22.23"}
```


--------------------


### An enhanced 'rule' example

Controller-A publishes a json-payload via udpBroker with topic 'SM.enhanced'.

```json
{"Power":1000,"Voltage":220}
```

Controller-B ist interested on Property 'Voltage' and wants to store it in the variable 'var1'.

#### Controller-B:  prepare a rule

Accessing elements of the json-payload is compliant with standard Tasmota practices.

```
rule1 
  ON udpBroker#SM.enhanced#Voltage do var1 %value% ENDON 

rule1 1
```

#### Controller-B:  subscribe the the topic of interst

```
udpsub SM.enhanced
```

#### Controller-A: publish the value


```
udppub SM.enhanced  {"Power:1000,"Voltage":220} 
```


#### Check the result

Check the output of the Console.

```
..MQT: stat/tasmota_testing/RESULT = {"Var1":"220"}
```



## How to install

Upload following files to the Controller

- udpBroker.tapp
- udpBroker01.be   (is executed before components are created)
- udpBroker02.be   (is after components are created)
  
After restart of the controller and you should see following picture of the file-system.

![Alt text](images/filesystem.png)


## How to deal with Berry

Take a look to file [udpBroker02.be](udpBroker02.be).


## Under the hood

The class UdpBroker is designed as a Tasmota-driver.

```be
    tasmota.add_driver(self) 
```
### Start/Stop of the broker

UdpBroker is started/stopped synchronize with Wifi-connection.

```be
    tasmota.add_rule("Wifi#Connected", / -> self.start()) 
    tasmota.add_rule("Wifi#Disconnected", / -> self.stop()) 
```

### Load

Note that each broadcast message is processed by the controller.
Too many messages can overwhelm the controller.

### Enable Logging

The berry-variable 'udpBroker' is global.

Use following statement in the Berry-Console to obtain more log-information.

    udpBroker.infoEnable=true


### No wildcard support for subscribing

Wildcard mechanisms like MQTT are omitted in favor of simplicity.