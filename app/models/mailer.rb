class Mailer < ActionMailer::Base
  def chpass_instructions(account, url_for_chpass)
    @subject    = ERB.new(CONFIG['chpass_mail_subject']).result(binding)
    @body       = {:msg => ERB.new(CONFIG['chpass_mail_body']).result(binding)}
    @recipients = account.owner.email
    @from       = ERB.new(CONFIG['chpass_mail_from']).result(binding)
    @sent_on    = Time.now
    @headers    = {}
  end

  def welcome(account, url_for_account)
    @subject    = ERB.new(CONFIG['welcome_mail_subject']).result(binding)
    @body       = {:msg => ERB.new(CONFIG['welcome_mail_body']).result(binding)}
    @recipients = account.owner.email
    @from       = ERB.new(CONFIG['welcome_mail_from']).result(binding)
    @sent_on    = Time.now
    @headers    = {}
  end
  
  def accounts_reminder(email, urls)
    @subject    = ERB.new(CONFIG['accounts_reminder_mail_subject']).result(binding)
    @body       = {:msg => ERB.new(CONFIG['accounts_reminder_mail_body']).result(binding)}
    @recipients = email
    @from       = ERB.new(CONFIG['accounts_reminder_mail_from']).result(binding)
    @sent_on    = Time.now
    @headers    = {}    
  end
  
  # Alerts to monitorize application health.
  def devalert(subject, body='', extra_to=nil)
    @subject    = subject
    @body       = {:msg => body}
    @recipients = [CONTACT_EMAIL_ACCOUNTS, extra_to].compact.join(', ')
    @from       = ALERT_EMAIL_DEV
    @sent_on    = Time.now
    @headers    = {}    
  end
end
