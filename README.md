# airbrake-cr
Airbrake notifier made in Crystal Lang

## Installation and usage

### In your `shard.yml`

```YAML
airbrake:
    github: tgferox/airbrake-cr
```

### In your crystal application

```CR
require "http/server"
require "airbrake"

Airbrake.configure do |config|
  config.project_id = 2
  config.endpoint = "your endpoint here"
  config.project_key = "your project key"
end



server = HTTP::Server.new([
  Airbrake::ErrorHandler.new #Replace any other Error Handler with this one
])

server.bind_tcp "127.0.0.1", 8080
server.listen
```

## Project To-do
- Implement HTTP data
- Implement masking parameters
- Implement session data
