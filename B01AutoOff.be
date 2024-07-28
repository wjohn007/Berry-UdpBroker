#-----------------------------------
AutoOff

- as long as a message is process via processMsg() state gets true for delayInSeconds
- if  no trigger between period of delayInSeconds state gets false  false
- if state changes onStateChanged(obj,state) is called when defined

var autoOff = AutoOff("mySwitch")
autoOff.delayInSeconds = 120
autoOff.trigger()

print(autoOff.state)   # true,false

------------------------------------#

import string

#@ solidify:AutoOff
class AutoOff 

    var lastLogInfo
    var lastWarnInfo
    var lastLogProc
    var infoEnable
    var name

    var delayInSeconds
    var autoOffCounter

    var state   # boolean, current output state

    var onStateChanged    #  (self,value)

    # log with level INFO
    def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "..self.name.."."..proc.." - "..info) end
    end

    # log with level WARN
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "..self.name.."."..proc.." - "..info)
    end

    # performs the onStateChanged callback
    def doStateChange(callerName)
        var cproc="doStateChange"

        var ss = "triggered by:"..callerName.." state:"..str(self.state)
        if self.onStateChanged != nil
            ss = ss + " (callback)"
            self.onStateChanged(self,self.state)
        end  
        if self.infoEnable self.info(cproc,ss) end
    end

    # process incomming value/message
    def trigger()
        var cproc="trigger"

        # here transitions are handled
        var oldState = self.state
        self.state = true
        var changed = oldState != self.state

        # rising edge
        if self.state 
            self.autoOffCounter = self.delayInSeconds
        end

        if changed 
            self.doStateChange(cproc)
        end
    end
 
    # called every second or after processing of value
    def every_second()
        var cproc="every_second"

        if self.autoOffCounter>0 
            self.autoOffCounter = self.autoOffCounter-1

            # auto off , only if current state is true
            if self.autoOffCounter==0 
                # self.info(cproc,"perform auto off")
                self.state=false
                self.doStateChange(cproc)
            end
        end
    end

    # resets the state soft, with callback
    def resetSoft()
        var cproc ="resetSoft"

        self.autoOffCounter = 0
        var oldState = self.state
        self.state = false
        var changed = oldState != self.state
        
        if changed
            self.doStateChange(cproc)
        end
        self.info(cproc,"done")
    end

    # reset the state hard, without callback
    def resetHard()
        var cproc="resetHard"
        self.state = false
        self.autoOffCounter = 0
        self.info(cproc,"done")
    end

    # constructor	
    def init(name)
        var cproc="init"

        if name==nil name="AutoOff" end
        self.name=name

        self.delayInSeconds = 60
        self.resetHard()

        self.info(cproc,"done")

        # uses tasmotas callback for second
        tasmota.add_driver(self)
        self.infoEnable = false

    end

    def tostring()
        return self.name+" state:"..str(self.state).." counter:"..str(self.autoOffCounter)
    end

    # destructor
    def deinit()
        var cproc="init"
        tasmota.remove_driver(self)
        self.info(cproc,"done")
    end

end
