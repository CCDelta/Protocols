--[[
	Server Setup
]]--

local function writeTo(path, data)
	local file = fs.open(".ftp/"..path,"w")
	file.write(data)
	file.close()
end

local default = [[
list:admin
exists:admin
isDir:admin
isReadOnly:admin
getSize:admin
getFreeSpace:admin
makeDir:admin
move:admin
copy:admin
delete:admin
combine:admin
open:admin
find:admin
getDir:admin
]]

local file = fs.open(".ftp/permissions","w")
file.write(default)
file.close()

term.write("Which side is the modem on: ")
local side = read()
writeTo("side",side)

term.write("Which is the request port? ")
local re = read()
term.write("Which is the authentification port? ")
local au = read()

writeTo("ports",re.."\n"..au)

print("Thank you for choosing Delta FTP.")