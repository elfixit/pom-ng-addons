--
--  Wall of sheep script for pom-ng. It dumps all the password seen.
--  Copyright (C) 2013-2014 Guy Martin <gmsoft@tuxicoman.be>
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
--

output_wallofsheep = pom.output.new("wallofsheep", "Log clear text password seen on the network", {
	{ "log_file", "string", "wallofsheep.log", "Log filename" },
})


function output_wallofsheep:process_http_request(evt)
    self:process_http_request_auth(evt)
    self:process_http_request_post(evt)
end

function output_wallofsheep:process_http_request_auth(evt)

    local data = evt.data

    local username = data["username"]
    local password = data["password"]

    if not username or not password then return end

    local client = data["client_addr"]
    local server = data["server_name"]
    local status = data["status"]

    if not status
    then
        status = "unknown"
    end


    self.logfile:write(os.date('%Y %m %d %X') .."Found credentials via HTTP : " .. client .. " -> " .. server .. " | user : '" .. username .."', password : '" .. password .. "' (status " .. status .. ")\n")
    self.logfile:flush()

end

function output_wallofsheep:process_http_request_post(evt)

    local data = evt.data

    if not data['request_method'] == 'POST' then return end

    local password
    local post_str
    post_str = "{"
    local data_iter = pom.data.item_iterator(data['post_data'])
    while true do
        local key, value
        key, value = data_iter()
        if not key then break end
        --print("key: " .. key .. " value: " .. value)
        local value_type = type(value)
        if not value_type == "userdata" and not value_type == "nil" then
            if key == 'passwd' then
                password = value
            elseif key == 'password' then
                password = value
            elseif key == 'pass' then
                password = value
            end
            post_str = post_str .. key .. " => " .. value ..", "
        else
            print("invalid post data key: " .. key .. " value: " .. value)
        end
    end
    post_str = post_str .. "}"
    if not username or not password then
        pom.log(POMLOG_DEBUG, "didn't found any information in postdata: " .. post_str)
        return
    end

    local client = data["client_addr"]
    local server = data["server_name"]

    self.logfile:write(os.date('%Y %m %d %X') .. " Found credentials via HTTP POST: " .. client .. " -> " .. server .. " | password: '" .. password .. " postdata : " .. post_str .. "\n")
    self.logfile:flush()

end

function output_wallofsheep:process_smtp_auth(evt)

	local data = evt.data
	local server = data["server_host"]
	if not server
	then
		server = data["server_addr"]
	end
	
	local params = data["params"]

	if not params then
		print("PARAMS not found !")
		return
	end

	local username = params["username"]
	local password = params["password"]
	local method = data["type"]

	if not username or not password then return end

	local status = "unknown"
	local success = data["success"]
	if success == true then
		status = "success"
	elseif success == false then
		status = "auth failure"
	end

	local client = data["client_addr"]

	self.logfile:write(os.date('%Y %m %d %X') .. "Found credentials via SMTP : " .. client .. " -> " .. server .. " | user : '" .. username .. "', password : '" .. password .. "', method : '" .. method .. "' (status : " .. status .. ")\n")
	self.logfile:flush()

end

function output_wallofsheep:process_ppp_pap_auth(evt)

	local data = evt.data

	local msg = "Found credentials via PPP-PAP : "

	local client = data["client"]
	local server = data["server"]
	if client and server then
		msg = msg ..  client .. " -> " .. server .. " "
	end
	
	local top_proto = data["top_proto"]
	if top_proto then
		msg = msg .. "over " .. top_proto .. " "
	end

	local vlan = data["vlan"]
	if vlan then
		msg = msg .. "on vlan " .. vlan .. " "
	end

	msg = msg .. "| user : '" .. data["peer_id"] .. "', password : '" .. data["password"]

	local status = "unknown"
	local success = data["success"]
	if success == true then
		status = "success"
	elseif success == false then
		status = "auth failure"
	end
	self.logfile:write(os.date('%Y %m %d %X') .. " " .. msg .. "' (status : " .. status .. ")\n")
	self.logfile:flush()

end

function output_wallofsheep:open()

	-- Open the log file
	self.logfile = io.open(self:param_get("log_file"), "a")

	-- Listen to HTTP request event
	self:event_listen_start("http_request", nil, self.process_http_request)

	-- Listen to SMTP auth event
	self:event_listen_start("smtp_auth", nil, self.process_smtp_auth)

	-- Listen to PPP-PAP auth event
	self:event_listen_start("ppp_pap_auth", nil, self.process_ppp_pap_auth)

end

function output_wallofsheep:close()

	if self.logfile then
		self.logfile:close()
	end

	self:event_listen_stop("http_request")
	self:event_listen_stop("smtp_auth")
	self:event_listen_stop("ppp_pap_auth")


end

