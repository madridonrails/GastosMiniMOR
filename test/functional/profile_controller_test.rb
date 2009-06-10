require File.dirname(__FILE__) + '/../test_helper'
require 'profile_controller'

# Re-raise errors caught by the controller.
class ProfileController; def rescue_action(e) raise e end; end

class ProfileControllerTest < Test::Unit::TestCase
  fixtures :users,:accounts
  REDIRECT_TO_MAIN = {:action => 'show'} # put hash or string redirection that you normally expect
  
  def setup
    @controller = ProfileController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.user_agent = 'Firefox'
    @request.host = "jose.#{DOMAIN_NAME}"
    login_as :jose
  end
  
  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end
  
  def test_show
    get :show
    assert_response :success
    assert_template 'show'    
  end
  
  def test_edit
    jose_user = users(:jose)
    new_attributes = {:first_name => "José", :last_name => "Pérez Navarro"}
    post :edit, :user => jose_user.attributes.merge(new_attributes),
                :current_password => "abracadabra",
                :owner => {:email => jose_user.email, :email_confirmation => jose_user.email}
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    
    jose_user = users(:jose)
    new_attributes.each do |attr_name|
      assert_equal new_attributes[attr_name], jose_user.attributes[attr_name], "@user.#{attr_name.to_s} incorrect"
    end    
  end

  protected
  # Could be put in a Helper library and included at top of test class
  def check_attrs(attr_list)
    attrs = []
    attr_list.each do |attr_sym|
      attr = assigns(attr_sym.to_sym)
      assert_not_nil attr,       "Attribute @#{attr_sym} should not be nil"
      assert !attr.new_record?,  "Should have saved the @#{attr_sym} obj" if attr.class == ActiveRecord
      attrs << attr
    end
    attrs.length > 1 ? attrs : attrs[0]
  end
end
