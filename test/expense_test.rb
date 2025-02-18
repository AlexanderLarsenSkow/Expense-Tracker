ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../expense'

class ExpenseTest < Minitest::Test
  include Rack::Test::Methods

  def session
    last_request.env['rack.session']
  end

  def app
    Sinatra::Application
  end

  def test_home
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'Expense Tracker'
    assert_includes last_response.body, "<a href = '/add'"
    assert_equal 200, last_response.status
  end

  def test_add_get
    get '/add'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form method = 'post'"
    assert_includes last_response.body, %q(<button type = 'submit')
  end

  def test_add_year
    post '/add/year', year: '2025'
    assert_equal 302, last_response.status
    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Success!'
    assert_includes last_response.body, '2025'
  end

  def test_add_year_error
    post 'add/year', year: ''
    
    error = 'Please enter a value between 1 and 100 characters.'
    assert_includes last_response.body, error

    assert_equal 200, last_response.status
  end

  def test_year_page
    post '/add/year', year: '2025'
    get '/year/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '2025'
    assert_includes last_response.body, 'Add Expense'
    assert_includes last_response.body, "<a href = '/'>Home</a>"
  end

  def test_add_list_get
    post 'add/year', year: '2025'
    get '/year/1/add_list'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Add Expense List'
    assert_includes last_response.body, %q(action = "/year/1")
    assert_includes last_response.body, %q(<button type = 'submit')
  end

  def test_add_list
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    message = 'Success! You have added a new list.'

    assert_equal 302, last_response.status
    assert_equal message, session[:success]
    follow_redirect!

    assert_includes last_response.body, message
    assert_includes last_response.body, 'Categories'
    assert_includes last_response.body, 'Shopping'
    assert_nil session[:success]
  end

  def test_add_list_error
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post 'year/1', expense_list: 'Shopping'

    error = 'Please enter a new list.'
    assert_includes last_response.body, error
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form method ="
  end

  def test_list_page
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    get '/year/1/list/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Shopping'
    assert_includes last_response.body, 'Add Expense'
    assert_includes last_response.body, %q("/year/1/list/1/edit")
  end

  def test_edit_list_page
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    get '/year/1/list/1/edit'
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Edit Shopping'
    assert_includes last_response.body, %q(value = "Shopping")
    assert_includes last_response.body, %q(<button type = 'submit')
    assert_includes last_response.body, 'Delete List'
  end

  def test_edit_list
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post '/year/1/list/1/edit', edit: 'Groceries'

    message = 'You have successfully changed the list name!'
    assert_equal message, session[:success]
    assert_equal 302, last_response.status

    follow_redirect!

    assert_includes last_response.body, message
    assert_includes last_response.body, 'Groceries'
  end
  
  def test_edit_list_error
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post '/year/1/list/1/edit', edit: '  '

    error = 'List must be between 1 and 100 characters.'

    assert_includes last_response.body, error
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(value = "  ")
  end

  def test_delete_list
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post '/year/1/list/1/delete_list'

    message = 'Success! You have deleted Shopping.'
    assert_equal message, session[:success]
    assert_equal 302, last_response.status

    get '/year/1'
    
    assert_equal 200, last_response.status
    refute_includes last_response.body, 'Categories:'
  end

  def test_add_expense_page
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    get '/year/1/list/1/add'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Cost:'
    assert_includes last_response.body, %q(button type = 'submit')
    assert_includes last_response.body, %q(value = "$")
  end

  def test_add_expense
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post 'year/1/list/1', {expense: 'Chips', cost: '$3.50'}

    assert_equal 'Success!', session[:success]
    assert_equal 302, last_response.status

    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(Chips: <strong>$3.50)
    assert_includes last_response.body, "Total: $3.50"
  end

  def test_good_totals_list
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: 'Chips', cost: '$3.50'}
    post '/year/1/list/1', {expense: 'Chips', cost: '$12.25'}
    post '/year/1/list/1', {expense: 'Chips', cost: '$19.71'}

    assert_equal 302, last_response.status
    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Total: $35.46"
  end

  def test_add_expense_with_commas_and_no_periods
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    
    post '/year/1/list/1', {expense: 'Chips', cost: '$23,500'}

    assert_equal 'Success!', session[:success]
    assert_equal 302, last_response.status

    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Total: $23,500.00"
  end

  def test_add_expense_lots_of_commas
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: 'Chips', cost: '$21,,,500'}

    assert_equal 302, last_response.status
    assert_equal 'Success!', session[:success]

    follow_redirect!

    assert_includes last_response.body, "Total: $21,500.00"
  end

  def test_add_expense_error_too_many_periods
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: 'Chips', cost: '$3......50'}

    error = 'Please only enter one period with two decimals.'
    assert_includes last_response.body, error
    assert_equal 200, last_response.status
  end

  def test_add_expenses_error_too_many_decimal_points
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: 'Chips', cost: '$3.50000000'}

    error = 'Please only enter one period with two decimals.'
    assert_includes last_response.body, error
    assert_equal 200, last_response.status
  end

  def test_add_expenses_error_letters_in_cost
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: 'Chips', cost: 'abcd3.50'}

    error = 'Please enter a number that only includes a $, comma, or period.'
    assert_includes last_response.body, error
    assert_equal 200, last_response.status
  end

  def test_add_expense_error_empty_inputs
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'

    post '/year/1/list/1', {expense: ' ', cost: '$3.50'}

    error = 'Please enter values between 1 and 100 characters.'
    assert_includes last_response.body, error
    assert_equal 200, last_response.status
  end

  def test_delete_expense
    post 'add/year', year: '2025'
    post 'year/1', expense_list: 'Shopping'
    post '/year/1/list/1', {expense: 'Chips', cost: '$3.50'}

    post '/year/1/list/1/1/delete'

    assert_equal 302, last_response.status
    message = 'You have successfully deleted the Chips Expense.'
    assert_equal message, session[:success]

    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Total: $0.00"
  end
end
