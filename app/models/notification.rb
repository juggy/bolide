class Notification
  
  def self.new_to_quote(project)
    if Account.current_account.tc?
      body = render_project_template(project, '/mail_sender/new_to_quote_message.rhtml')
      new_role_notification(["nouvelle demande"], "Nouvelle demande: #{project.display_name}", body)
    end
  end
  
  def self.new_intervention(project)
    if Account.current_account.tc?
      body = render_project_template(project, '/mail_sender/new_intervention_message.rhtml')
      new_role_notification(["appel de service"], "Appel de service: #{project.display_name}", body)
    end
  end
  
  def self.new_role_notification(roles, subject, body)
    Message.create( 
      { 
        :to => roles_email( roles ), 
        :body => body, 
        :subject => subject, 
        :sender_email => "tcmanager@couture.codegenome.com",
        #:content_type => 'text/plain',
        :state => 'unsent'
      }
    )
  end
  
  def self.render_project_template(project, path)
    renderer = ActionView::Base.new( Rails::Configuration.new.view_path, {})
    class << renderer
      include ApplicationHelper
    end
    
    renderer.assigns[:project] = project
    file = File.join(RAILS_ROOT, '/app/views',path)
    body = renderer.render(:file => file )
  end
  
  def self.roles_email(roles)
    if RAILS_ENV == 'production'
      emails = []
      for role in roles
        emails.concat( Role.find_by_name(role).users.collect(&:email) ) rescue nil
      end
      emails.join(", ")
    else
      "jfcouture@gmail.com"
    end
  end
  
end