class DailySchedule < ScopedByAccount
  
  WEATHER =
   [
     'sunny',
     'cloudy',
     'rainy',
     'storm',
     'snow',
     'p-cloudy',
     'p-rainy',
     'p-snow'
   ].freeze
   
  validates_presence_of :date
  validates_uniqueness_of :date, :scope => :account_id
  validates_inclusion_of :weather, :in => WEATHER, :allow_blank => true
  
  has_many :interventions, :primary_key => :date, :foreign_key => :date
  
  def update_caches
    RAILS_DEFAULT_LOGGER.info("UPDATE CACHES")
    RAILS_DEFAULT_LOGGER.info self.update_attributes!(
      :work_time => interventions.sum(:work_time),
      :work_days => interventions.sum(:work_days)
    )
  end
  
  def self.last_schedule_date
    self.maximum(:date) || 1.month.ago.to_date
  end
  
  def self.next_day_to_schedule
    [last_schedule_date + 1.day, Date.today].max
  end
  
  def self.generate( for_date = Date.tomorrow )
    for_date = for_date.to_date
    schedule = nil
    
    DailySchedule.transaction do
      schedule = DailySchedule.create!(:date => for_date)
        
      work_sheets = WorkSheet.to_show_in_schedule.find(:all, :conditions => ["foreman_id IS NOT NULL AND scheduled_date <= ? AND (scheduled_end_date IS NULL OR scheduled_end_date >= ?)", for_date, for_date])
      if for_date >= Date.today || Rails.env.test?
        work_sheets.each do |ws|
          next unless ws.remaining_days > 0.0
          next if !CompanyCalendar.works_on?(for_date) && ws.scheduled_date != for_date
          
          intervention = ws.interventions.find_by_date( for_date )
          attrs = {:date => for_date, :foreman_id => ws.foreman_id}
          attrs[:work_days] = ws.remaining_days if ws.remaining_days < 1.0
          
          intervention ||= ws.interventions.create!( attrs )
          intervention.assign_team
        
          copy_roofer_conditions(ws, intervention)
        end
      end
    end
    
    schedule
  end
  
  def self.copy_roofer_conditions(ws,intervention)
    if ws.interventions.size > 1
      copy_from = ws.interventions[ ws.interventions.index(intervention) - 1 ]
      intervention.roofer_assignments.each do |assignment|
        copy_assignment = copy_from.roofer_assignments.detect {|copy_assignment| copy_assignment.roofer_id == assignment.roofer_id }
        if copy_assignment && copy_assignment.condition_id
          assignment.update_attribute(:condition_id, copy_assignment.condition_id)
        end
      end
    end
  end
  
  def to_params
    date
  end
  
end
