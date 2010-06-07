class InterventionsController < ApplicationController
  require_permission 'update_schedule', :except => [:index, :show]
  
  before_filter :get_work_sheet_project, :except => [:index]

  def index
    @interventions = Intervention.for_foreman( params[:foreman_id] ).
                                  min_date( params[:min_date] ).
                                  max_date( params[:max_date] ).
                                  non_completed_only(params[:non_completed]).
                                  paginate( :order => 'date desc, foreman_id', :per_page => 50, :page => params[:page],
                                  :include => [:foreman, 
                                    {:work_sheet => 
                                        [:project => 
                                            [:work_type, {:contract => [:contract_type]}, {:building => :address } ]
                                        ]
                                    }]
                                  ) # premature optimization
  end

  def show
    @intervention = @work_sheet.interventions.find(params[:id])
    respond_to do |wants|
      wants.html { redirect_to_parent }
      wants.pdf { send_data WorkSheetPdf::generate(@intervention), :filename => "bon_de_travail_#{@intervention.work_sheet.id}.pdf" }
    end
  end

  def new
    @intervention = @work_sheet.interventions.new(params[:intervention])
    @work_sheets = WorkSheet.service.to_schedule
  end

  def edit
    @intervention = @work_sheet.interventions.find(params[:id])
  end

  def create
    @intervention = @work_sheet.interventions.new(params[:intervention])

    if @intervention.save
      redirect_to_parent
    else
      render :action => "new"
    end
  end

  def update
    @intervention = @work_sheet.interventions.find(params[:id])

    if @intervention.update_attributes(params[:intervention])
      #flash[:notice] = 'Intervention was successfully updated.'
      redirect_to_parent
    else
      render :action => "edit"
    end
  end

  def destroy
    @intervention = @work_sheet.interventions.find(params[:id])
    @intervention.destroy

    redirect_to_parent
  end
  
  protected
    def redirect_to_parent
      redirect_to([@project,@work_sheet])
    end
    
    def get_work_sheet_project
      @work_sheet = WorkSheet.find(params[:work_sheet_id], :include => :project)
      @project = @work_sheet.project
    end
end
