class NotesController < ApplicationController

  # def index
  #   @notes = Note.find(:all)
  # end
  # 
  # def show
  #   @note = Note.find(params[:id])
  # end
  # 
  # def new
  #   @note = Note.new
  # end
  # 
  # def edit
  #   @note = Note.find(params[:id])
  # end
  #
  def show
    @note = Note.find(params[:id])
  end
  
  def create
    @note = Note.new(params[:note].merge(:user => current_user))
  
    respond_to do |format|
      if @note.save
        flash[:notice] = _('Note was successfully created.')
        format.js
      else
        format.js { render :action => 'failed_create'}
      end
    end
  end
  
  def edit
    @note = Note.find(params[:id])
    render :partial=>"/notes/edit_note"
  end
  
  # 
  def update
    @note = Note.find(params[:id])
    
    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.js
      else
        format.js do
          render :update do |page|
            page.alert( _("Vous devez entrer un texte") )
          end
        end
      end
    end
  end
  # 
  def destroy
    @note = Note.find(params[:id])

    respond_to do |format|
      if @note.destroy
        format.js
      end
    end
  end
end
