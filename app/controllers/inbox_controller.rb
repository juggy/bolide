class InboxController < ApplicationController
  
  # must save to session the id and restore across controllers
  # before_filter :set_user_email
  
  def show
    #restore_session_params("inbox")
    
    case params[:show]
      when 'unread'
        @message_recipients = email_user.received_messages.unread.paginate(:page => params[:page])
      when 'read'
        @message_recipients = email_user.received_messages.read.paginate(:page => params[:page])
      else
        @message_recipients = email_user.received_messages.active.paginate(:page => params[:page])
    end
  end
  
  # Non rest
  def count
    msg_count = current_user.received_messages.unread.count
    str = (msg_count > 0 ? "(#{msg_count})" : "") 
    respond_to do |wants|
      wants.js { render :text => str }
    end
  end
end