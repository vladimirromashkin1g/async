-- c lib / bindings for libuv
local uv = require 'luv'

-- handle
local handle = require 'async.handle'
-- url parser
local tcp = require 'async.tcp'

-- TCP server/client:
local udp = {}

-- protocols:
udp.protocols = {
   http = 80,
   https = 443,
}

-- url parser:
udp.parseUrl = function(url, cb)
   if type(url) == 'string' then
      local parseUrl = require 'lhttp_parser'.parseUrl
      local parsed = parseUrl(url)
      parsed.port = parsed.port or http.protocols[parsed.schema]
      url = parsed
   end
   local isip = url.host:find('^%d*%.%d*%.%d*%.%d*$')
   if not isip then
      uv.getaddrinfo(url.host, url.port, nil, function(res)
         url.host = (res[1] and res[1].addr) or error('could not resolve address: ' .. url.host)
         cb(url)
      end)
   else
      cb(url)
   end
end

function udp.listen(domain, cb)
   local server = uv.new_udp()
   local h = handle(server)
   h.settype("udp")
   tcp.parseUrl(domain, function(domain)
      local host = domain.host
      local port = domain.port
      uv.udp_bind(server, host, port)
      uv.udp_recv_start(server)
      h.sockname = uv.udp_getsockname(server)
      cb(h)
   end)
   return h
end

function udp.connect(domain, cb)
   local client = uv.new_udp()
   local h = handle(client)
   tcp.parseUrl(domain, function(domain)
      local host = domain.host
      local port = domain.port
      uv.udp_connect(client, host, port, function()
         h.sockname = uv.udp_getsockname(client)
         cb(h)
      end)
   end)
   return h
end

-- UDP lib
return udp
