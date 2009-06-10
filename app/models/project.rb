# == Schema Information
# Schema version: 2
#
# Table name: projects
#
#  id                      :integer(11)   not null, primary key
#  account_id              :integer(11)   not null
#  url_id                  :string(255)   not null
#  name                    :string(255)   
#  name_for_sorting        :string(255)   
#  description             :string(255)   
#  description_for_sorting :string(255)   
#  notes                   :text          
#  created_at              :datetime      
#  updated_at              :datetime      
#

class Project < ActiveRecord::Base
  belongs_to :account

  has_many :expenses, :dependent => :destroy
  
  has_one :login_token, :class_name => 'LoginTokenForProject', :dependent => :destroy
  after_create :renew_login_token
    
  add_for_sorting_to :name

  validates_presence_of :name

  def before_create
    compute_and_set_url_id
  end
  
  def before_update
    self_in_db = Project.find(id, :select => 'id, name')
    compute_and_set_url_id if name != self_in_db.name
  end
  
  def to_param
    url_id
  end

  def renew_login_token
    # It may fail because of the UNIQUE constraint on the token column, very unlikely but possible.
    loop do
      token = GastosminiUtils.random_login_token
      if login_token.nil?
        break if create_login_token(:token => token)
      else
        break if login_token.update_attribute(:token, token)
      end
    end
  end

  def compute_and_set_url_id
    candidate = GastosminiUtils.normalize_for_url_id(name)
    prefix = candidate
    n = 1
    loop do
      p = Project.find_by_account_id_and_url_id(account_id, candidate)
      break if p.nil?
      return if self == p # perhaps just an accented letter was changed or whatever
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
