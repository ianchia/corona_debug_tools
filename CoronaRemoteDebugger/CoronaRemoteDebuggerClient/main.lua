--[[

Take a string of a global variable name
and dump all the contents in a similar fashion
to PHP's print_r()

Return the entire formatted string.

Note that the Carriage return character is defined instead of a LF 0x0A.
LuaSocket uses in the "l*" mode uses the LF \n character as a terminator,
which would result in an endless loop of echoing messages back and forth.

--]]


function dump ( string_of_global_variable_name ) 
	
	local CR = '\r'; -- yes, this is a CR 0x0D. Don't try LF 0x0A \n. There will be tears.
	
	-- use the string of the variable name to find the pointer to the global var
	local t = _G[string_of_global_variable_name];
	
	-- header and footer of output, customize to your liking
	local buffer_header = CR .. "_______________"
			.. "Contents of: "..string_of_global_variable_name .. "_______________" .. CR;
	local buffer_footer = "_____________________________" .. CR;
	
	local buffer = "";
	local print_r_cache={}
    local function sub_print_r(t,indent)
            if (print_r_cache[tostring(t)]) then
                    buffer = buffer .. (indent.."*"..tostring(t)) .. CR;
            else
                    print_r_cache[tostring(t)]=true
                    if (type(t)=="table") then
                            for pos,val in pairs(t) do
                                    if (type(val)=="table") then
                                            buffer = buffer .. (indent.."["..pos.."] => "..tostring(t).." {") .. CR;
                                            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                                            buffer = buffer .. (indent..string.rep(" ",string.len(pos)+6).."}") .. CR;
                                    elseif (type(val)=="string") then
                                            buffer = buffer .. (indent.."["..pos..'] => "'..val..'"') .. CR;
                                    else
                                            buffer = buffer .. (indent.."["..pos.."] => "..tostring(val)) .. CR;
                                    end
                            end
                    else
                            buffer = buffer .. (indent..tostring(t)) .. CR;
                    end
            end
    end
    if (type(t)=="table") then
            buffer = buffer .. (tostring(t).." {") .. CR;
            sub_print_r(t,"  ")
            buffer = buffer .. ("}") .. CR;
    else
            sub_print_r(t,"Lua type: "..type(t)..CR);
    end
    
    -- add header & footer to buffered output
    buffer = buffer_header
		    .. buffer 
		    .. buffer_footer;
		     
    return buffer;
        
end

--Ê///////////////////////////////////////////////////////////////////////////////////////////////////
--[[

unit test sample data

--]]

mystring = "the Quick brown fox.";
mynumber = 3.141592654;
myfunction = function()
	-- this is a stub function
end
mynil = nil;
mybool_true = true;
mybool_false = false;

data_manager = {};
data_manager.customer_name="";
data_manager.location="";
data_manager.machine_number="";
data_manager.machine_start_hours="";
data_manager.product_name="";
data_manager.product_supplier="";
data_manager.docket_number="";
data_manager.spread_rate="";
data_manager.total_tonnes="";
data_manager.who_carted="";
data_manager.driver="";
data_manager.actual_tonnes="";
data_manager.prefs_index = 0;
data_manager.job_status = 0;

mytable = { 
         id="prefs_Obj"
         ,username=""
         ,password="" 
         ,start_job=os.date( "*t" ) 
         ,customer_name=tostring(data_manager.customer_name)
         ,location=tostring(data_manager.location)
         
         ,machine_number=tostring(data_manager.machine_number)
         ,machine_start_hours=tostring(data_manager.machine_start_hours)
         
         ,product_name=tostring(data_manager.product_name)
         ,supplier=tostring(data_manager.product_supplier)
         ,docket_number=tostring(data_manager.docket_number)
         
         ,spread_rate=tostring(data_manager.spread_rate)
         ,total_tonnes=tostring(data_manager.total_tonnes)
         
         ,who_carted=tostring(data_manager.who_carted)
         ,driver=tostring(data_manager.driver)
         ,job_status="0"
         ,stub_function = myfunction
}
mytable.start_job.nested_table = os.date( "*t" )
mytable.start_job.nested_function = myfunction


--Ê///////////////////////////////////////////////////////////////////////////////////////////////////

timer_interval_ms = 5000;

connectObject = {};
connectObject.socket = require( "socket" )


function beep()
	
end

com_beingprudence_debug = {};

com_beingprudence_debug.temp1 = 0;

-- push message to socket server
com_beingprudence_debug.push_msg = function(msg)
	connectObject.client:send(msg);
