class PublicController < ApplicationController
  session :off, :except => %w(login signup)

  skip_before_filter :find_account
  skip_before_filter :find_user_or_guest
    
  def index    
  end
  
  def contact
  end
  
  def tour
    @current_view = @current_action
    @current_section = GastosminiUtils.normalize(params[:section])     
    unless @current_section.blank? 
      @current_view = @current_action + "_#{@current_section}"
    end
    render :action => @current_view, :layout => true
  end
  
  def help
    @current_view = @current_action
    @current_section = GastosminiUtils.normalize(params[:section])     
    unless @current_section.blank? 
      @current_view = @current_action + "_#{@current_section}"
    end
    render :action => @current_view, :layout => true
  end

  def image
    send_hot_editable_media('images')
  end

  def video
    send_hot_editable_media('videos')
  end
  
  def send_hot_editable_media(kind)
    if params[:filename].blank?
      render :nothing => true
    else
      # We are going to access the disk, so be extra-careful with the parameter.
      # Rails unescapes %XXs, but the normalizer would filter them all anyway.
      filename = GastosminiUtils.normalize_filename(File.basename(params[:filename]))
      begin
        send_file("#{RAILS_ROOT}/app/hot_editable/#{kind}/#{filename}", :disposition => 'inline')
      rescue
        # this is raised if you try to access a non-existing filename
        logger.info("we received a request for the invalid #{kind.singularize} '#{params[:filename]}'")
        render :nothing => true
      end
    end    
  end
  private :send_hot_editable_media
 
  def login
    unless (request.get? && params[:open_id_complete].nil?)      
      if using_open_id?
        authenticate_with_open_id do |result, identity_url|
          if result.successful?
            u = User.find_by_openid_url(identity_url) rescue nil
            if u.nil?
              flash.now[:notice] = "Por favor revise los datos de acceso."
            else
              u.account.update_attribute(:direct_login, true)
              redirect_to_url "http://#{u.account.short_name}.#{account_domain}"
            end
          else
            logger.warn("invalid openid access request. Message: #{result.message}")
            flash.now[:notice] = "Por favor revise los datos de acceso."            
          end
        end
      else
        User.find(:all, params[:login]).each do |u|
          if User.authenticate(u.account, params[:login], params[:password])
            u.account.update_attribute(:direct_login, true)
            redirect_to_url "http://#{u.account.short_name}.#{account_domain}" and return
          end
        end
        flash.now[:notice] = "Por favor revise los datos de acceso."        
      end
    end
  end

  def accounts_reminder
    begin
      users = User.find_all_by_email(params[:email])
      unless users.empty?
        urls = users.map {|u| "http://#{u.account.short_name}.#{account_domain}"}
        Mailer.deliver_accounts_reminder(params[:email], urls)
      end
    rescue Exception => e
      # do nothing for the view, just log it, otherwise people may figure out our accounts
      logger.info("accounts reminder raised an exception for email '#{params[:email]}'")
      logger.info(e.backtrace.join("\n"))
    end
    redirect_to :action => 'index'
  end
  verify :only => :accounts_reminder, :method => :post, :redirect_to => {:action => 'index'}
  
  # We use an explicit account owner because account.owner is only assigned
  # if both objects are valid, and thus we couldn't get to it if validation
  # fails.
  def signup
    if request.get? && params[:open_id_complete].nil?      
      @account = Account.new
      @account_owner = User.new
    else
      create_account
    end
  end
  
  def create_account
    if params[:open_id_complete].nil?
      params[:account][:short_name] = GastosminiUtils.normalize_for_url_id(params[:account][:short_name])
      @account = Account.new(params[:account])
      @account_owner = User.new(params[:account_owner])
      @account.users << @account_owner
      session[:account] = @account
      session[:account_owner] = @account_owner
      session[:openid_url] = params[:account_owner][:openid_url]
    else
      @account = session[:account]
      @account_owner = session[:account_owner]
    end

    v1 = @account_owner.valid?
    v2 = @account.valid?
    
    if params[:accept_terms_of_service].nil? && params[:open_id_complete].nil?
      @account.errors.add(:accept_terms_of_service, 'Has de aceptar las condiciones de uso')
      v2 = false
    end      
    
    if v1 && v2 # we do it this way to ensure all validations are run
      if using_open_id?(session[:openid_url])
        begin
          authenticate_with_open_id(session[:openid_url]) do |result, identity_url|
            if result.successful?
              # We reassign the openid_url to get it normalized, otherwise login may have some troubles
              @account_owner.openid_url = identity_url
              if create_user_and_mail
                redirect_to_url "http://#{@account.short_name}.#{account_domain}"
              end
            else
              logger.warn("invalid openid access request. Message: #{result.message}")
              @account_owner.errors.add(:openid_url, 'URL OpenID no válida')              
            end
          end
        rescue  OpenIdAuthentication::InvalidOpenId
          logger.warn("invalid openid access request. URL: #{session[:openid_url]}")
          @account_owner.errors.add(:openid_url, 'URL OpenID no válida')
        end
      else
        if create_user_and_mail
          redirect_to_url "http://#{@account.short_name}.#{account_domain}"
        end
      end
    end
  end
  private :create_account

  def create_user_and_mail  
    @account.direct_login = true
    @account.save
    @account_owner.account = @account
    @account.owner = @account_owner
    @account.save
    session[:account] = nil
    session[:account_owner] = nil
    session[:openid_url] = nil
    begin
      Mailer.deliver_welcome(@account, "http://#{@account.short_name}.#{account_domain}")
      devalert("Nueva cuenta", <<-BODY, CONTACT_EMAIL_ACCOUNTS)
