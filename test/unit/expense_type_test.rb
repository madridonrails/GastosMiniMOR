require File.dirname(__FILE__) + '/../test_helper'

class ExpenseTypeTest < Test::Unit::TestCase
  fixtures :expense_types

  NEW_EXPENSE_TYPE = {:name => 'Entrada de cine'}
  REQ_ATTR_NAMES = %w(name) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = expense_types(:first)
  end

  def test_raw_validation
    expense_type = ExpenseType.new
    if REQ_ATTR_NAMES.blank?
      assert expense_type.valid?, "ExpenseType should be valid without initialisation parameters"
    else
      # If ExpenseType has validation, then use the following:
      assert !expense_type.valid?, "ExpenseType should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert expense_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    expense_type = ExpenseType.new(NEW_EXPENSE_TYPE)
    assert expense_type.valid?, "ExpenseType should be valid"
    NEW_EXPENSE_TYPE.each do |attr_name|
      assert_equal NEW_EXPENSE_TYPE[attr_name], expense_type.attributes[attr_name], "ExpenseType.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_expense_type = NEW_EXPENSE_TYPE.clone
      tmp_expense_type.delete attr_name.to_sym
      expense_type = ExpenseType.new(tmp_expense_type)
      assert !expense_type.valid?, "ExpenseType should be invalid, as @#{attr_name} is invalid"
      assert expense_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end

  def test_duplicate
    current_expense_type = ExpenseType.find(:first)
    DUPLICATE_ATTR_NAMES.each do |attr_name|
      expense_type = ExpenseType.new(NEW_EXPENSE_TYPE.merge(attr_name.to_sym => current_expense_type[attr_name]))
      assert !expense_type.valid?, "ExpenseType should be invalid, as @#{attr_name} is a duplicate"
      assert expense_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
end

