# == Schema Information
# Schema version: 2
#
# Table name: accounts
#
#  id               :integer(11)   not null, primary key
#  owner_id         :integer(11)   
#  short_name       :string(255)   not null
#  blocked          :boolean(1)    not null
#  name             :string(255)   not null
#  name_for_sorting :string(255)   
#  logo             :string(255)   
#  direct_login     :boolean(1)    
#  created_at       :datetime      
#  updated_at       :datetime      
#

class Account < ActiveRecord::Base
  attr_protected :direct_login, :owner_id, :is_blocked, :is_active  
  belongs_to :owner, :class_name => 'User', :foreign_key => :owner_id
  
  has_many :users, :dependent => :destroy
  has_many :projects, :order => 'name_for_sorting ASC', :dependent => :destroy
  has_many :expense_types, :order => 'name_for_sorting ASC', :dependent => :destroy
  has_many :expenses, :dependent => :destroy

  has_one :login_token_for_agencies, :dependent => :destroy
  after_create :renew_login_token_for_agencies
  after_create :create_default_project_and_expense_type
  
  has_one :chpass_token, :dependent => :destroy

  add_for_sorting_to :name
  
  validates_presence_of   :name
  validates_presence_of   :short_name
  validates_uniqueness_of :short_name
  validates_exclusion_of  :short_name, :in => CONFIG['reserved_subdomains'], :message => 'esta es una dirección reservada'
  validates_format_of     :short_name, :with => %r{\A[a-z][\-a-z\d]+\z}, :message => 'la dirección debe empezar por una letra y sólo puede tener caracteres alfanumericos'
  
  # We do not validate the existence of the owner because of the
  # chicken and egg problem in the public signup, that action
  # must ensure there's a owner.
  validates_associated :owner

  def renew_login_token_for_agencies
    # We loop because of the UNIQUE constraint on the token column.
    loop do
      token = GastosminiUtils.random_login_token
      if login_token_for_agencies.nil?
        break if create_login_token_for_agencies(:token => token)
      else
        break if login_token_for_agencies.update_attribute(:token, token)
      end
    end
  end
  private :renew_login_token_for_agencies

  def create_default_project_and_expense_type
    self.projects.create :name => 'General', :description => 'Categoría general'
    self.expense_types.create :name => 'Comidas'
    self.expense_types.create :name => 'Comidas con Clientes'
    self.expense_types.create :name => 'Parking'
    self.expense_types.create :name => 'Kilometraje'
    self.expense_types.create :name => 'Taxi'    
    self.expense_types.create :name => 'Avion'
    self.expense_types.create :name => 'Otros desplazamientos'
    self.expense_types.create :name => 'Material de Oficina'
    self.expense_types.create :name => 'Varios'
  end
  private :create_default_project_and_expense_type

  def set_chpass_token
    # We loop because of the UNIQUE constraint on the token column.
    loop do
      token = GastosminiUtils.random_chpass_token
      if chpass_token.nil?
        break if create_chpass_token(:token => token)
      else
        break if chpass_token.update_attribute(:token, token)
      end
    end
  end
  
  def default_project
    self.projects.find_by_name 'General' rescue nil
  end

  def default_expense_type
    self.expense_types.find_by_name 'General' rescue nil
  end
  
  def envelopes
    expenses.map {|e| e.envelope}.reject {|e| e.blank?}.uniq.sort
  end

end
