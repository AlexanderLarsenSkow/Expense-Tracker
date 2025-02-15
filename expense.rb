require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

get '/' do
  @years = session[:years]

  erb :home
end

get '/add' do
  erb :add_years
end

def set_id
  return 1 if session[:years].empty?
  session[:years].map { |year_list| year_list[:id] }.max + 1
end

post '/add/year' do
  @year = params[:year]
  session[:years] = [] unless session[:years]

  session[:years] << { id: set_id, year: @year, expense_lists: [] }
  redirect '/'
end

def set_up_year
  @years = session[:years]
  @year_id = params[:year_id].to_i
  @year = @years.find { |year| year[:id] == @year_id }

end

get '/:year_id' do
  set_up_year

  erb :year
end