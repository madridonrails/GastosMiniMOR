# == Schema Information
# Schema version: 2
#
# Table name: expenses
#
#  id                   :integer(11)   not null, primary key
#  account_id           :integer(11)   not null
#  project_id           :integer(11)   not null
#  expense_type_id      :integer(11)   not null
#  date                 :date          
#  amount               :decimal(10, 2 
#  concept              :string(255)   not null
#  concept_for_sorting  :string(255)   
#  notes                :text          
#  envelope             :string(255)   
#  envelope_for_sorting :string(255)   
#  created_at           :datetime      
#  updated_at           :datetime      
#

class Expense < ActiveRecord::Base
  belongs_to :account
  belongs_to :project
  belongs_to :expense_type

  add_for_sorting_to :concept, :envelope
  
  validates_presence_of :date, :message => "fecha inválida"  
  validates_presence_of :account_id
  validates_presence_of :account
  validates_presence_of :project_id
  validates_presence_of :project
  validates_presence_of :expense_type_id
  validates_presence_of :expense_type
  validates_presence_of :concept
  validates_presence_of :amount
  validates_numericality_of :amount

  def url_id
    id
  end
  
  def <=> (other_expense)
    self.date <=> other_expense.date
  end

end
