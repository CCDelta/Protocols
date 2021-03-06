--[[
	Client CLI
]]--

local path, path2 = ...

dofile = function(path,...)
	local f, err = loadfile(path)
	if not f then
		print(err)
	end
	setfenv(f,_G)
	return f(...)
end

local Delta = dofile(path.."/init.lua", path)
local FTP = dofile(path2.."/FTP/Client.lua", Delta)

print("CLI FTP Client by Creator")

term.write("Input IP: ")
local IP = read(nil, {"192.168."})

term.write("Input dest port: ")
local dest_port = tonumber(read())

term.write("Input send port: ")
local send_port = tonumber(read())

term.write("Input modem side: ")
local side = read(nil, {
	"right",
	"left",
	"back",
	"front",
	"top",
	"bottom"
})
local modem = Delta.modem(side)
modem.connect()

local connection = FTP(modem, IP, dest_port, send_port)

term.write("Input username: ")
local user = read()

term.write("Input password: ")
local pass = read()

connection.connect(user, pass)