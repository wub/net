--[[

  DNS SERVER / TRAFFIC DIRECTOR

	Periodically gathers computer IDs and labels, and tracks the pairs in a 
	globally accessible	table (via simple API). 

	Either periodically request id:label from each server or only update
	when pushed to from server? Will test performance of both. Perhaps the
	latter, as it will reduce garbage traffic?

	For now, this server will also forward rednet messages. It may stay
	that way, due to the _current_ simplicity of the system.

	Pull event raw (when deployed), to prevent termination.
	The service will be centralised to help prevent poisoning.

		- Disk -> bottom
		- Monitor -> top
		- Modem -> right

	TODO: Local DNS cache! Valid for x game hours
	TODO: Unique label validation! Don't let them in
	      until they are unique. FIFS.
	TODO: Registrar. Mitigate above problem.

]]

local master_id = os.getComputerID()
local monitor = peripheral.wrap('top')
local cycle = false

-- To retrieve a key by its value - rather than value by key
function get_key(table, value)
	for key, values in pairs(table) do
		if values == value then
			return key
		end
	end

	return nil
end

-- http://lua-users.org/wiki/SplitJoin
-- Function: true Python semantics for split
-- Will move into our own API
function string_split(sString, sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)

	local aRecord = {}

	if sString:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField=1 nStart=1
		local nFirst,nLast = sString:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = sString:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = sString:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = sString:sub(nStart)
	end

	return aRecord
end

function propagate_dns()
	-- this may have to be done in a loop from 1 -> 100?

	monitor.write('Updating DNS...')
	rednet.broadcast(master_id .. '|dns')

	-- Generous 10s to receive responses
	-- will this terminate after a single response?
	id, label = rednet.receive(10)

	-- Enforce unique labels
	if dns[label] then do
		rednet.send(id, 'Non-unique label; os.setComputerLabel("unique foo")')
	else
		-- Using label as key makes lookups easier
		dns[label] = id
	end

	monitor.write('+ ' .. id .. ' -=> ' .. label)
end


function boot()
	monitor.write('Booting modem...')

	-- Boot up the modem
	-- TODO: if it's off/can't boot, spout a friendly error
	rednet.open('right')
	monitor.write('Initialising DNS...')

	-- Declare the global DNS table with master servers
	dns = {
		master = master_id,
		backup = 2 -- Technician to manually set this ID
	}

	propagate_dns()
	monitor.write('Listening...')

	-- Prepare your l0gz
	local log = 'log'

	-- Listening for queries.
	while true do
		event, id, request = os.pullEvent()
		req = string_split(request, '|')
		
		target = req[1]
		cmd = req[2], req[3]

		rednet.send(target, cmd, true)
		monitor.write(get_key(dns, id) .. ' -=> ' .. get_key(dns, target))

		if fs.exists(file) then
			write_log = fs.open(file, 'a')

			write_log.write(id, request)
			write_log.close()
		end
	end
end

-- Perhaps redundant; blind copypasta
if cycle = false then do
	boot()

	cycle = true
end


--[[--handy functions
	for k,v in pairs(t) do print(k,v) end
	for i,v in ipairs(t) do print(i,v) end
]]
