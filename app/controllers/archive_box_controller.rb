class ArchiveBoxController < ApplicationController
  
  def show
    @message_recipients = email_user.received_messages.
                                      archived.
                                      for_min_date(params[:start_date]).
                                      for_max_date(params[:end_date]).
                                      paginate(:page => params[:page])
  end
  
  
  #TODO: cleanup message state cahnges across inbox, trash, archive controller
  def create
    if params[:ids]
      email_user.received_messages.find(params[:ids].keys).each do |r|
        r.archive!
      end
    end
    respond_to do |wants|
      wants.html { redirect_to( archive_box_url ) }
      wants.js { 
        render :update do |page|
          page.redirect_to( inbox_url )
        end
      }
    end      
  end
  
  def destroy
    if params[:ids]
      email_user.received_messages.find(params[:ids].keys).each do |r|
        r.inbox!
      end
    end
    respond_to do |wants|
      wants.html { redirect_to( archive_box_url ) }
      wants.js { 
        render :update do |page|
          page.redirect_to( inbox_url )
        end
      }
    end      
  end
  
end