require 'reel'
require 'uri'

class HDIffServer < Reel::Server
  def initialize(host = "127.0.0.1", port = 3000)
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    while request = connection.request
      next unless request.kind_of?(Reel::Request)
      handle_request(request)
    end
  end

  def handle_request(request)
    uri = URI(request.uri)
    filename = File.join('.', uri.path)
    
    if File.exists?(filename) and not filename.match(/\.hdiff$/)
      accept_headers = request.headers["Accept"]

      body = ""

      # weak logic. We're doing science here !
      if accept_headers.match(/\s*hdiff\s*/)
        body = File.read(filename + '.hdiff')
      else
        body = File.read(filename)
      end

      request.respond :ok, body
    else
      request.respond :not_found
    end

    request.close
  end

end

HDIffServer.run
