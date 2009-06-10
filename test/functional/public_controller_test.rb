require File.dirname(__FILE__) + '/../test_helper'
require 'public_controller'

# Re-raise errors caught by the controller.
class PublicController
  
  def rescue_action(e) raise e end; 
  def using_open_id?(identity_url = params[:openid_url])
    return identity_url      
  end    
end

class PublicControllerTest < Test::Unit::TestCase
  fixtures :users, :accounts
    
  def setup
    @controller = PublicController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
    
    ActionMailer::Base.delivery_method = :test
  end

  def test_index
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_login
    jose = users(:jose)
    post :login, :login => jose.email, :password => "abracadabra"
    assert_redirected_to "expenses/index"
  end
  
  def test_error_in_login
    jose = users(:jose)
    post :login, :login => jose.email, :password => '_bracadabra'
    assert_template 'login'    
  end
  
  def test_access_signup
    get :signup
    assert_response :success
    assert_template "signup"
  end
  
  def test_make_signup
    post :signup, :account => {:name => 'foo', :short_name => 'foo'}, 
      :account_owner => {:email => 'foo@example.com',:email_confirmation => 'foo@example.com',
                         :password => 'abracadabra',:password_confirmation => 'abracadabra'}, 
      :accept_terms_of_service => 'on'
    
    assert_redirected_to "http://foo.#{DOMAIN_NAME}"
  end
  
  def test_error_in_signup
    post :signup, :account => {:name => 'foo', :short_name => 'foo'}, 
      :account_owner => {:email => 'foo@example.com',:email_confirmation => 'other@example.com',
                         :password => 'abracadabra',:password_confirmation => 'abracadabra'}, 
      :accept_terms_of_service => 'on'
    
    assert assigns["account_owner"].errors.invalid?(:email)
    assert_template "signup"    
  end  

end
