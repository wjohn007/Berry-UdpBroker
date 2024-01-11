#-----------------------------------
 dynamic class
     Dynamically add members to a class at runtime.
     Refer 'virtual members' https://berry.readthedocs.io/en/latest/source/en/Chapter-8.html#module-undefined   
------------------------------------#
import string
import json

class DynClass

    var xmap

    def setmember(name, value)
        self.xmap[name] = value
    end

    def member(name)
        if self.xmap.contains(name)
            return self.xmap[name]
        else
            import undefined
            return undefined
        end
    end

    # return members as json-string
    def toJson()
        return json.dump(self.xmap)
    end

    # load new members from json-string
    def loadJson(jsonString)
        var data = json.load(jsonString)
        if classname(data)=='map'
          self.xmap = data
        end
    end
    
    def init()
        self.xmap = {}
    end
end

#-----------------------------------
this class implements the XAction class
    XAction allows to bind multiple callbacks using th '+' operator
    var action=XAction()
    action += myCallback1  
------------------------------------#
class XAction 

    var callback
    var onAction

    # define a new operator '+'
    def +(other)
        if type(other)!="function"
            raise 'type_error','expect a function'
        end

        # if already defined
        if self.callback.find(other)!=nil
            return self
        end

        # print ("other:",str(other))
        self.callback.push(other)
        return self
    end

    def tostring()
        return self.callback.tostring()
    end

    def doAction()
      ## for xx:self.callback xx() end
      if !self.onAction
         return
      end

      for xx:self.callback 
          self.onAction(self,xx)
       end
    end

    def clear()
        self.callback = []
    end

    def count()
        return self.callback.size()
    end
 
    def init()
        self.callback = []
    end   
end