require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController  
  def rescue_action(e) raise e end; 
  def using_open_id?(identity_url = params[:openid_url])
    return identity_url      
  end    
end

class ProjectsControllerTest < Test::Unit::TestCase  
  fixtures :users,:accounts,:projects,:login_tokens
  
  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.user_agent = 'Firefox'
    @request.host = "jose.#{DOMAIN_NAME}"
    login_as :jose
  end
  
  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to "projects/list"
  end
  def test_list
    get :list
    assert_response :success
    assert_template 'list'
    projects = check_attrs(%w(projects))
    assert_equal Project.find(:all).length, projects.length, "Incorrect number of projects shown"
  end
  def test_show
    get :show, :id => projects(:especial).url_id
    assert_response :success
    assert_template 'show'    
  end
  
  def test_new
    project_count = Project.find(:all).length
    post :new, :project => {:name => "Car", :description => "Buy car", :notes => "Lists of cars"}
    project = check_attrs(%w(project))
    assert_response :redirect
    assert_redirected_to "projects/list"
    assert_equal project_count + 1, Project.find(:all).length, "Expected an additional Project"
  end
  
  def test_create_for_expense
    project_count = Project.find(:all).length
    xhr :post, :create_for_expense, :project => {:name => "Car", :description => "Buy car", :notes => "Lists of cars"}
    project,expense = check_attrs(%w(project expense))
    assert_equal project_count + 1, Project.find(:all).length, "Expected an additional Project"
    assert_equal project, expense.project
  end
  
  def test_edit
    project_count = Project.find(:all).length
    cine_project = projects(:cine)
    new_attributes = {:name => "Cinema", :description => "Lists of fils", :notes => "Lists of cinemas and films"}
    post :edit, :id => cine_project.url_id,:project => cine_project.attributes.merge(new_attributes)
    assert_response :redirect
    assert_redirected_to "projects/show"
    
    cine_project = projects(:cine)
    new_attributes.each do |attr_name|
      assert_equal new_attributes[attr_name], cine_project.attributes[attr_name], "@project.#{attr_name.to_s} incorrect"
    end
    assert_equal project_count, Project.find(:all).length, "Number of Projects should be the same"    
  end
  
  def test_destroy
    project_count = Project.find(:all).length
    post :destroy, :id => projects(:cine).url_id
    assert_response :redirect
    assert_redirected_to "projects/list"   
    assert_equal project_count - 1, Project.find(:all).length, "Number of Projects should be one less"    
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
