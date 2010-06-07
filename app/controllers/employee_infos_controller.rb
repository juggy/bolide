class EmployeeInfosController < ApplicationController
  require_hr_permission
  
  before_filter :load_objects
  
  def edit
  end
  
  def create
    update
  end
  
  def update
    if @employee_info.update_attributes( params[:employee_info] )
      redirect_to hr_contact_url(@contact)
    else
      render :action => 'edit'
    end
  end
  
  def load_hr_user
    load_objects
    @contact.user
  end
  
  def create_comment
    @employee_info.comments.create(params[:comment].merge( {:user_id => current_user.id} ) )
    redirect_to hr_contact_url(@contact)
  end
  
  def edit_comment
    @comment = @employee_info.comments.find(params[:comment_id])
    render :update do |page|
      page.replace_html 'edit_comment_form', render( :partial => 'edit_comment')
    end
  end
  
  def update_comment
    @comment = @employee_info.comments.find(params[:comment_id])
    @comment.update_attributes(params[:comment])
    redirect_to hr_contact_url(@contact, :anchor => 'comments')
  end
  
  def delete_comment
    @comment = @employee_info.comments.find(params[:comment_id])
    @comment.destroy
    redirect_to hr_contact_url(@contact)
  end
  
  protected
    def load_objects
      @contact ||= Contact.find(params[:contact_id])
      @employee_info ||= @contact.get_employee_info
    end
  
end
