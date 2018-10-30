#notes

run vagrant up
if asked, pick the ethernet connection for bridged interface

Note the partitioner entry for fx.ARCS
bootp():/30-Overlays1/stand/fx.ARCS

Connect serial cable.
Start screen on linux

# prom
printenv
Note "eaddr=08:00:69:0e:af:65"

ConsoleOut=video()
ConsoleIn=keyboard()
console=g

# Modify settings
setenv ConsoleOut serial(0)
setenv changed to ConsoleIn serial(0)
setenv changed to console d

