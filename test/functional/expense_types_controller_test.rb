require File.dirname(__FILE__) + '/../test_helper'
require 'expense_types_controller'

# Re-raise errors caught by the controller.
class ExpenseTypesController  
  def rescue_action(e) raise e end; 
  def using_open_id?(identity_url = params[:openid_url])
    return identity_url      
  end    
end

class ExpenseTypesControllerTest < Test::Unit::TestCase
  fixtures :users,:accounts,:projects,:expenses,:expense_types
  REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect
  
  def setup
    @controller = ExpenseTypesController.new
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
  
  def test_list
    get :list
    assert_response :success
    assert_template 'list'    
  end
  
  def test_show
    get :show, :id => expense_types(:transporte).url_id
    assert_response :success
    assert_template 'show'    
  end
  
  def test_new
    expense_types_count = ExpenseType.find(:all).length
    post :new, :expense_type => {:name => "trajes"}
    expense_type = check_attrs(%w(expense_type))
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    assert_equal expense_types_count + 1, ExpenseType.find(:all).length, "Expected an additional Expense Type"
  end
  
  def test_create_for_expense
    expense_types_count = ExpenseType.find(:all).length
    xhr :post, :create_for_expense, :expense_type => {:name => "Food"}
    expense_type,expense = check_attrs(%w(expense_type expense))
    assert_equal expense_types_count + 1, ExpenseType.find(:all).length, "Expected an additional Expense Type"
    assert_equal expense_type, expense.expense_type
  end
  
  def test_edit
    expense_types_count = ExpenseType.find(:all).length
    transporte_expense_type = expense_types(:transporte)
    new_attributes = {:name => "traslado"}
    post :edit, :id => transporte_expense_type.url_id,:expense_type => transporte_expense_type.attributes.merge(new_attributes)
    assert_response :redirect
    assert_redirected_to "expense_types/show"
    
    transporte_expense_type = expense_types(:transporte)
    new_attributes.each do |attr_name|
      assert_equal new_attributes[attr_name], transporte_expense_type.attributes[attr_name], "@expense_type.#{attr_name.to_s} incorrect"
    end
    assert_equal expense_types_count, ExpenseType.find(:all).length, "Number of Expense Types should be the same"    
  end
  
  def test_destroy
    expense_types_count = ExpenseType.find(:all).length
    post :destroy, :id => expense_types(:comida).url_id
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN   
    assert_equal expense_types_count - 1, ExpenseType.find(:all).length, "Number of Expense Types should be one less"    
  end

  protected
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
