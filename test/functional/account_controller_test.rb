require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController  
  def rescue_action(e) raise e end; 
  def using_open_id?(identity_url = params[:openid_url])
    return identity_url      
  end    
end

class AccountControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  fixtures :users,:accounts,:chpass_tokens

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
  end

  def test_should_login_and_redirect
    @request.host = "jose.#{DOMAIN_NAME}"
    post :login, :login => 'jose@example.com', :password => 'abracadabra'
    assert_response :redirect
    assert_redirected_to 'expenses/list'
  end

  def test_should_fail_login_and_not_redirect
    @request.host = "jose.#{DOMAIN_NAME}"
    post :login, :login => 'jose@example.com', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
    assert_template 'login'
  end

  def test_should_logout
    @request.host = "jose.#{DOMAIN_NAME}"
    login_as :jose
    get :logout
    assert_nil session[:user]
    assert_response :redirect
    assert_redirected_to 'account/login'
  end

  def test_chpass
    @request.host = "jose.#{DOMAIN_NAME}"
    post :chpass, :password => 'newpassword',:password_confirmation => 'newpassword',:chpass_token => 'token'
    assert_redirected_to '/'
  end
  
  def test_should_fail_chpass
    @request.host = "jose.#{DOMAIN_NAME}"
    post :chpass, :password => 'newpassword',:password_confirmation => 'newpassword',:chpass_token => 'bad token'
    assert_response :redirect
    assert_redirected_to 'account/login'
  end
  
  
  protected
    def create_user(options = {})
      post :signup, :user => { :login => 'quire', :email => 'quire@example.com', 
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
    
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
