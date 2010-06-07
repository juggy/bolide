class InvoicesController < ApplicationController
  require_permission 'create_and_update_invoices', :except => [:index, :show]
  
  before_filter :get_work_sheet
  
  def index
    @invoice = Invoice.new
  end
  
  def show
    @invoice = @work_sheet.invoices.find(params[:id])
  end
  
  def create
    @invoice = @work_sheet.invoices.new(params[:invoice])
    @invoice.creator = current_user
    if @invoice.save
      redirect_to :action => "show", :id => @invoice
    else
      render :action => "index"
    end
  end
  
  def update
    @invoice = @work_sheet.invoices.find(params[:id])

    if @invoice.update_attributes(params[:invoice])
      #message
    end
    
    render :action => "show"
  end
  
  def destroy
    @invoice = @work_sheet.invoices.find(params[:id])
    @invoice.destroy

    redirect_to work_sheet_invoices_path(:work_sheet_id => @work_sheet.id)
  end
  protected
  def get_work_sheet
    @work_sheet = WorkSheet.find(params[:work_sheet_id])
  end
end
