class InvolvementsController < ApplicationController

  before_filter :set_project

  def index
    @involvements = @project.involvements
  end

  def show
    @involvement = @project.involvements.find(params[:id])
  end

  def new
    @involvement = @project.involvements.build
  end

  def edit
    @involvement = @project.involvements.find(params[:id])
  end

  def create
    @involvement = @project.involvements.build(params[:involvement])

    respond_to do |format|
      if @involvement.save
        flash[:notice] = 'Involvement was successfully created.'
        format.html { redirect_to project_involvements_url(@project) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @involvement = @project.involvements.find(params[:id])

    respond_to do |format|
      if @involvement.update_attributes(params[:involvement])
        flash[:notice] = 'Involvement was successfully updated.'
        format.html { redirect_to project_involvements_url(@project) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @involvement = @project.involvements.find(params[:id])
    @involvement.destroy

    redirect_to project_involvements_url(@project)
  end
  
  protected
  def set_project
    @project = Project.find(params[:project_id])
  end
end
