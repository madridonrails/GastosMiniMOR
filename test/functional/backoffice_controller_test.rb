require File.dirname(__FILE__) + '/../test_helper'
require 'backoffice_controller'

# Re-raise errors caught by the controller.
class BackofficeController  
  def rescue_action(e) raise e end; 
#  def using_open_id?(identity_url = params[:openid_url])
#    return identity_url      
#  end    
end

class BackofficeControllerTest < Test::Unit::TestCase
  fixtures :users,:accounts,:projects,:expenses,:expense_types
  REDIRECT_TO_MAIN = {:action => 'index'} # put hash or string redirection that you normally expect
  def setup
    @controller = BackofficeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
  end
  
  def test_login
    post :login, :login => CONFIG['root_login'], :password => CONFIG['root_password']
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end
  
  def test_index
    login_as_root
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_accounts
    login_as_root
    get :accounts
    assert_response :success
    assert_template 'accounts'
  end
  
  def test_logout
    login_as_root
    get :logout
    assert_response :redirect
    assert_redirected_to :controller => 'public'    
  end  
  
  protected	
  def login_as_root
    @request.session[:root] = true
  end
end