Nueva alta en gastosmini:

Nombre:  #{@account.name}
Alias:   #{@account.short_name}
Email:   #{@account_owner.email}

Esta es el alta número #{Account.count}.
      BODY
    rescue Exception => e
      logger.error(e.inspect)
      return false
    end
    return true
  end
  private :create_user_and_mail
  
  # Called by the post-commit hook of the repository gastosmini_hot_editable,
  # via wget.
  def __update_hot_editable
    #raise ActionController::UnknownAction unless request.put?
    @ip = request.remote_ip
    msg = "updating hot_editable from IP #@ip"
    logger.info(msg)
    Dir.chdir("#{RAILS_ROOT}/app/hot_editable") do
      @svn = `svn up`
    end
    devalert("hot editable update", msg + "\n\n" + @svn)
    render :action => '__update_hot_editable', :layout => false
  end
  
  def terms_of_service
    render :action => 'terms_of_service', :layout => false
  end
  
  # This method is not used currently.
  def suggest_short_name
    suggestion = GastosminiUtils.normalize_for_url_id(params[:name])
    # some from http://www.rmc.es/Scripts/Usr/icorporativa/infosolici.asp?idioma=Espa%F1ol&op=17
    suggestion.sub!(/-s(a|l|rl|c|rc|al|ll|i|icav|ii)$/, '')
    suggestion.gsub!(/\b(.)[^-]*-/, '\1') # in case the name is multi-word we take the first letters of initial words
    while Account.find_by_short_name(suggestion) || CONFIG['reserved_subdomains'].include?(suggestion)
      suggestion.sub!(/(\D)$/, "\\11")
      suggestion.isucc!
    end
    render :update do |page|
      page << "$('account_short_name').value = '#{suggestion}';"
      page << "$('account_short_name').onchange();"
      page << "$('account_owner_email').focus();"
    end
  end
  xhr_only :suggest_short_name
  
  def check_availability_of_short_name
    sn = GastosminiUtils.normalize_for_url_id(params[:short_name])
    available = '<em style="color: #0FC10B">(disponible)<em>'
    if sn.blank? || Account.find_by_short_name(sn) || CONFIG['reserved_subdomains'].include?(sn)
      available = '<span class="error">(no disponible)</span>'
    elsif sn != params[:short_name]
      available = %Q{<em style="color: #0FC10B">(disponible como "#{sn}")<em>}
    end
    render :update do |page|
      page.replace_html 'available', available
    end
  end
  
  #To check Exception Notifier
  def error  
    raise RuntimeError, "Generating an error"  
  end 
  
end
