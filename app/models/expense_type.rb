# == Schema Information
# Schema version: 2
#
# Table name: expense_types
#
#  id               :integer(11)   not null, primary key
#  account_id       :integer(11)   not null
#  url_id           :string(255)   not null
#  name             :string(255)   not null
#  name_for_sorting :string(255)   
#  created_at       :datetime      
#  updated_at       :datetime      
#

class ExpenseType < ActiveRecord::Base
  belongs_to :account

  has_many :expenses, :dependent => :destroy

  add_for_sorting_to :name

  validates_presence_of :name

  def before_create
    compute_and_set_url_id
  end
  
  def before_update
    self_in_db = ExpenseType.find(id, :select => 'id, name')
    compute_and_set_url_id if name != self_in_db.name
  end
  
  def to_param
    url_id
  end

  def compute_and_set_url_id
    candidate = GastosminiUtils.normalize_for_url_id(name)
    prefix = candidate
    n = 1
    loop do
      et = ExpenseType.find_by_account_id_and_url_id(account_id, candidate)
      break if et.nil?
      return if self == et # perhaps just an accented letter was changed or whatever
      n += 1
      candidate = "#{prefix}-#{n}"
    end
    self.url_id = candidate
  end
  private :compute_and_set_url_id

  def can_be_destroyed?
    expenses.empty?
  end

end
