--
--  Event publish script for redis
--  Copyright (C) 2014-2014 elfixit <el@xiala.net>
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

pcall(require, "luarocks.require")
--print(package.path)
package.path = package.path .. ';/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua'
-- print(package.path)
require 'luarocks.loader'

local json = require("json")
local redis = require('redis')

output_redis = pom.output.new("output_redis", "push a event on a redis channel", {
    { "log_file", "string", "output_redis.log", "name of the log file"},
    { "event", "string", "payload", "name of the event" },
    { "redis_host", "string", "localhost", "host of redis daemon"},
    { "redis_port", "uint32", 6379, "post of the redis daemon"},
    { "channel", "string", "pomng", "name of the redis channel to publish"},
})


function pload_open(payload_priv, payload)

end

function pload_write(payload_priv, payload_data)

end

function pload_close(payload_priv)

end

function output_redis:handle_event(evt)
    local con = self:get_conn()
    pom.log(POMLOG_DEBUG, "handle event: " .. evt.name)
    local data = self:data2table(evt.data)
    local resp = con:publish(self:param_get('channel'), json.encode(data))
end

function output_redis:data2table(data)
    local data_iter = pom.data.iterator(data)
    local tbl = {}
    while true do
        local key, value
        key, value = data_iter()
        if not key then break end

        local value_type = type(value)
        if value_type == "userdata" then
            print("Data has key " .. key .. " which value is a data_item object")
            tbl[key] = data2table(value)
        elseif value_type == "nil" then
            print("Data has key " .. key .. " with no value associated")
            tbl[key] = nil
        else
            print("Data has key " .. key .. " with value \"" .. value .. "\"")
            tbl[key] = value
        end
    end
end

function output_redis:get_conn()
    local client = redis.connect(self:param_get('redis_host'), self:param_get('redis_port'))
    return client
end

function output_redis:open()

    -- Open the log file
    pom.log(POMLOG_DEBUG, "start output_redis addon")
    if self:param_get("event") == "payload" then
        -- handle pload events
        self:pload_listen_start(self.pload_open, self.pload_write, self.pload_close)
        pom.log(POMLOG_DEBUG, "subscribed to pload events")
    else
        -- subscribe to event
        self:event_listen_start(self:param_get('event'), self.handle_event)
        pom.log(POMLOG_DEBUG, "subscribed to event")
    end

end



function output_redis:close()

    pom.log(POMLOG_DEBUG, "start output_redis addon")
    if self:param_get("event") == "payload" then
        -- handle pload events
        self:pload_listen_stop()
        pom.log(POMLOG_DEBUG, "unsubscribed to pload events")
    else
        -- subscribe to event
        self:event_listen_stop(self:param_get('event'))
        pom.log(POMLOG_DEBUG, "unsubscribed to event " .. self:param_get('event'))
    end

end

