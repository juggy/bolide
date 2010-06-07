class DispatchInterventionsController < ApplicationController
  require_permission 'update_schedule'

  # def index
  #   @interventions = Intervention.find(:all)
  # end

  # def show
  #   @intervention = Intervention.find(params[:id])
  # end

  def new
    @intervention = Intervention.new(params[:intervention])
    work_sheets = WorkSheet.service.to_schedule.schedule_order.find(:all, :conditions => ["foreman_id IS null OR foreman_id = ?", @intervention.foreman_id], :order => 'created_at')
    
    work_sheets_scheduled, other = work_sheets.partition {|w| w.foreman_id}
    work_sheets_promised, other = other.partition {|w| !w.scheduled_date.nil?}
    work_sheets_priority, other = other.partition {|w| w.project.priority?}
    
    one_year = 1.year.from_now.to_date
    @work_sheets = [
        ['Cédulé', work_sheets_scheduled.sort_by {|ws| ws.scheduled_date || one_year }],
        ['Promesse', work_sheets_promised],
        ['Coulisse', work_sheets_priority],
        ['Autres', other]
      ]
    respond_to do |format|
      format.html { render :layout => false }# new.html.erb
      #format.js { render :template => 'new', :layout => false }
    end
  end

  def edit
    @intervention = Intervention.find(params[:id])
    render :layout => false
  end

  def create
    @intervention = Intervention.new(params[:intervention])

    respond_to do |format|
      if @intervention.save
        
        format.html { redirect_to(@intervention) }
        format.js do
          render :update do |page|
            page.remove 'intervention_form_wrapper'
            page.insert_html :bottom, dom_id(@intervention.foreman, @intervention.date.strftime("%Y%m%d") ),
                              render( :partial => 'work_sheet_dispatch/intervention', :object => @intervention)
          end
        end
        
      else
        
        format.html { render :action => "new" }
        format.js do
          render :update do |page|
            page.alert @intervention.errors.full_messages.join("/r/n")
          end
        end
            
      end
    end
  end

  def reschedule
    id = params[:id].split("_").last
    @intervention = Intervention.find(id)
    @intervention.foreman_id = params[:foreman_id]
    @intervention.date = params[:date]
    render :update do |page|
      
      if !@intervention.save
        page.alert @intervention.errors.full_messages.join("/r/n")
        @intervention.reload
      end
      page.remove dom_id(@intervention)
      page.insert_html :bottom, dom_id(@intervention.foreman, @intervention.date.strftime("%Y%m%d") ),
                        render( :partial => 'work_sheet_dispatch/intervention', :object => @intervention)
      
    end
  end

  def update
    @intervention = Intervention.find(params[:id])

    respond_to do |format|
      if @intervention.update_attributes(params[:intervention])
        flash[:notice] = 'Intervention was successfully updated.'
        format.html { redirect_to(@intervention) }
        format.js do
          render :update do |page|
            page.remove 'intervention_form_wrapper'
            page.replace dom_id(@intervention),
                              render( :partial => 'work_sheet_dispatch/intervention', :object => @intervention)
            page.visual_effect :highlight, dom_id(@intervention)
          end
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @intervention = Intervention.find(params[:id])
    @intervention.destroy

    respond_to do |format|
      format.html { redirect_to(interventions_dispatch_url) }
      format.js do
        render :update do |page|
          page.remove 'intervention_form_wrapper'
          page.remove dom_id(@intervention)
        end
      end
    end
  end
end
