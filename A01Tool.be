#-----------------------------------
The static class  implements common functions
------------------------------------#

#@ solidify:xtool
class xtool
    static lastJsonResult 
    static lastIsBoolResult
    static lastIsNumberResult
    static lastLogInfo
    static lastWarnInfo
    static rebootWeeklyActivated

    static def info(proc,info)
        xtool.lastLogProc = proc
        xtool.lastLogInfo = info
        if xtool.infoEnable print("INFO xtool."..proc.." - "..info) end
    end    

    static  def warn(proc,info)
        xtool.lastLogProc = proc
        xtool.lastWarnInfo = info
        print("WARN xtool."..proc.." - "..info)
    end

    #-
    function      checks whether value can be converted into a valid json
    return        true, if value is a valid json, false otherwise 
    -#
    static def isJson(value)
        
        import json
        xtool.lastJsonResult = json.load(value)
        if classname(xtool.lastJsonResult)=='map'
            return true
        else
            return false
        end 
    end

    #-
        function      checks whether value can be converted to a bool value
        returns       true, if value is convertible to a bool, false otherwise 
    -#
    static def isBool(value)
        import json
        import string

        xtool.lastIsBoolResult=nil

        if value==nil return false end

        var ss = string.format('{"value": %s}',string.tolower(str(value)))
        var data = json.load(ss)
    
        if data==nil return false end
    
        var xval = data["value"]
    
        if type(xval)  == 'bool'
            xtool.lastIsBoolResult =xval
            return true
        else
            return false
        end
    end   

    #-
    function      checks whether value can be converted to a number value
    return        true, if value is convertible to a number, false otherwise
    -#
    static def isNumber(value)
        import json
        xtool.lastIsNumberResult = json.load(str(value))
        var xtype = type(xtool.lastIsNumberResult)
        var result = xtype == "int" || xtype == "real"
        return result
    end

    #  calculates the dewpoint
    static def calcDewpoint(temp,hum)
        import math

        var rf1 = 0.01 * hum
        var k1 = 0.124688
        var k2 = 109.8
        var s = math.pow(rf1,k1)
        var result = (s * (k2 + temp)) - k2
        return result
    end   

    # reboots at Sa at 09:00
    static def rebootWeekly()
        var cproc="rebootWeekly"
        xtool.info(cproc,"will reboot weekly")

        # seconds minute hour day   month Weekday
        # 0-59    0-59   0-23 1-30  1-12  0 (So)-6(Sa)
        tasmota.remove_cron('weeklyRestart')

        tasmota.add_cron("0 0 9 * * 6",
            def()
            tasmota.cmd("restart 1")
            end
            ,'weeklyRestart') 
            xtool.rebootWeeklyActivated=true
    end

end