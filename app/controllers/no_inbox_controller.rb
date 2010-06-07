class NoInboxController < ApplicationController
  
  def show
    @messages = Message.no_inbox.paginate(:page => params[:page])
  end
  
  def destroy
    if params[:ids]
      Message.destroy(params[:ids].keys)
    end
    redirect_to no_inbox_url
  end
end