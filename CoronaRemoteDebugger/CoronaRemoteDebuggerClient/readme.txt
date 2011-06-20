1. Start the OS X Server (default is port 8080) - make sure port 8080 is open on your firewall.
2. Start the Corona Lua client. You can run it on the simulator or the device.
3. Type in commands from the desktop debugger. Valid commands so far are:

beep
-- makes the device vibrate (or a beep from the desktop)

dump:stringNameOfGlobalVariable

-- eg. these are all valid unit test variable defined in the test file
dump:mytable
dump:mystring
dump:mynumber
dump:system

-- Corona will dump the global variable using a print_r type format back into the remote debugger's window.