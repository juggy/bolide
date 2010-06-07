class AccountingItemsController < ApplicationController
  require_permission 'access_accounting_infos'

  before_filter :set_project

  def index
    @accounting_items = @project.accounting_items
  end

  def show
    @accounting_item = @project.accounting_items.find(params[:id])
  end

  def new
    @accounting_item = @project.accounting_items.build
  end

  def edit
    @accounting_item = @project.accounting_items.find(params[:id])
  end

  def create
    @accounting_item = @project.accounting_items.build(params[:accounting_item])

    respond_to do |format|
      if @accounting_item.save
        format.html { redirect_to project_accounting_items_url(@project) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @accounting_item = @project.accounting_items.find(params[:id])

    respond_to do |format|
      if @accounting_item.update_attributes(params[:accounting_item])
        format.html { redirect_to project_accounting_items_url(@project) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @accounting_item = @project.accounting_items.find(params[:id])
    @accounting_item.destroy

    redirect_to project_accounting_items_url(@project)
  end

  protected
  def set_project
    @project = Project.find(params[:project_id])
  end

end
