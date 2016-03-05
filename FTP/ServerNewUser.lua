local path = ...

local dofile = function(path,...)
	local f, err = loadfile(path)
	if not f then
		print(err)
	end
	setfenv(f,_G)
	return f(...)
end

local SHA = dofile(path.."/lib/SHA256.lua")

term.write("Username: ")
local username = read()

term.write("Password: ")
local pass1 = read()

term.write("Confirm password: ")
local pass2 = read()
if pass2 ~= pass1 then
	error("Passwords do not match!")
end

local sha_pass = SHA(pass1)

local p = {
	admin = true,
	user = true,
	guest = true
}

local perm
repeat
	term.write("Permission level: <admin><user><guest> ")
	perm = read()
until p[perm]

local file = fs.open(".ftp/users","a")
file.write(username..":"..perm..":"..sha_pass.."\n")
file.close()
