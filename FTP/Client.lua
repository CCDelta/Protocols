--[[
	Delta Network FTP Client
]]--f

local Delta = ...
local AES = Delta.lib.AES
local SHA = Delta.lib.SHA256
local DH = Delta.lib.DH

local FTP = function(modem, ip, dest_port, send_port)
	assert(type(modem) == "table", "Please pass a modem!")
	assert(type(ip) == "string", "Please pass an IP!")
	assert(type(dest_port) == "number", "Please pass a dest_port!")
	assert(type(send_port) == "number", "Please pass a send_port!")
	local key, enc_pass, user, server_connection_port, enc_user

	local self = {}

	self.sendCommand = function (msg)
		modem.send(ip, dest_port, send_port, msg)
	end

	self.connect = function(user, pass)
		self.sendCommand({
			[1] = "connect"
		})
		local packet
		repeat
			packet = modem.receive()
		until packet and packet[5][1] == "connection_port" and packet[2] == ip
		print("Packet accepted.")
		server_connection_port = packet[4]
		key = SHA(tostring(DH(modem, ip, server_connection_port, send_port)))
		enc_pass = AES.encryptBytes(key, pass)
		enc_user = AES.encryptBytes(key, user)
		self.sendCommand({
			[1] = enc_user,
			[2] = enc_pass,
		})
	end

	self.list = function(path)

	end

	self.exists = function(path)

	end

	self.isDir = function(path)

	end

	self.isReadOnly = function(path)

	end

	self.getSize = function(path)

	end

	self.getFreeSpace = function(path)

	end

	self.makeDir = function(path)

	end

	self.move = function(path)

	end

	self.copy = function(path)

	end

	self.delete = function(path)

	end
	
	return self
end

return FTP