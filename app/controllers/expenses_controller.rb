require 'set'
require 'fastercsv'
require 'iconv'
require 'spreadsheet/excel'

class ExpensesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include FormatterHelper
  include ExpensesHelper

  before_filter :ensure_can_write, :except => [:index, :of, :of_type, :list, :pending, :show, :export, :show_filter,:hide_filter,:filtered]
  before_filter :find_expense, :only => [:show, :edit, :cancel_edit, :modify, :copy, :destroy, :update_account]
  
  CSV_HEADERS = ['fecha', 'concepto', 'importe', 'sobre', 'tipo', 'categoria']

  def index
    redirect_to :action => 'list'
  end

  def list
    @submit = 'create'
    @cancel = 'cancel_add'
    
    if can_read_all?
      @expense_pages, @expenses = paginator("expenses.account_id = #{@current_account.id}")
      @total = total("expenses.account_id = #{@current_account.id}")
      @expense = @current_account.expenses.build
      respond_to do |format|
        format.html { render :action => 'list' }
        format.js   { render :partial => 'list' }
      end
    else
      redirect_to :action => 'of', :id => @guest[:project]
      return
    end
  end

  def of
    @project = @current_account.projects.find_by_url_id(params[:id])
    return logout unless can_read_project?(@project)
    @expense_pages, @expenses = paginator("expenses.project_id = #{@project.id}")
    @total = total("expenses.project_id = #{@project.id}")
    @expense = @current_account.expenses.build
    params[:project_id] = @project.id.to_s
    @current_project = @project
    respond_to do |format|
      format.html { render :action => 'list' }
      format.js   { render :partial => 'list' }
    end
  end

  def of_type
    @expense_type = @current_account.expense_types.find_by_url_id(params[:id])
    conditions = can_read_all? ? "expenses.account_id = #{@current_account.id}" : "expenses.project_id = #{@guest[:project].id}"
    conditions << " AND expenses.expense_type_id = #{@expense_type.id}"
    @expense_pages, @expenses = paginator(conditions)
    @total = total(conditions)
    @expense = @current_account.expenses.build
    params[:expense_type_id] = @expense_type.id.to_s
    @current_expense_type = @expense_type
    respond_to do |format|
      format.html { render :action => 'list' }
      format.js   { render :partial => 'list' }
    end
  end

  def filtered
    str_conditions = "expenses.account_id = :account_id"
    hs_conditions_params = { :account_id => @current_account.id }
    
    
    if params[:expense_date_from] && params[:date_from]
      aux_time = GastosminiUtils.parse_date(params[:date_from])
      if aux_time
        str_conditions << ' AND expenses.date >= :date_from'
        hs_conditions_params[:date_from] = aux_time.strftime("%Y-%m-%d")
      end
    end
    if params[:date_to] && params[:date_to]
      aux_time = GastosminiUtils.parse_date(params[:date_to])
      if aux_time
        str_conditions << ' AND expenses.date <= :date_to'
        hs_conditions_params[:date_to] = aux_time.strftime("%Y-%m-%d")
      end
    end
    unless params[:concept].blank? || params[:concept] == 'all'
      str_conditions << ' AND UPPER(expenses.concept) LIKE :concept'
      hs_conditions_params[:concept] = "%#{params[:concept].upcase}%"
    end
    unless params[:expense_type_id].blank? || params[:expense_type_id] == 'all'
      str_conditions << ' AND expenses.expense_type_id = :expense_type_id'
      hs_conditions_params[:expense_type_id] = params[:expense_type_id]
    end
    unless params[:project_id].blank? || params[:project_id] == 'all'
      str_conditions << ' AND expenses.project_id = :project_id'
      hs_conditions_params[:project_id] = params[:project_id]
    end
    unless params[:envelope].blank? || params[:envelope] == 'all'
      if params[:envelope] == 'none'
        str_conditions << " AND expenses.envelope = ''"
      else
        str_conditions << ' AND UPPER(expenses.envelope) LIKE :envelope'
        hs_conditions_params[:envelope] = "%#{params[:envelope].upcase}%"
      end
    end
    @filtered = hs_conditions_params.size > 1
    @expense_pages, @expenses = paginator([str_conditions, hs_conditions_params])
    @total = total([str_conditions, hs_conditions_params])
    @expense = @current_account.expenses.build
    
    render :partial => 'list' unless params[:page].blank?
  end

  def paginator(conditions)
    @current_order_by  = order_by(7, 0)
    @current_direction = direction('DESC')
    
    page_params = [
      { :order => "expenses.date #@current_direction" },
      { :order => "projects.name_for_sorting #@current_direction" },
      { :order => "expense_types.name_for_sorting #@current_direction" },
      { :order => "expenses.concept_for_sorting #@current_direction" },
      { :order => "expenses.envelope_for_sorting #@current_direction" },
      { :order => "expenses.amount #@current_direction" },
      nil,
      nil
    ]
    paginate(
      :expenses, {
        :include    => [:project, :expense_type],
        :per_page   => CONFIG['pagination_window'],
        :conditions => conditions
      }.merge(page_params[@current_order_by])
    )
  end
  private :paginator

  def create
    @expense = @current_account.expenses.build(params[:expense])

    if @expense.save
      url_params = {:action => 'list'}
      if params[:from] && params[:from_id]
        if params[:from] == 'project'
          url_params = {:action => 'of', :id => params[:from_id]}
        elsif params[:from] == 'type'
          url_params = {:action => 'of_type', :id => params[:from_id]}
        end
      end
      @url = url_for url_params
    end
  end
  verify :only => :create, :method => :post, :redirect_to => {:action => 'list'}

  def new
    @expense = @current_account.expenses.build
    @expense.date = Date.today
    @expense.project = @current_account.default_project
    @expense.expense_type = @current_account.default_expense_type
    if params[:from] && params[:id]
      if params[:from] == 'project'
        new_for_project
      elsif params[:from] == 'type'
        new_for_expense_type
      end
    end
    set_formatters
    @submit = 'create'
    @cancel = 'cancel_new'
  end

  def new_for_project
    project = @current_account.projects.find_by_url_id(params[:id])
    @expense.project = project if project
  end
  private :new_for_project

  def new_for_expense_type
    expense_type = @current_account.expense_types.find_by_url_id(params[:id])
    @expense.expense_type = expense_type if expense_type
  end
  private :new_for_expense_type

  def destroy
    @expense.destroy
    redirect_to :back
  end
  verify :only => :destroy, :method => :post, :redirect_to => {:action => 'list'}

  def find_expense
    @expense = @current_account.expenses.find(params[:id])
    unless @expense
      redirect_to :action => 'list'
      return false
    end
  end
  private :find_expense

  def commify(n)
    n.to_s.tr('.', ',')
  end
  private :commify

  def export
    return if request.get?
    period_conditions = case params[:period]
      when 'dates'
        date_from = params[:start_date]
        date_to   = params[:end_date]
        {:date => date_from..date_to}
      else
        {}
    end
    
    project_conditions = if can_read_all?
      # we do not need to check project_id against injection because we constrain afterwards
      params[:project_id].blank? ? {} : {:project_id => params[:project_id].to_i}
    else
      {:project_id => @guest[:project].id}
    end
    
    format = params[:format]
    
    conditions = period_conditions.merge(project_conditions)
    conditions = nil if conditions.blank? # an empty hash gives invalid SQL
    expenses = @current_account.expenses.find(:all, :conditions => conditions)
    
    # These charsets are expected to be common in our users.
    charset = (request_from_a_mac? ? "MacRoman" : "ISO-8859-1")
    @norm = lambda {|str| Iconv.conv("#{charset}//IGNORE", "UTF-8", str)}
    
    col_sep = ';'                                     # Excel understands this one automatically
    row_sep = (request_from_windows? ? "\r\n" : "\n") # in case people treat it as a text file
    
    if format == 'xls'
      tmp = Tempfile.new(@current_account.id)
      workbook = Spreadsheet::Excel.new(tmp.path)   
      worksheet = workbook.add_worksheet('Listado')
      format_row = Format.new(:size=>11)
      worksheet.write_row(0, 0, export_header)
      index = 1

      expenses.sort.each_with_index {|e, i|
        worksheet.write_row(index, 0, export_row(e), format_row)
        index += 1
      }
      
      workbook.close
      send_data(tmp.read, :type => "application/vnd.ms-excel", :filename => "export_gastos_#{@current_account.short_name}.xls", :disposition => 'inline')
    else
      csv_string = FasterCSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
        csv << export_header
        expenses.sort.each do |e|
          csv << export_row(e)
        end
      end
      send_data(csv_string, :type => "text/csv; charset=#{charset}", :filename => "export_gastos_#{@current_account.short_name}.csv")
    end
  end

  def export_header
    ['ID', 'Categoria', 'Fecha', 'Tipo de gasto', 'Concepto', 'Importe', 'Comentarios', 'Sobre'].map {|h| @norm.call(h)}
  end
  private :export_header
  
  def export_row(e)
    [e.id, @norm.call(e.project.name), format_date(e.date), @norm.call(e.expense_type.name), @norm.call(e.concept), commify(e.amount), @norm.call(e.notes), @norm.call(e.envelope)]
  end
  private :export_row

  # ---------------------------------------------------- #
  #                                                      #
  #  Remote methods to support expense creation/edition  #
  #                                                      #
  # ---------------------------------------------------- #

  def parse_decimal(f)
    GastosminiUtils.parse_decimal(f)
  end
  private :parse_decimal

  def update_account
    @expense.account = @current_account
  end
  xhr_only :update_logo

  def update_project
    id = params[:expense][:project_id]
    unless id.blank?
      begin
        @project = @current_account.projects.find(id)
      rescue
        # this is not fatal, perhaps it was deleted in the meantime in another
        # parallel session, perhaps the user is trying to obtain information
        # about projects of other accounts, just let the view handle this case.
        # TODO: possibly rebuild the combo
      end
    end
  end
  xhr_only :update_project

  def update_expense_type
    id = params[:expense][:expense_type_id]
    unless id.blank?
      begin
        @expense_type = @current_account.expense_types.find(id)
      rescue
        # this is not fatal, perhaps it was deleted in the meantime in another
        # parallel session, perhaps the user is trying to obtain information
        # about projects of other accounts, just let the view handle this case.
        # TODO: possibly rebuild the combo
      end
    end
  end
  xhr_only :update_expense_type

  def cancel_new
    url_params = {:action => 'list'}
    if params[:from]
      if params[:from] == 'project'
        url_params.merge!(:controller => 'projects')
      elsif params[:from] == 'type'
        url_params.merge!(:controller => 'expense_types')
      end
    end
    render :update do |page| 
      page.redirect_to url_for(url_params)
    end
  end
  xhr_only :cancel_new

  def add
    if params[:from] && params[:id] && params[:from] == 'copying'
      add_copying_expense
      @copying = true
    else
      @expense = @current_account.expenses.build
      @expense.date = Date.today
      @expense.project = @current_account.default_project
      @expense.expense_type = @current_account.default_expense_type
      @copying = false
    end
    set_formatters
    @submit = 'create'
    @cancel = 'cancel_add'
  end

  def add_copying_expense
    expense_to_copy = @current_account.expenses.find(params[:id])
    if expense_to_copy
      @expense = expense_to_copy.dup
    end
  end
  private :add_copying_expense

  def cancel_add
  end
  xhr_only :cancel_add

  def edit
    set_formatters
    @submit = 'modify'
    @cancel = 'cancel_edit'
  end
  xhr_only :edit

  def cancel_edit
  end
  xhr_only :cancel_edit

  def modify
    return unless request.post?
    begin
      Expense.transaction do
        @expense.account = @current_account unless params[:update_account].blank?
        if params[:expense][:project_id].blank?
          # a blank means the current project is OK
          params[:expense].delete(:project_id)
        else
          # otherwise we need to reassign, in the case the ID is the same as
          # the ID of the current associated project that means a reload of
          # its data. That updates the data if the project's card has been
          # updated after its assignment to this expense.
          @expense.project = @current_account.projects.find(params[:expense][:project_id])
        end
        if params[:expense][:expense_type_id].blank?
          # a blank means the current expense type is OK
          params[:expense].delete(:expense_type_id)
        else
          # otherwise we need to reassign, in the case the ID is the same as
          # the ID of the current associated expense type that means a reload of
          # its data. That updates the data if the type's card has been
          # updated after its assignment to this expense.
          @expense.expense_type = @current_account.expense_types.find(params[:expense][:expense_type_id])
        end
        @expense.update_attributes!(params[:expense])
      end
    rescue
    end
  end
  xhr_only :modify
  
  # Set the formatters Procs for views.
  def set_formatters(options={})
    @amounts_formatter = lambda {|x| format_integer(x, options)}
  end
  private :set_formatters

  #Expenses import
  def import
    # expense instance to store errors for all lines and show them on the view
    @expense = Expense.new
  end
  xhr_only :import
  
  def cancel_import
  end
  xhr_only :cancel_import

  def import_csv
    return unless request.post?
    @successful = true
    imported_ids = []
    # expense instance to store errors for all lines and show them on the view
    @expense = Expense.new
    file = params['csv'] rescue nil
    line = 1
    if !file.blank? && file.size > 0
      if file.original_filename =~ /\.csv\z/
        begin
          #we need to convert categoría with an accent to without
          #since not sure about client's encoding we will sub categor with categoria
          #we can receive the name with single, double or without quotes so we
          #try to perform the 3 subs. 
          raw_content=file.read    
          convert_content = raw_content.downcase
        
          if !convert_content.sub!(/'categor[^\s]*/,"'categoria'") #single quoted  
            if !convert_content.sub!(/"categor[^\s]*/,'"categoria"') #double quouted
              convert_content.sub!(/categor[^\s]*/,"categoria") #unquoted
            end
          end
        
          input = FasterCSV.parse(convert_content, {:col_sep => ',', 
                                              :headers => true,
                                              :header_converters => :downcase})
          if input.headers == CSV_HEADERS
            ActiveRecord::Base.transaction do
              input.each do |row|
                @expense_successful = true
                unless row.blank?
                  if import_expense row, line
                    logger.debug @imported_expense.valid?
                    logger.debug @imported_expense.errors.inspect
                    @expense_successful =  @imported_expense.save!
                    imported_ids << @imported_expense.id
                  end
                  logger.debug("Expense import #{@expense_successful} línea #{line}")
                  @successful = false unless @expense_successful
                end
                line += 1
              end
              raise unless @successful
            end
          else
            @successful = false
            logger.debug("Las cabeceras del fichero no son correctas.")
            @expense.errors.add_to_base("Las cabeceras del fichero no son correctas. Han de ser #{CSV_HEADERS.join(', ')}")
          end
        rescue ActiveRecord::RecordInvalid
          @successful = false
          logger.debug("Línea #{line}. Error.")
          @expense.errors.add_to_base("Línea #{line}. Error.")
        rescue
          @successful = false
          logger.debug("Línea #{line}. #{$!.to_s}") if !($!.to_s.blank?)   
          @expense.errors.add_to_base("Línea #{line}. #{$!.to_s}") if !($!.to_s.blank?)        
        end
      else
        @successful = false
        logger.debug("Fichero no csv. #{file.original_filename}")
        @expense.errors.add_to_base("Formato de fichero no válido. Ha de tener la extensión csv.")
      end
    else
      @successful = false
      logger.debug("El fichero es un campo obligatorio")
      @expense.errors.add_to_base('El fichero es un campo obligatorio')
    end

    # Since file was uploaded through an iframe, we must return the answer to its parent
    responds_to_parent do
      render :action => 'import_csv'
    end
  end

  def import_expense(row, line)
    @imported_expense = @current_account.expenses.build
    @imported_expense.date = GastosminiUtils.parse_csv_date(row['fecha'].strip) rescue nil
    if @imported_expense.date.nil?
      @expense.errors.add_to_base("Línea #{line}. La fecha [#{row['fecha']}] no es válida.")
      @expense_successful = false
    end
    @imported_expense.concept = row['concepto'].strip rescue nil
    if @imported_expense.concept.nil?
      @expense.errors.add_to_base("Línea #{line}. El concepto [#{row['concept']}] no es válido.")
      @expense_successful = false
    end
    @imported_expense.amount = GastosminiUtils.parse_decimal(row['importe'].strip) rescue nil
    if @imported_expense.amount.nil?
      @expense.errors.add_to_base("Línea #{line}. El importe [#{row['importe']}] no es válido.")
      @expense_successful = false
    end
    @imported_expense.envelope = row['sobre'].strip rescue ''
    @imported_expense.expense_type = @current_account.expense_types.find_by_name(row['tipo'].strip) rescue nil
    if @imported_expense.expense_type.nil?
      @expense.errors.add_to_base("Línea #{line}. No se encuentra el tipo de gastos [#{row['tipo']}] en la aplicación.")
      @expense_successful = false
    end
    @imported_expense.project = @current_account.projects.find_by_name(row['categoria'].strip) rescue nil
    if @imported_expense.project.nil?
      @expense.errors.add_to_base("Línea #{line}. No se encuentra la categoría [#{row['categoria']}] en la aplicación.")
      @expense_successful = false
    end
    @expense_successful
  end
  private :import_expense
  
  #Expenses filter
  def show_filter
  end
  xhr_only :show_filter
    
  def hide_filter
  end
  xhr_only :hide_filter

end
