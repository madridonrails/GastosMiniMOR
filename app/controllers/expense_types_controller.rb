class ExpenseTypesController < ApplicationController
  include LoginUrlHelper
  
  before_filter :ensure_can_write, :except => [:index, :list, :show]
  before_filter :ensure_can_read_all, :only => [:index, :list]
  before_filter :find_expense_type, :except => [:list, :new, :create_for_expense]
  before_filter :calculate_total_expenses, :except => [:create, :destroy]
  
  def index
    redirect_to :action => 'list'
  end
  
  # Expense Types listing.
  def list
    @current_order_by  = order_by(1, 0)
    @current_direction = direction()
    page_params = [
      { :order => "name_for_sorting #@current_direction" }
    ]
    @expense_type_pages, @expense_types = paginate(
      :expense_types, {
        :per_page   => CONFIG['pagination_window'],
        :conditions => "account_id = #{@current_account.id}"
      }.merge(page_params[@current_order_by])
    )
    render :partial => 'list' if request.xhr?
  end
  
  # Expense Type details.
  def show
    return logout unless can_read_all?
  end
  
  # This is the action that gets called from the redbox in the
  # expense form.
  def create_for_expense
    @expense_type = @current_account.expense_types.build(params[:expense_type])
    if @expense_type.save
      # To display this expense type on the left header reusing partials.
      @expense = Expense.new
      @expense.expense_type = @expense_type
    end
  end
  xhr_only :create_for_expense

  # Expense Type creation, GET and POST. Note that expense type creation from
  # the expense redbox is handled by create_for_expense.
  def new
    if request.get?
      @expense_type = @current_account.expense_types.build
    else
      @expense_type = @current_account.expense_types.build(params[:expense_type])
      redirect_to :action => 'list' if @expense_type.save
    end
  end
  
  # Expense Type edition, GET and POST.
  def edit
    return if request.get?
    @expense_type.attributes = params[:expense_type]
    ExpenseType.transaction do
      @expense_type.save!
      redirect_to :action => 'show', :id => @expense_type
    end rescue nil
  end
  
  def destroy
    if request.post? && @expense_type.can_be_destroyed?
      @expense_type.destroy
      redirect_to :action => 'list'
    else
      redirect_to :action => 'show', :id => @expense_type
    end
  end
  
  def find_expense_type
    expense_type = nil
    unless params[:id].blank?
      expense_type = @current_account.expense_types.find_by_url_id(params[:id])
    end
    if expense_type.nil?
      redirect_to :action => 'list'
      return false
    end
    @expense_type = expense_type
  end
  protected :find_expense_type

end
