class FileAttachmentsController < ApplicationController
  def show
    @file_attachment = FileAttachment.find(params[:id])
  end

  def new
    @file_attachment = FileAttachment.new({:party_id => params[:party_id], :project_id => params[:project_id]})
  end

  def create
    @file_attachment = FileAttachment.new(params[:file_attachment].merge(:user_id => current_user.id))

    respond_to do |format|
      if @file_attachment.save
        flash[:notice] = 'FileAttachment was successfully created.'
        format.html do 
          redirect_to_attachment_parent
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  def destroy
    @file_attachment = FileAttachment.find(params[:id])
    @file_attachment.destroy
    redirect_to_attachment_parent
  end
  
  def redirect_to_attachment_parent
    if @file_attachment.project
      redirect_to( @file_attachment.project )
    else
      redirect_to( @file_attachment.party )
    end
  end
end
