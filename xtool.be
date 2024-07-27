#-----------------------------------
The static class  implements common functions
------------------------------------#

#@ solidify:xtool
class xtool
    static lastJsonResult 
    static lastIsBoolResult
    static lastLogInfo
    static lastWarnInfo

    def info(proc,info)
        xtool.lastLogProc = proc
        xtool.lastLogInfo = info
        if xtool.infoEnable print("INFO xtool."..proc.." - "..info) end
    end    

    def warn(proc,info)
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
    def isBool(value)
        import json

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
 
end