end

-- parse server msg
com_beingprudence_debug.parse_server_msg = function(msg)

	--[[
	print "/////////////////////////////////////////////////////////////////////////              "
	print ("dumping variable name: ".. string.sub(msg,6,string.len(msg)) );
	print "/////////////////////////////////////////////////////////////////////////              "
	--]]
	
	local global_var_stringname = string.sub(msg,6,string.len(msg));
	com_beingprudence_debug.push_msg( dump(global_var_stringname) );

end


local function onEnterFrame(event)

	-- the "*l" mode uses a 0x0A byte as the socket stream terminator
	-- it parses only lines WITHOUT CR & LF characters. All CR chars are ignored.
	local buffer = connectObject.client:receive("*l") 
	
	if buffer then 
		if (buffer == "beep") then
	        system.vibrate();
	        
	    elseif (buffer == "restart") then
	    	os.exit();

	    elseif (string.sub(buffer,1,5) == "dump:") then
	        com_beingprudence_debug.parse_server_msg(buffer);
	    end        
	end
end


connectObject.client = connectObject.socket.tcp()
connectObject.client:connect("192.168.1.3","8080");
connectObject.client:settimeout( 0 );
connectObject.client:setoption('keepalive',true);
Runtime:addEventListener( "enterFrame", onEnterFrame )


------------------------------------------------------------------------------------------
--
-- this is just some debug stuff so we can see a clock being updated on screen and
-- the corresponding timestamp data being pushed from Corona (simulator & desktop)
-- to the Remote Debugger
--
--
local clock = display.newGroup()
-- Set the rotation point to the center of the screen
clock:setReferencePoint( display.CenterReferencePoint )

-- Create dynamic textfields
-- Note: these are iOS/MacOS fonts. If building for Android, choose available system fonts, 
-- or use native.systemFont / native.systemFontBold

local hourField = display.newText( "", 0, 0, native.systemFontBold, 180 )
hourField:setTextColor( 255, 255, 255, 70 )
clock:insert( hourField, true )
hourField.x = 100; hourField.y = 90; hourField.rotation = -15

local minuteField = display.newText( "", 0, 0, native.systemFontBold, 180 )
minuteField:setTextColor( 255, 255, 255, 70 )
clock:insert( minuteField, true )
minuteField.x = 100; minuteField.y = 240; minuteField.rotation = -15

local secondField = display.newText( "", 0, 0, native.systemFontBold, 180 )
secondField:setTextColor( 255, 255, 255, 70 )
clock:insert( secondField, true )
secondField.x = 100; secondField.y = 390; secondField.rotation = -15

-- Create captions
local hourLabel = display.newText( "hours ", 0, 0, native.systemFont, 40 )
hourLabel:setTextColor( 131, 255, 131, 255 )
clock:insert( hourLabel, true )
hourLabel.x = 220; hourLabel.y = 100

local minuteLabel = display.newText( "minutes ", 0, 0, native.systemFont, 40 )
minuteLabel:setTextColor( 131, 255, 131, 255 )
clock:insert( minuteLabel, true )
minuteLabel.x = 220; minuteLabel.y = 250

local secondLabel = display.newText( "seconds ", 0, 0, native.systemFont, 40 )
secondLabel:setTextColor( 131, 255, 131, 255 )
clock:insert( secondLabel, true )
secondLabel.x = 210; secondLabel.y = 400


local function updateTime()
	local time = os.date("*t")
	
	local hourText = time.hour
	if (hourText < 10) then hourText = "0" .. hourText end
	hourField.text = hourText
	
	local minuteText = time.min
	if (minuteText < 10) then minuteText = "0" .. minuteText end
	minuteField.text = minuteText
	
	local secondText = time.sec
	if (secondText < 10) then secondText = "0" .. secondText end
	secondField.text = secondText
	
	--[[
	this is to update temp data as a background "thread"
	--]]
	com_beingprudence_debug.temp1 = com_beingprudence_debug.temp1 + 1;
	
	local debugmsg = 
		"Corona counter: "
		.. com_beingprudence_debug.temp1 
		.. " and timestamp is "
		..hourText..":"
		..minuteText..":"
		..secondText..'\0';

	-- push the debug message to the Remote Debugger
	com_beingprudence_debug.push_msg (debugmsg);

end

updateTime() -- run once on startup, so correct time displays immediately

-- Update the clock once per timer_interval_ms
local clockTimer = timer.performWithDelay( timer_interval_ms, updateTime, -1 )

