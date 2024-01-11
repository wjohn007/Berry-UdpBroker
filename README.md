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
udppub \<topic\> \<payload\>  |udppub SM.PowerAV 22.23 | publish value '22.23' with topic 'SM.PowerAV'
udpsub \<topic\>              |udpsub SM.PowerAV      | subscribe for topic 'SM.PowerAV', the reception  triggers 'event \<topic\>=\<payload\>'
udpunsub \<topic\>            |udpunsub SM.PowerAV    | unsubscribe topic 'SM.PowerAV'

*Remarks*

You can subscribe the same topic for using 'Commands' by 'udpsub'  and using 'Berry' by 'udpBroker.subscribe(\<topic\>).

Both subscriptions exist independently of each other.
This also applies to unsubscribing to a topic.

### A 'rule' example

This rule on Controller-A writes the payload of received UDP-message of topic 'SM.PowerAV' to 'var1'
```sh
rule1 
  ON event#SM.PowerAV do var1 %value% ENDON 	      
rule1 1
```

Perform this on Controller-B and send an udp-broadcast message.
```sh
udpsub SM.PowerAV 123  
```


## How to install

Upload following files to the Controller

- udpBroker.tapp
- udpBroker01.be   (is executed before components are created)
- udpBroker02.be   (is after components are created)
  
After restart of the controller and you should see following picture of the file-system.

![Alt text](images/filesystem.png)


## How to test

  We need 2 controllers (Controller-A and Controller-B) with installed udp-Broker  and following setting.
  “InfoEnable” makes the udpBroker more talkative.
  
```java
     udpBroker.infoEnable=true
 ```

  Perform following command in 'Console' of Controller-A:

```sh
  udppub global/test hello world
 ```

  You will receive on controller-B

    .... INFO broker.every_poll - got valid message:{"topic":"global/test","payload":"hello world"}

  It is also possible to perform this from berry-console using the publish-method.


```java
  udpBroker.publish("global/test","hello world")
```

Take a look to file [udpBroker02.be](udpBroker02.be) and find how to subscribe for a topic.

