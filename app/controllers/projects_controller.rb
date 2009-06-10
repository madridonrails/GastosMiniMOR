class ProjectsController < ApplicationController
  include LoginUrlHelper
  
  before_filter :ensure_can_write, :except => [:index, :list, :show]
  before_filter :ensure_can_read_all, :only => [:index, :list]
  before_filter :find_project, :except => [:list, :new, :create_for_expense]
  before_filter :calculate_total_expenses, :except => [:create_for_expense, :destroy]

  def index
    redirect_to :action => 'list'
  end
  
  # Projects listing.
  def list
    @current_order_by  = order_by(1, 0)
    @current_direction = direction()
    page_params = [
      { :order => "name_for_sorting #@current_direction" }
    ]
    @project_pages, @projects = paginate(
      :projects, {
        :per_page   => CONFIG['pagination_window'],
        :conditions => "account_id = #{@current_account.id}"
      }.merge(page_params[@current_order_by])
    )
    render :partial => 'list' if request.xhr?
  end
  
  # Project details.
  def show
    return logout unless can_read_project?(@project)
    @subject = ERB.new(CONFIG['project_login_url_mail_subject']).result(binding)
    @body    = ERB.new(CONFIG['project_login_url_mail_body']).result(binding)
  end
  
  # This is the action that gets called from the redbox in the
  # expense form.
  def create_for_expense
    @project = @current_account.projects.build(params[:project])
    if @project.save
      # To display this project on the left header reusing partials.
      @expense = Expense.new
      @expense.project = @project
    end
  end
  xhr_only :create_for_expense

  # Project creation, GET and POST. Note that project creation from
  # the expense redbox is handled by create_for_expense.
  def new
    if request.get?
      @project = @current_account.projects.build
    else
      @project = @current_account.projects.build(params[:project])
      redirect_to :action => 'list' if @project.save
    end
  end
  
  # Project edition, GET and POST.
  def edit
    return if request.get?
    @project.attributes = params[:project]
    Project.transaction do
      @project.save!
      @project.renew_login_token if params[:change_login_url_for_project] == '1'
      redirect_to :action => 'show', :id => @project
    end rescue nil
  end
  
  def destroy
    if request.post? && @project.can_be_destroyed?
      @project.destroy
      redirect_to :action => 'list'
    else
      redirect_to :action => 'show', :id => @project
    end
  end

  def find_project
    project = nil
    unless params[:id].blank?
      project = @current_account.projects.find_by_url_id(params[:id])
    end
    if project.nil?
      redirect_to :action => 'list'
      return false
    end
    @project = project
  end
  protected :find_project

end
