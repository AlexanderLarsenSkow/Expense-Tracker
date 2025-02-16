require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'bcrypt'

require_relative 'classes'

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

def set_year_id
  return 1 if session[:years].empty?
  session[:years].map { |year_list| year_list[:id] }.max + 1
end

def set_expense_list_id
  return 1 if @expense_lists.empty?
  @expense_lists.map { |list| list.id }.max + 1 
end

post '/add/year' do
  @year = params[:year]
  session[:years] = [] unless session[:years]

  session[:years] << { id: set_year_id, year: @year, expense_lists: [] }
  redirect '/'
end

def set_up_year
  @years = session[:years]
  @year_id = params[:year_id].to_i
  @year = @years.find { |year| year[:id] == @year_id }
  @expense_lists = @year[:expense_lists]
end

get '/year/:year_id' do
  set_up_year

  erb :year
end

get '/year/:year_id/add_list' do
  set_up_year

  erb :add_expense_list
end

post '/year/:year_id' do
  set_up_year
  list_id = set_expense_list_id

  @year[:expense_lists] << ExpenseList.new(params[:expense_list], list_id)
  redirect "/year/#{@year_id}"
end

def set_up_list
  @list_id = params[:list_id].to_i
  @list = @expense_lists.find { |list| list.id == @list_id }
  @name = @list.name
  @total_costs = @list.sum
end

get '/year/:year_id/list/:list_id' do
  set_up_year
  set_up_list

  erb :list
end

get "/year/:year_id/list/:list_id/add" do
  set_up_year
  set_up_list

  erb :add_expense
end

def set_expense_id
  return 1 if @list.size == 0
  @list.find_max + 1
end

post '/year/:year_id/list/:list_id' do
  set_up_year
  set_up_list

  name = params[:expense]
  cost = params[:cost].to_i
  id = set_expense_id

  expense = Expense.new(name, cost, id)
  @list << expense

  redirect "/year/#{@year_id}/list/#{@list_id}"
end
