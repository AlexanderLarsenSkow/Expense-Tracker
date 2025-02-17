require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubi'
require 'bcrypt'

require_relative 'classes'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do
  def flash_message(name)
    return unless session[name]
    "<p class = 'flash'>#{session.delete(name)}</p>"
  end

  def dollar_commas(cost)
    digits = cost.to_i.digits
    index = 0
  
    commas = digits.map do |digit|
      index += 1
      if index % 3 == 0 && digits[index]
        "#{digit},"
      
      else
        digit.to_s
      end
    end
    commas.join.reverse.prepend('$')
  end

  def handle_decimals(cost)
    cost = cost.to_s
    cost << '0' if cost[-3] != '.'

    cost[-3..-1]
  end

  def display_cost(cost)
    dollar_commas(cost) << handle_decimals(cost)
  end

  def add_dollar_sign(input)
    if input
      input.prepend('$') unless input.include?('$')
      input
    
    else
      input.to_s + '$'
    end
  end
end

get '/' do
  @years = session[:years]

  erb :home
end

def set_up_add_year
  @title = 'Add Year'
  @path = '/add/year'
  @input_name = 'year'
  @input_value = params[:year]
  @label = 'Year:'
end

get '/add' do
  set_up_add_year

  erb :add
end

def set_year_id
  return 1 if session[:years].empty?
  session[:years].map { |year_list| year_list[:id] }.max + 1
end

def set_expense_list_id
  return 1 if @expense_lists.empty?
  @expense_lists.map { |list| list.id }.max + 1 
end

def existing_year?(input_year)
  session[:years].any? { |hash| hash[:year] == input_year }
end

def invalid_size?(input)
  !(1..100).cover? input.size
end

def invalid?(input)
  existing_year?(input) || invalid_size?(input)
end

def determine_year_error(input)
  if existing_year?(input)
    session[:error] = 'Please enter a new year.'

  else
    session[:error] = 'Please enter a value between 1 and 100 characters.'
  end
end

post '/add/year' do
  set_up_add_year
  @year = params[:year].strip
  session[:years] = [] unless session[:years]

  if invalid?(@year)
    determine_year_error(@year)
    erb :add

  else
    session[:success] = 'Success! You have added a new year.'
    session[:years] << { id: set_year_id, year: @year, expense_lists: [] }
    redirect '/'
  end
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

def set_up_add_list
  @title = "Add Expense List"
  @path = "/year/#{@year_id}"
  @input_name = 'expense_list'
  @input_value = params[:expense_list]
  @label = 'List Name:'
end

get '/year/:year_id/add_list' do
  set_up_year
  set_up_add_list

  erb :add
end

def existing_list?(list_name)
  return if !@expense_lists || list_name == @name
  @expense_lists.any? { |list| list.name == list_name }
end

def invalid_list?(list_name)
  existing_list?(list_name) || invalid_size?(list_name)
end

def determine_list_error(list_name)
  if existing_list?(list_name)
    session[:error] = 'Please enter a new list.'
  
  else
    session[:error] = 'List must be between 1 and 100 characters.'
  end
end

post '/year/:year_id' do
  set_up_year
  list_name = params[:expense_list].strip
  list_id = set_expense_list_id

  if invalid_list?(list_name)
    set_up_add_list
    determine_list_error(list_name)

    erb :add
  
  else
    session[:success] = 'Success! You have added a new list.'
    @year[:expense_lists] << ExpenseList.new(params[:expense_list], list_id)
    redirect "/year/#{@year_id}"
  end
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

get '/year/:year_id/list/:list_id/edit' do
  set_up_year
  set_up_list

  erb :edit_list
end

post '/year/:year_id/list/:list_id/edit' do
  set_up_year
  set_up_list
  
  new_name = params[:edit].strip

  if invalid_list?(new_name)
    determine_list_error(new_name)

    erb :edit_list
  
  else
    session[:success] = 'You have successfully changed the list name!'
    @list.change_name(new_name)

    redirect "/year/#{@year_id}/list/#{@list_id}"
  end
end

def set_up_add_expense
  @title = 'Add Expense'
  @path = "/year/#{@year_id}/list/#{@list_id}"
  @input_name = 'expense'
  @input_value = params[:expense]
  @label = 'Name:'
end

get "/year/:year_id/list/:list_id/add" do
  set_up_year
  set_up_list
  set_up_add_expense

  erb :add
end

def set_expense_id
  return 1 if @list.size == 0
  @list.find_max + 1
end

def select_numbers(cost)
  cost.gsub(/[,$]/, '')
end

def invalid_cost?(cost)
  !cost.chars.all? { |char| char.match?(/[\d$,.]/) }
end

def too_many_periods?(cost)
  cost.count('.') > 1
end

def too_many_decimals?(cost)
  cost.include?('.') && cost[-3] != '.'
end

def invalid_period?(cost)
  too_many_periods?(cost) || too_many_decimals?(cost)
end

def invalid_expense?(name, cost)
  invalid_size?(name) || invalid_size?(cost) ||
  invalid_cost?(cost) || invalid_period?(cost)
end

def determine_expense_error(name, cost)
  if invalid_size?(name) || invalid_size?(cost)
    session[:error] = 'Please enter values between 1 and 100 characters.'
  
  elsif invalid_cost?(cost)
    session[:error] = 'Please enter a number that only includes a $, comma, or period.'
  
  elsif invalid_period?(cost)
    session[:error] = 'Please only enter one period with two decimals.'
  end
end

post '/year/:year_id/list/:list_id' do
  set_up_year
  set_up_list
  set_up_add_expense

  name = params[:expense].strip
  cost = select_numbers(params[:cost]).strip

  if invalid_expense?(name, cost)
    determine_expense_error(name, cost)
    erb :add

  else
    session[:success] = "Success!"
    dollar_convert = cost.to_f
    expense = Expense.new(name, dollar_convert, set_expense_id)
    @list << expense
  
    redirect "/year/#{@year_id}/list/#{@list_id}"
  end
end
