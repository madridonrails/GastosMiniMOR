# == Schema Information
# Schema version: 2
#
# Table name: chpass_tokens
#
#  id         :integer(11)   not null, primary key
#  account_id :integer(11)   not null
#  token      :string(255)   not null
#  created_at :datetime      
#

class ChpassToken < ActiveRecord::Base
  belongs_to :account
end
