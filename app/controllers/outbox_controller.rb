class OutboxController < ApplicationController
  
  def show
    #restore_session_params("outbox" )
    case params[:show]
      when 'unsent'
        @messages = email_user.sent_messages.unsent.paginate(:page => params[:page])
      when 'sent'
        @messages = email_user.sent_messages.sent.paginate(:page => params[:page])
      when 'error'
        @messages = email_user.sent_messages.error.paginate(:page => params[:page])
      when 'draft'
          @messages = email_user.sent_messages.draft.paginate(:page => params[:page])
      else
        @messages = email_user.sent_messages.paginate(:page => params[:page])
    end
    
  end
  
end