require File.dirname(__FILE__) + '/../test_helper'
require 'expenses_controller'

# Re-raise errors caught by the controller.
# Re-raise errors caught by the controller.
class ExpensesController  
  def rescue_action(e) raise e end; 
  def using_open_id?(identity_url = params[:openid_url])
    return identity_url      
  end    
end

class ExpensesControllerTest < Test::Unit::TestCase
  fixtures :users,:accounts,:projects,:expenses,:expense_types,:login_tokens
  REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

  def setup
    @controller = ExpensesController.new
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
  
  def test_of    
   @request.reset_session
   @request.session[:guest] = {
              :account  => accounts(:jose).id,
              :project => Project.find(login_tokens(:token_2).project_id)
            }    
    get :of, :id => 'especial'
    assert_response :success
    assert_template 'list'    
  end
  
  def test_of_type
    @request.reset_session
    @request.session[:guest] = {
              :account  => accounts(:jose).id,
              :project => Project.find(login_tokens(:token_2).project_id)
            }    
    get :of_type, :id => 'transporte'
    assert_response :success
    assert_template 'list'    
  end
  
  def test_filtered
    date_from = 5.days.ago
    date_to = 1.days.ago
    expense_count = Expense.find(:all,:conditions => "date >= '#{date_from.strftime("%Y-%m-%d")}' and date <= '#{date_to.strftime("%Y-%m-%d")}'").length
    post :filtered, :expense_date_from => 1,:date_from => date_from.strftime('%d/%m/%Y'),:expense_date_to => 1,:date_to => date_to.strftime('%d/%m/%Y')
    expense_pages, expenses, total = check_attrs(%w(expense_pages expenses total))
    assert_equal expense_count, expenses.length, "Number of Expenses should be the same" 
    assert_response :success    
    assert_template 'filtered' 
  end
  
  def test_create
    expense_count = Expense.find(:all).length
    post :create, :expense => {:concept => "De BCN a Madrid", :date => Time.now.strftime('%d/%m/%Y'), 
      :notes => "Caro", :amount => 120.0, 
      :envelope => "N1", :project_id => 1, :expense_type_id => 1}
    expense = check_attrs(%w(expense))
    assert_response :success    
    assert_template 'create'
    assert_equal expense_count + 1, Expense.find(:all).length, "Expected an additional Expense"
  end  
    
  def test_destroy
    expense_count = Expense.find(:all).length
    @request.env["HTTP_REFERER"] = '/expenses/list'
    post :destroy, :id => expenses(:parking).url_id
    assert_response :redirect
    assert_redirected_to 'expenses/list'   
    assert_equal expense_count - 1, Expense.find(:all).length, "Number of Expense should be one less"    
  end
  
  def test_add_copying
    post :add, :id => 1, :from => 'copying'
    expense = check_attrs(%w(expense))
    assert_response :success    
    assert_template 'add'    
  end
  
  def test_add_without_copying
    post :add
    expense = check_attrs(%w(expense))
    assert_response :success    
    assert_template 'add'    
  end
  
  def test_edit
    xhr :get, :edit, :id => expenses(:parking).id
    assert_response :success    
    assert_template 'edit'    
  end
  
  def test_import
    xhr :get, :import
    assert_response :success    
    assert_template 'import'    
  end
  
  def test_import_csv
    expense_count = Expense.find(:all).length
    post :import_csv, :csv => fixture_file_upload("import/example.csv" , "text/csv" )
    assert_response :success    
    assert_template 'import_csv'    
    assert_not_equal expense_count, Expense.find(:all).length, "Number of Expenses should be higher"    
  end
  
  def test_modify
    expense_count = Expense.find(:all).length
    parking_expense = expenses(:parking)
    new_attributes = {:notes => "Más de tres horas", :envelope => "N2"}
    xhr :post, :modify, :id => parking_expense.id,:expense => parking_expense.attributes.merge(new_attributes)
    assert_response :success
    assert_template "modify"
    
    parking_expense = expenses(:parking)
    new_attributes.each do |attr_name|
      assert_equal new_attributes[attr_name], parking_expense.attributes[attr_name], "@expense.#{attr_name.to_s} incorrect"
    end
    assert_equal expense_count, Expense.find(:all).length, "Number of Expense should be the same"    
  end
  
  def test_export
    @request.env['HTTP_USER_AGENT']= 'Windows'
    post :export, :format => 'csv'
    reader = CSV::Reader.create(@response.body)
    header = reader.shift
    ["Categoria","Fecha","Tipo de gasto","Concepto","Importe","Comentarios","Sobre"].each do |attribute|
      assert header[0].include?(attribute)
    end
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
