-- Imports
local http_server = require "http.server" -- LUA-HTTP library for handling http
local http_headers = require "http.headers" -- LUA-HTTP library for handling http

-- Define the server host and port
local HOST = "0.0.0.0"
local PORT = 8080

-- Function to handle incoming requests asynchronously
local function handle_request(stream)
  local req_headers = assert(stream:get_headers())
  local method = req_headers:get(":method")
  local path = req_headers:get(":path")
  
  print("Received " .. method .. " request for " .. path)

  -- Simulate async operation (like querying a database)
  local async_task = function()
    -- Simulate a delay (like a database query)
    socket.sleep(1) -- Use a non-blocking sleep for actual async tasks
    return "Async Task Completed"
  end

  -- Spawn a coroutine for async handling
  local co = coroutine.create(async_task)
  local success, result = coroutine.resume(co)

  -- Prepare response headers
  local res_headers = http_headers.new()
  res_headers:append(":status", "200")
  res_headers:append("content-type", "text/plain")
  
  -- Send response back to the client
  assert(stream:write_headers(res_headers, false))
  assert(stream:write_body_from_string(result))
end

-- Start the async HTTP server
local server = assert(http_server.listen {
  host = HOST,
  port = PORT,
  onstream = handle_request,
  onerror = function(server, context, op, err, errno)
    io.stderr:write(string.format("%s on %s failed: %s\n", op, context, err))
  end
})

print("HTTP Server running on " .. HOST .. ":" .. PORT)
assert(server:loop())
