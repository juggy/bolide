class UserMailer < ActionMailer::Base
  
  def change_password(user, domain, sent_at = Time.now)
    @subject    = 'Password change'
    @body       = {:user => user, :domain => domain}
    @recipients = user.email
    @from       = 'password@' + domain.split(":").first
    @sent_on    = sent_at
    @headers    = {}
  end
  
end
