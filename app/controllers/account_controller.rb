require 'openid'
class AccountController < ApplicationController
  include LoginUrlHelper  
  
  skip_before_filter :find_user_or_guest, :except => :logout
  
  def login
    if params[:login_token]
      reset_session
      login_token = LoginToken.find_by_token(params[:login_token])
      if login_token
        begin
          if login_token.is_a?(LoginTokenForAgencies) && login_token.account == @current_account
            session[:guest] = {
              :account  => @current_account.id,
              :project => nil
            }
            redirect_to :controller => 'expenses', :action => 'list'
          elsif login_token.is_a?(LoginTokenForProject) && login_token.project.account == @current_account
            session[:guest] = {
              :account  => @current_account.id,
              :project => login_token.project
            }
            redirect_to :controller => 'expenses', :action => 'of', :id => login_token.project
          else
            logout
          end
        rescue
          logout
        end
      else
        logout
      end
    else
      if request.get? && params[:open_id_complete].nil?
        render :action => 'login', :layout => 'public'
      else
        if using_open_id?
          open_id_authentication
        else
          login_pass_authentication
        end
      end
    end
  end
  
  def send_chpass_instructions
    begin
      @current_account.set_chpass_token
      url_for_chpass = url_for :action => 'chpass', :chpass_token => @current_account.chpass_token.token
      Mailer.deliver_chpass_instructions(@current_account, url_for_chpass)
      flash[:notice] = 'Se ha enviado un email con instrucciones a la dirección de contacto.'
      logger.debug("Se ha enviado un chpass mail para #{@current_account.short_name}, con mail de contacto #{@current_account.owner.email}")
    rescue Exception => e
      flash[:notice] = 'Lo sentimos, debido a un problema técnico no ha sido posible enviar el mail, trataremos de solventarlo lo antes posible.'
      logger.error("No se pudo enviar el chpass mail para #{@current_account.short_name}, con mail de contacto #{@current_account.owner.email}")
      logger.error("Motivo: #{e}")
    end
    redirect_to :back
  end

  def chpass
      @chpass_token = params[:chpass_token]
    if @chpass_token.blank? || @current_account.chpass_token.nil? || @current_account.chpass_token.token != @chpass_token
      logger.warn("invalid chpass request")
      redirect_to :action => 'login'
      return
    end
    @user = @current_account.owner
    if request.post?
      @user.password              = params[:password]
      @user.password_confirmation = params[:password_confirmation]
      if @user.validate_attributes_and_save(:only => [:password, :password_confirmation])
        # chpass tokens are one shot for security reasons
        if not @current_account.chpass_token.destroy
          # Race conditions are very unlikely here, I think the only possible way to enter
          # here is that the database has a problem, we cannot do too much in that case.
          logger.error("I couldn't destroy the chpass token '#{@chpass_token}' of #{@current_account}")
        end
        # log the user in automatically
        self.current_user = User.authenticate(@current_account, @user.email, @user.password)
        redirect_to "/"
        return
      end
    end
    render :action => 'chpass', :layout => 'public'
  end  

  protected

  def open_id_authentication
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        reset_session
        self.current_user = User.find_by_openid_url(identity_url)
        check_login_result
      else
        logger.warn("invalid openid access request. Message: #{result.message}")
        flash.now[:notice] = "Por favor revise los datos de acceso."
        render :action => 'login', :layout => 'public'
      end
    end
  end

  def login_pass_authentication
    reset_session
    self.current_user = User.authenticate(@current_account, params[:login], params[:password])
    check_login_result
  end

  def check_login_result
    if logged_in?
      redirect_back_or_default(:controller => 'expenses', :action => 'list')
    else
      flash.now[:notice] = "Por favor revise los datos de acceso."
      render :action => 'login', :layout => 'public'
    end
  end

end
