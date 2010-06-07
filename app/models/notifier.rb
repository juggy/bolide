class Notifier < ActionMailer::Base

  def day_agenda(user, tasks)
    @sent_on    = Time.now
    @subject    = "[C3]: AGENDA #{@sent_on.strftime('%d %b')}"
    @body['tasks']=tasks
    @recipients = user.email
    @from       = user.email
    @headers    = {}
  end
end
