--[[
	Delta Networking FTP Server.
]]--

local path = ...

local dofile = function(path,...)
	local f, err = loadfile(path)
	if not f then
		print(err)
	end
	setfenv(f,_G)
	return f(...)
end

local Delta = dofile(path.."/init.lua", path)
local Thread = Delta.lib.Thread
local DH = Delta.lib.DH
local SHA = Delta.lib.SHA256
local AES = Delta.lib.AES
local helper = {}
local processes = {}
local connections = {}
local users = {}
--[[
users = {
	name = {
		[1] = pass_sha
		[2] = permission
	}
}
]]
local side, port, connectionPort

local permissions = {
	list = "admin",
	exists = "admin",
	isDir = "admin",
	isReadOnly = "admin",
	getSize = "admin",
	getFreeSpace = "admin",
	makeDir = "admin",
	move = "admin",
	copy = "admin",
	delete = "admin",
	combine = "admin",
	open = "admin",
	find = "admin",
	getDir = "admin",
}
local permValues = {
	["admin"] = true,
	["user"] = true,
	["false"] = true,
}

local function loadSettings()
	if not fs.exists(".ftp/permissions") then
		print("No permission file found, everything set to maximum security!")
		for i,v in pairs(permissions) do
			permissions[i] = "admin"
		end
	else
		local file = fs.open(".ftp/permissions", "r")
		local data = file.readAll()
		file.close()
		local index, value
		for token in data:gmatch("[^\n]+") do
			index, value = token:match("([^:]+):([^:]+)")
			permissions[index] = permValues[value] and value or "admin"
		end
	end
	if fs.exists(".ftp/side") then
		local file = fs.open(".ftp/side", "r")
		side = file.readAll()
		file.close()
		print("Side")
		print(side)
	else
		print("Side")
		for i,v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then
				side = v
				print(side)
			end
		end
		if side == nil then
			error("No modem found!")
		end
	end
	if fs.exists(".ftp/ports") then
		local file = fs.open(".ftp/side", "r")
		local portsData = file.readAll()
		file.close()
		port, connectionPort = portsData:match("([^\n]+)[\n]([^\n]+)")
		port = tonumber(port) or 20
		print("Port: ", port)
		connectionPort = tonumber(connectionPort) or 21
		print("Got ports")
	else
		port = 20
		connectionPort = 21
	end
end

loadSettings()

local function loadUsers()
	if fs.exists(".ftp/users") then
		local index, permission, pass
		local file = fs.open(".ftp/users","r")
		local data = file.readAll()
		file.close()
		for token in data:gmatch("[^\n]+") do
			index, permission, pass = nil, nil, nil
			index, permission, pass = token:match("([^:]+):([^:]+):([^:]+)")
			if not users[index] then
				users[index] = {
					[1] = pass,
					[2] = permission
				}
			end
		end
	else
		error("No user file found.")
	end
end

loadUsers()

print("Getting modem")
local modem = Delta.modem(side)
print("IP: ", modem.connect(5))

local function setUpConnection(...)
	local id, IP, dest_port = ...
	local key = SHA(tostring(DH(modem, IP, dest_port, connectionPort)))
	local packet
	repeat
		packet = modem.receive(true)
	until packet and type(packet) == "table" and packet[1] == modem.IP and packet[2] == IP and packet[3] == port
		and packet[4] == dest_port
	local decrypted_pass = AES.decryptBytes(key,packet[5][2])
	local decrypted_user = AES.decryptBytes(key,packet[5][1])
	local sha_pass = SHA(decrypted_pass)
	if users[decrypted_user] and users[decrypted_user][1] == sha_pass then
		connections[IP] = {
			dest_port = {
				[1] = decrypted_user,
				[2] = sha_pass
			}
		}
		print("Sucess")
	else
		print("Fail")
	end
	os.queueEvent("FTP_Server_Event")
	os.pullEventRaw("FTP_Server_Event")
	helper[id] = "done"
end

local actions = {
	connect = function(ip, client_port, msg)
		print("IP is ",ip)
		local notFound = true
		local index = 0
		while notFound do -- find next free index
			if not helper[index] then
				notFound = false
			else
				index = index + 1
			end
		end
		helper[index] = os.clock()+30
		print("Index is ", index)
		modem.send(ip, client_port, connectionPort, {
			[1] = "connection_port"
		})
		print("Sent message.",index)
		processes[index] = 
		Thread.new(
			setUpConnection, index, ip, client_port)
		print("Added function.")
	end
}

print("Loaded things") -- Change
--[[IP_PACKET
	{
		[1] = Destination IP
		[2] = Sender IP
		[3] = Destination Port
		[4] = Sender Port
		[5] = Message
		[6] = TTL
	}]]

local function main()
	local event = {}
	local action, user, pass, arguments
	while true do
		event, dummy = modem.receive(true)
		--[[if event then
			print(event[1])
			print(event[2])
			print(event[3], event[3] == port, type(port), type(event[3]), port)
			print(event[4])
			print(event[5])
		end]]
		if event and event[3] == port and type(event[5]) == "table" then
			print("Match 1")
			action = event[5][1]
			if actions[action] then
				print("Does exist")
				actions[action](event[2], event[4], event[5])
			else
				print(action)
				print("No such action")
			end
		end
	end
end

local function clean()
	local time = os.clock()
	for i, v in pairs(helper) do
		if (type(i) == "number" and type(v) == "number"and v < time) or i == "done" then
			processes[i] = nil
			print("Niled index ", v)
		end
	end
end

print("Loaded more stuff")

processes.main = Thread.new(main)

Thread.run(processes, clean)


