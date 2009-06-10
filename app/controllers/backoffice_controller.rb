class BackofficeController < ApplicationController

  skip_before_filter :find_account  
  skip_before_filter :find_user_or_guest

  before_filter :ensure_user_is_root, :except => :login

  def login
    if request.post?
      if params[:login] == CONFIG['root_login'] && params[:password] == CONFIG['root_password']
        session[:root] = true
        redirect_to :action => 'index'
        return
      else
        flash.now[:notice] = "Por favor revise los datos de acceso."
      end
    end
    render :action => 'login', :layout => 'public'
  end
  
  def logout
    reset_session
    redirect_to :controller => 'public'
  end
  
  def index
    @naccounts                   = Account.count
    @nexpenses                   = Expense.count
    @nprojects                   = Project.count
    @most_recent_accounts        = Account.find(:all, :order => 'created_at DESC', :limit => 10)
    @nlast_seen_accounts         = User.count(:conditions => ["last_seen_at > ?", 1.month.ago])
    @nlast_registered_accounts   = Account.count(:conditions => ["created_at > ?", 1.month.ago])
    @naccounts_with_some_expenses = Expense.connection.select_value(<<-SQL).to_i
      SELECT COUNT(*) FROM (
        SELECT COUNT(id) FROM expenses
        GROUP BY account_id HAVING COUNT(id) >= 10
      ) as expense_counters_per_account
    SQL
  end
  
  def accounts
    @current_order_by  = order_by(6, 3)
    @current_direction = direction('DESC')
    
    page_params = [
      { :order => "accounts.name_for_sorting #@current_direction" },
      { :order => "users.email #@current_direction" },
      { :order => "accounts.created_at #@current_direction" },
      { :order => "users.last_seen_at #@current_direction" }
    ]
    
    if @current_order_by < page_params.length && page_params[@current_order_by]
      @account_pages, @accounts = paginate(
        :accounts, {
          :per_page => CONFIG['pagination_window'],
          :include  => :owner
        }.merge(page_params[@current_order_by])
      )
    else
      select = 'accounts.id, accounts.name, accounts.created_at, accounts.owner_id, accounts.short_name'
      @account_pages = Paginator.new(self, Account.count, CONFIG['pagination_window'], params[:page])
      
      if @current_order_by == page_params.length # expenses
        @accounts = Account.find_by_sql(<<-SQL)
          SELECT #{select} FROM accounts 
          LEFT OUTER JOIN (
            SELECT account_id, COUNT(id) as nexpenses FROM expenses GROUP BY account_id
          ) as expense_counters
          ON accounts.id = expense_counters.account_id
          ORDER BY expense_counters.nexpenses #{@current_direction}
          LIMIT #{@account_pages.items_per_page}
          OFFSET #{@account_pages.current.offset}
        SQL
      elsif @current_order_by == page_params.length + 1 # projects
        @accounts = Account.find_by_sql(<<-SQL)
          SELECT #{select} FROM accounts 
          LEFT OUTER JOIN (
            SELECT account_id, COUNT(id) as nprojects FROM projects GROUP BY account_id
          ) as project_counters
          ON accounts.id = project_counters.account_id
          ORDER BY project_counters.nprojects #{@current_direction}
          LIMIT #{@account_pages.items_per_page}
          OFFSET #{@account_pages.current.offset}
        SQL
      end
    end
    render :partial => 'list' if request.xhr?
  end
  
  def ensure_user_is_root
    if session[:root]
      return true
    else
      redirect_to :action => 'login'
      return false
    end
  end
  private :ensure_user_is_root
  
  #this_controller_only_responds_to_https
end
