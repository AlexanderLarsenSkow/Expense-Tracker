class ExpenseList
  attr_reader :name, :id
  
  def initialize(name, id)
    @name = name
    @expenses = []
    @id = id
  end

  def <<(item)
    expenses << item
  end

  def delete(id)
    expense = expenses.find { |exp| exp.id == id }
    expenses.delete(expense)
  end

  def sum
    expenses.map { |expense| expense.cost }.sum
  end

  def each
    expenses.each { |expense| yield(expense) }
    expenses
  end

  private

  attr_reader :expenses
end

class Expense
  attr_reader :name, :cost, :id

  def initialize(name, cost, id)
    @name = name
    @cost = cost
    @id = id
  end

  def to_s
    name
  end
end