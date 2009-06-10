# == Schema Information
# Schema version: 2
#
# Table name: login_tokens
#
#  id         :integer(11)   not null, primary key
#  account_id :integer(11)   
#  project_id :integer(11)   
#  type       :string(255)   
#  token      :string(255)   not null
#  created_at :datetime      
#  updated_at :datetime      
#

class LoginTokenForProject < LoginToken
end
