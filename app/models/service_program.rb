class ServiceProgram
  
  attr_accessor :today, :start_date, :end_date, :work_sheets
  attr_reader :next_unscheduled_day
  
  def initialize(options = {})
    @department = Department.find(options[:department_id]) # || 'service'

    @week_factor = options[:week_factor] || 1.0
    
    @today = Date.today
    @start_date = options[:start_date] ? options[:start_date].to_date : (@today - 1.days)
    @end_date = options[:end_date] ? options[:end_date].to_date : @start_date + 6.days
    @last_schedule = DailySchedule.last_schedule_date + 1.day
    @next_unscheduled_day = [@last_schedule, @today].max
    # puts @end_date, @last_schedule, @end_date <= @last_schedule
    if !past_schedule?
      @work_sheets = WorkSheet.to_show_in_schedule.find(:all, :include => [:interventions, :project, :foreman]) # .for_department(@department)
    else
      @work_sheets = WorkSheet.find(:all, :conditions => { :interventions => {:foreman_id => foremen.collect(&:id), :date => days} }, :include => [:interventions, :project, :foreman])
    end
    build_calendar_week
  end
  
  def past_schedule?
    @end_date <= @last_schedule
  end
  
  def days
    @days ||= (@start_date..@end_date).to_a
  end
  
  def foremen
    return @foremen if @foremen
    @foremen = @department.foremen
  end
  
  def work_sheets_for(foreman, date)
    @calendar_week[foreman.id][date] || []
  end
  
  def max_date_for(foreman)
    @calendar_week[foreman.id] ? @calendar_week[foreman.id].keys.max : nil
  end
  
  def unscheduled?(date) 
    @next_unscheduled_day <= date
  end
  
  protected
    
    class DailyWorkSheet
      attr_reader :work_sheet
      def initialize(work_sheet, day, remaining, time = 1.0, type = 'work_sheet')
        @work_sheet = work_sheet
        @day = day
        @remaining = remaining
        @type = type
        @time = time || 1.0
      end
      
      def time
        @time if @time < 1.0
      end
      
      def intervention?
        @type == 'intervention'
      end
      
      def css_classes
        classes = []
        classes << 'first_day' if (@work_sheet.interventions.size == 0 && @work_sheet.scheduled_date == @day) || (@work_sheet.interventions.size > 0 && @work_sheet.interventions[0].date == @day)
        classes << 'last_day' if @remaining <= 0.0
        classes << 'done' if intervention?
        classes.join(" ")
      end
    end
    
    def build_calendar_week
      @calendar_week = {}
      
      foremen.each do |foreman|
        foreman_week = new_empty_week
        
        @work_sheets.each do |work_sheet|
          
          first_intervention = true
          work_sheet.interventions.select {|int| int.foreman_id == foreman.id}.each do |int|
            foreman_day = (foreman_week[int.date] ||= [])
            
            last = (work_sheet.interventions[-1] == int && (work_sheet.remaining_days || 0.0) <= 0.0)
            foreman_day << DailyWorkSheet.new(work_sheet, int.date, last ? 0 : 1, int.work_days, 'intervention')
            first_intervention = false
          end
          
          next unless work_sheet.foreman_id == foreman.id
          next unless work_sheet.scheduled_date
          
          # current_day = [@next_unscheduled_day, work_sheet.scheduled_date].max
          # remaining_days = work_sheet.remaining_days
          # 
          # while (remaining_days > 0 ) do
          #   # puts "#{work_sheet.id} #{remaining_days} #{current_day.to_s} #{current_day.weekend?}"
          #   if !current_day.weekend? || current_day == work_sheet.scheduled_date
          #     
          #     remaining_days -= @week_factor
          #     if current_day >= @next_unscheduled_day && current_day >= @start_date && current_day <= @end_date
          #       foreman_week[current_day] << DailyWorkSheet.new(work_sheet, current_day, remaining_days, [@week_factor, remaining_days + 1].min)
          #     end
          #     
          #   end
          #   current_day += 1.day
          # end
          work_sheet.planned_interventions.each do |pi|
            (foreman_week[pi.day] ||= []) << DailyWorkSheet.new(work_sheet, pi.day, pi.remaining, pi.time)
          end
          
        end
        
        @calendar_week[foreman.id] = foreman_week
      end
    end
    
    def new_empty_week
      h = {}
      # days.each do |day|
      #   h[day] = []
      # end
      # h
    end
end
