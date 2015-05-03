require './app.rb'

class Carte::Server
  configure do
    Mongoid.load! './mongoid.yml'
    config = JSON.parse File.read('config.json')
    set :carte, config
  end
end

map '/' do
  run Sinatra::Application
end

map '/cards' do
  run Carte::Server.new
end
