class DailySchedulesController < ApplicationController
  require_permission 'update_schedule', :except => [:index, :show]
  require_permission ['update_schedule','show_schedule'], :only => [:index, :show]
  
  layout 'fullscreen'
  
  def index
    @today = Date.today
    params[:year]  ||= @today.year
    params[:month] ||= @today.month
    params[:year]  = params[:year].to_i
    params[:month] = params[:month].to_i
    @current_day = Date.new(params[:year], params[:month], 1)
    
    calendar = CalendarHelper::Calendar.new(:year => params[:year], :month => params[:month])
    
    @schedules = DailySchedule.find(:all, :conditions => ['date >= ? AND date <= ?', calendar.first_day, calendar.last_day])
  end
  
  def create
    @schedule = DailySchedule.generate(params[:date])
    redirect_to daily_schedule_url(params[:date])
  end
  
  def show
    params[:date] = params[:id]
    @schedule = DailySchedule.find_by_date(params[:date], 
        :include => [ 
          :interventions => [
            :work_sheet => [
              :project
            ],
            :roofer_assignments => [
              :roofer => [
                :contact => [
                  :employee_info
                ]
              ]
            ]
          ]
        ]
      )
    
    @departments = Department.all
    @grouped_interventions = @schedule.interventions.group_by(&:foreman_id)
  end
  
  def update
    @schedule = DailySchedule.find(params[:id])
    @schedule.update_attributes(params[:daily_schedule])
    
    render :update do |page|
      page.replace_html 'schedule_info', (render :partial => "info")
    end
  end
  
  def new_intervention
    @intervention = Intervention.new( :foreman_id => params[:foreman_id], :date => params[:date] )
    work_sheets = WorkSheet.to_show_in_schedule.schedule_order.find(:all, :conditions => ["foreman_id IS null OR foreman_id = ?", @intervention.foreman_id], :include => [:project, :interventions], :order => 'created_at')
    
    work_sheets_scheduled, other = work_sheets.partition {|w| w.foreman_id}
    work_sheets_promised, other = other.partition {|w| !w.scheduled_date.nil?}
    work_sheets_priority, other = other.partition {|w| w.project.priority?}
    
    one_year = 1.year.from_now.to_date
    @work_sheets = [
        ['Cédulé', work_sheets_scheduled.sort_by {|ws| ws.scheduled_date || one_year }],
        ['Promesse', work_sheets_promised.sort_by {|ws| ws.scheduled_date || one_year }],
        ['Coulisse', work_sheets_priority],
        ['Autres', other]
      ]

    render :update do |page|
      page.insert_html :top, dom_id(@intervention.foreman, "add_intervention_form_wrapper"), render(:partial => 'new_intervention')
    end
  end
  
  def update_intervention
    params[:roofers] ||= {}
    
    # TODO: bug with nested indexed form, absence attributes goes roofer[attributes][5] instead of roofer[5][attributes]
    absences = params[:roofers].delete(:absence_attributes) || {}
    
    @roofers = []
    (params[:roofers] || {}).each do |rid, values|
      ir = InterventionRoofer.find(rid)
      @roofers << ir
      values[:absence_attributes] = absences[rid] || {}
      
      # TODO: nested attributes reject function can only access its own attributes
      values[:absence_attributes][:status] = values[:status]
      # puts values.inspect
      ir.update_attributes(values)
      # puts ir.valid?
    end

    @intervention = Intervention.find(params[:id])
    @intervention.update_attributes!(params[:intervention])
    render :update do |page|
      
      page.replace_html dom_id(@intervention), render(:partial => 'intervention', :locals => {:intervention => @intervention})
      page.visual_effect :highlight, dom_id(@intervention)
    end
  end
  
  def add_intervention
    @intervention = Intervention.create(params[:intervention])
    @intervention.assign_team
    roofer_ids = @intervention.roofers.collect(&:id)
    
    render :update do |page|
      page.insert_html :top, dom_id(@intervention.foreman, 'body'), render(:partial => 'intervention', :locals => {:intervention => @intervention})
      page.remove dom_id(@intervention.foreman, 'new_intervention_form')
      doubles = roofer_ids.collect do |rid|
        page << "check_double('.roofer_#{rid}');"
      end
    end
  end
  
  def delete_intervention
    intervention = Intervention.find(params[:id])
    roofer_ids = intervention.roofers.collect(&:id)
    intervention.destroy
    
    render :update do |page|
      doubles = roofer_ids.collect do |rid|
        "check_double('.roofer_#{rid}');"
      end
      page.visual_effect :slide_up, dom_id(intervention), :afterFinish => "function() { $('#{dom_id(intervention)}').remove() ; #{doubles.join} }"
      # page.remove dom_id(intervention)
    end
  end
  
  def add_intervention_roofer
    ir = InterventionRoofer.create(params[:intervention_roofer])
    render :update do |page|
      page.insert_html :bottom, dom_id(ir.intervention, 'roofers_list'), render(:partial => 'edit_roofer', :locals => {:ir => ir})
      page.visual_effect :highlight, dom_id(ir.intervention, 'roofers_list')
      page.hide dom_id(ir.intervention, 'add_roofer_form_wrapper')
      page << "check_double('.roofer_#{ir.roofer_id}');"
    end
  end
  
  def delete_intervention_roofer
    ir = InterventionRoofer.find(params[:id])
    ir.destroy
    
    render :update do |page|
      page.remove dom_id(ir)
      page.visual_effect :highlight, dom_id(ir.intervention, 'roofers_list')
      page << "check_double('.roofer_#{ir.roofer_id}');"
    end
  end
  
end
