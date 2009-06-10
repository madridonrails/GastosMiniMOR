class ProfileController < ApplicationController
  include LoginUrlHelper # needed to process ERB templates with mail parts
  
  before_filter :ensure_can_write
  before_filter :calculate_total_expenses
  
  def index
    redirect_to :action => 'show'
  end
  
  def show
    @user = @current_account.owner
    @subject = ERB.new(CONFIG['agencies_login_url_mail_subject']).result(binding)
    @body    = ERB.new(CONFIG['agencies_login_url_mail_body']).result(binding)
  end
  
  def edit
    @user = @current_account.owner
    @wrong_password = @show_email_confirmation = false
    return if request.get?
    
    # Do this before attempt to change email below.
    unless User.authenticate(@current_account, @current_account.owner.email, params[:current_password])
      @wrong_password = true
    end
    
    unless @current_account.owner.email == params[:owner][:email] && params[:owner][:email] == params[:owner][:email_confirmation]
      @show_email_confirmation = true
    end

    @user.attributes = params[:user]

    if @user.valid? && !@wrong_password # run validations even if the password was not correct
      User.transaction do
        @user.save!
        @current_account.renew_login_token_for_agencies if params[:change_login_url_for_agencies] == '1'
        redirect_to :action => 'show'
      end rescue nil
    end
  end
  
end
