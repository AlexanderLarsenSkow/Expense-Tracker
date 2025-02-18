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

  def change_name(new_name)
    self.name = new_name
  end

  def include?(item)
    expenses.include? item
  end

  def size
    expenses.size
  end

  def sum
    expenses.map { |expense| expense.cost }.sum
  end

  def find(id)
    expenses.find { |expense| expense.id == id }
  end

  def find_max
    expenses.map(&:id).max
  end

  def each
    expenses.each { |expense| yield(expense) }
    self
  end

  private

  attr_reader :expenses
  attr_writer :name
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
