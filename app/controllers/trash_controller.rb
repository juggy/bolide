class TrashController < ApplicationController
  
  def show
    @message_recipients = email_user.received_messages.trash.paginate(:page => params[:page])
  end
  
  def create
    if params[:ids]
      if params["commit"] && !(params["commit"] =~ /effacer/)
        email_user.received_messages.find(params[:ids].keys).each do |r|
          r.archive!
        end
      else
        email_user.received_messages.find(params[:ids].keys).each do |r|
          r.trash!
        end
      end
    end
    respond_to do |wants|
      wants.html { redirect_to( inbox_url ) }
      wants.js { redirect_to( inbox_url ) }
    end      
  end
  
  def destroy
    if params[:ids]
      if params["commit"] && !(params["commit"] =~ /supprimer/)
        
        email_user.received_messages.find_all_by_message_id(params[:ids].keys).each do |r|
          r.inbox!
        end
        
      else
        if current_user.has_permission?('destroy_messages')
          email_user.received_messages.find_all_by_message_id(params[:ids].keys).each do |r|
            r.mark_for_deletion!
          end
        end
      end
      
    end
    redirect_to trash_url
  end
  
end
