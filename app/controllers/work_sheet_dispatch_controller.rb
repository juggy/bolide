class WorkSheetDispatchController < ApplicationController

  layout 'fullscreen'
  
  def to_schedule
    @work_sheets = WorkSheet.service.to_schedule
    @foremans = Role.users_with_role("chef d'équipe service")
    @interventions = Intervention.find(:all).group_by(&:foreman_id)
    #@interventions.default = []
    
    set_schedule_days
  end

  def acceptation
    @work_sheets = work_sheet_in_acceptation
    if request.post? && params[:work_sheets]
      @work_sheets.each do |work_sheet|
        if params[:work_sheets][work_sheet.id.to_s] == "1"
          work_sheet.done!
        end
      end
      
      # update work_sheet collection and count how many were updated
      size = @work_sheets.size
        @work_sheets = work_sheet_in_acceptation
      size -= @work_sheets.size
      
      flash.now[:notice] = "#{size} bons de travail sont prêts à être facturés"
    end
  end
  
  def to_invoice
    @work_sheets = WorkSheet.to_invoice.find(:all, :include => :project, :order => 'projects.call_number asc')
  end
  
  def invoice
    @work_sheet = WorkSheet.find(params[:id])
    # if @work_sheet.invoice!( params[:work_sheet] )
    #   flash[:notice] = "#{@work_sheet.id} - #{@work_sheet.call_number} a été facturé!"
    # else
    #   flash[:notice] = "#{@work_sheet.id} - #{@work_sheet.call_number} manque information pour terminer la facturation."
    # end
    # redirect_to :action => 'to_invoice'
  end
  
  protected
  
  def work_sheet_in_acceptation
    WorkSheet.acceptation.find(:all, :include => {:project => {:contract => :contract_type}}, :order => "projects.call_number")
  end
  
  def set_schedule_days
    @yesterday_label = "Hier"
    yester = Time.now.yesterday
    if yester.wday == 0
      yester -= 2.days
      @yesterday_label = "Vendredi"
    elsif yester.wday == 6
      yester -= 1.days
      @yesterday_label = "Vendredi"
    end
    @yesterday = yester.strftime("%Y%m%d")
    
    @today = Time.now.strftime("%Y%m%d")
    
    @tomorrow_label = "Demain"
    tomor = Time.now.tomorrow
    if tomor.wday == 0
      tomor += 1.days
      @tomorrow_label = "Lundi"
    elsif tomor.wday == 6
      tomor += 2.days
      @tomorrow_label = "Lundi"
    end
    @tomorrow = tomor.strftime("%Y%m%d")
  end
end
