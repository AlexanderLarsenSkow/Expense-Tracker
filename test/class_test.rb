require 'minitest/autorun'
require 'bundler/setup'
require_relative '../classes'

class ExpenseListTest < Minitest::Test
  def setup
    @expense_one = Expense.new('Remodel', 20_000, 1)
    @expense_two = Expense.new('Cleaning', 500, 2)
    @expense_three = Expense.new('Painting', 1000, 3)
    @list = ExpenseList.new('Home Costs', 1)
  end

  def test_expense_getters
    assert_equal 20_000, @expense_one.cost
    assert_equal 'Cleaning', @expense_two.name
    assert_equal 3, @expense_three.id
  end

  def test_expense_to_s
    output = 'Cleaning'
    assert_equal output, @expense_two.to_s
  end

  def test_list_getters
    name = "Home Costs"
    id = 1

    assert_equal name, @list.name
    assert_equal id, @list.id
    assert_raises(NoMethodError) { @list.expenses }
  end

  def test_add
    @list << @expense_one

    assert_includes @list, @expense_one
    assert_equal 1, @list.size
  end

  def test_delete
    @list << @expense_one
    @list.delete(1)

    refute_includes @list, @expense_one
    assert_equal 0, @list.size
  end

  def test_include
    @list << @expense_one

    assert @list.include?(@expense_one)
  end

  def test_size
    @list << @expense_one << @expense_two

    assert_equal 2, @list.size
  end

  def test_sum
    @list << @expense_one << @expense_two
    assert_equal 20_500, @list.sum

    @list << @expense_three
    assert_equal 21_500, @list.sum
  end

  def test_each
    @list << @expense_one << @expense_two

    assert_raises(LocalJumpError) { @list.each }
    assert_equal @list, @list.each { |exp| exp }

    total = 0
    @list.each { |expense| total += expense.cost }

    assert_equal 20_500, total
  end
end
