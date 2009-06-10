require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :accounts,:users

  def test_invalid_with_empty_attributes
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:email)
    assert user.errors.invalid?(:email_confirmation)
    assert user.errors.invalid?(:password)  
  end
    
  def test_unique_email_in_account
    jose_account = accounts(:jose)
    jose_user = users(:jose)
    user = User.new(:email => jose_user.email,:account_id=>jose_account.id)
    assert !user.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], user.errors.on(:email)
  end
  
  def test_unique_openid_url_in_account
    jose_account = accounts(:jose)
    user = User.new(:email => "samuel@example.com", :email_confirmation => "samuel@example.com", 
      :account_id=>jose_account.id,:openid_url=>'http://getopenid.com/sampleid')
    assert user.save, user.errors.full_messages
    user = User.new(:email => "alvaro@example.com", :account_id=>jose_account.id,:openid_url=>'http://getopenid.com/sampleid')
    assert !user.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], user.errors.on(:openid_url)
  end

end
