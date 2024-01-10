#-----------------------------------
The Tool module 'tool'
impelments common functions
------------------------------------#
import json
import string

tool = module("tool")

tool.init = def (m)

        class Tool
            var lastIsNumberResult
            var lastLogInfo
            var lastWarnInfo
            var lastLogProc
            var infoEnable

            def init()
                self.infoEnable = false
            end

            def info(proc,info)
                self.lastLogProc = proc
                self.lastLogInfo = info
                if self.infoEnable print("INFO "+"Tool."+proc+" - "+info) end
            end

            def warn(proc,info)
                self.lastLogProc = proc
                self.lastWarnInfo = info
                print("WARN "+"Tool."+proc+" - "+info)
            end

            #-
            function      checks whether value can be converted into a bool
            return        true, if value is convertible into bool otherwise false 
            -#
            def isBool(value)
                return type(value)=='bool'
            end

            #-
            function      checks whether value can be converted into a number
            return        true, if value is convertible into number otherwise false 
            -#
            def isNumber(value)
                self.lastIsNumberResult = json.load(str(value))
                var xtype = type(self.lastIsNumberResult)
                var result = xtype == "int" || xtype == "real"
                return result
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
            function      checks whether property defined in 'propName' exists in map (obj)
            return        obj, if property was found otherwise nil 
            -#
            def mapCheckProp(obj,propName)
                if classname(obj) != "map"
                    self.warn("mapCheckProp","no map")
                    return nil
                end
            
                if !obj.contains(propName)
                    return nil
                end
            
                return obj
            end

            #-
            function      tries to extract the the value of key 'propname' from the map 'obj' as bool. 
            return        property-value as bool, if checks are, otherwise nil 
            -#
            def mapGetBoolean(obj,propName)

                if self.mapCheckProp(obj,propName) == nil
                    return nil
                end
            
                if type(obj[propName]) != "bool"
                    self.warn("mapGetBoolean","wrong type")
                    return nil
                end
            
                return obj[propName]
            end
            
            #-
            function      tries to extract the the value of key 'propname' from the map 'obj' as number. 
            return        property-value as number, if checks are ok, otherwise nil 
            -#
            def mapGetNumber(obj,propName)

                if self.mapCheckProp(obj,propName) == nil
                    return nil
                end
            
                var xvalue = obj[propName]
                if  !self.isNumber(xvalue)
                    self.warn("mapGetNumber","wrong type")
                    return nil
                end
            
                return self.lastIsNumberResult
            end    

            
            #-
            function      tries to extract the the value of key 'propname' from the map 'obj' as string. 
            return        property-value as string, if checks are ok, otherwise nil 
            -#
            def mapGetString(obj,propName)

                if self.mapCheckProp(obj,propName) == nil
                    return nil
                end
            
                var xtype = type(obj[propName]) 
                if  xtype != "string"
                    self.warn("mapGetString","wrong type")
                    return nil
                end
            
                return obj[propName]
            
            end

        end

    # return a single instance for this class
    return Tool()
end

# return the module as the output of import, which is eventually replaced by the return value of 'init()'
return tool 



