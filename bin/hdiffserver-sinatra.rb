require 'sinatra'
require 'digest/sha1'
require 'celluloid'
require 'hdiff'

class HdiffStore
  include Celluloid

  def initialize
    @hdiffs = {}
  end

  def hdiff filename
    ret = ""
    HDiff.roll(File.open(filename, File::RDONLY)) do |summary|
      ret << summary.join('-')
      ret << "\r\n"
    end
    ret
  end
end


class HdiffServer < Sinatra::Base
  set :server, :thin

  configure do
    mime_type :hdiff, 'text/hdiff'
  end

  get '/index.html' do
    send_file "../ui/index.html"
  end

  get '/:filename' do
    filename = params[:filename]
    return 404 unless File.exists? filename
    return 404 if filename.match(/\.hdiff$/)

    etag Digest::SHA1.file filename

    if request.accept?('text/hdiff')
      [200, {"Content-Type" => "text/hdiff"}, [@store.future.hdiff(filename).value]]
    else
      send_file filename
    end
  end

  if __FILE__ == $0
    ::HdiffStore.supervise_as :hdiffstore
    @store = Celluloid::Actor[:hdiffstore]
    run!
  end
end
