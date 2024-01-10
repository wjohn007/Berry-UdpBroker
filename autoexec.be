# autoexec.be is automatically loaded at startup

import string

appName="udpBroker"

# tasmota.wd is only valid at startup step
tasmotawd = tasmota.wd

# needed to import modules located in tapp file
def push_path()
    import sys
    var p = tasmotawd
    var path = sys.path()
    if path.find(p) == nil
      path.push(p)
    end
  end

def xload(name,useRoot)
    var result=false

    if useRoot
      result = load(name)
    else
      result = load(tasmotawd + name)
    end

    print("loaded",name," with result:"+str(result))   
end


print("autoexec - start with app-file:"+tasmotawd)

# change to path where tapp files are located
push_path()

# no import your one module which is part of the tapp-file
# this is the first time loaded in cache, so following 'import' commands can work
import tool

# define types
xload("git.be")
xload("Libs.be")
xload("UdpBroker.be")


# define global variables
xload("configure01.be")

# loader user's input and adjustings 
xload(appName+"01.be",true)

# shortcut for test device
if tasmota.cmd("DeviceName")["DeviceName"] == "Tasmota Testing"
  return
end

xload("configure02.be")

# settings after initializations
xload(appName+"02.be",true)


