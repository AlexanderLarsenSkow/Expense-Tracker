require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

get '/' do
  "Hello World"
end