class WorkWeekExpectation < ScopedByAccount
  validates_presence_of :start_date, :end_date
  validates_numericality_of :days_per_week, :less_than_or_equal_to => 5.0, :greater_than  => 0.0
  validate :no_overlap_between_date_ranges
  
  named_scope :active, lambda { {:conditions => ["end_date > ?", Date.today], :order => 'start_date'} }
  
  def includes?(date)
    start_date <= date && end_date >= date
  end
  
  def day_weight
    days_per_week / 5.0
  end
  
  def work_days_left_for(users)
    @work_days_left_for ||= begin
      c = 0
      (Date.today..end_date).each do |date|
        users.each do |user|
          c += CompanyCalendar.planned_day_weight_on(date) if CompanyCalendar.works_on?(date) && user.available_on?(date)
        end
      end
      c
    end
  end
  
  def work_days_left
    @work_days_left ||= begin
      c = 0
      (Date.today..end_date).each do |date|
        c += CompanyCalendar.planned_day_weight_on(date) if CompanyCalendar.works_on?(date)
      end
      c
    end
  end
  
  protected
    def no_overlap_between_date_ranges
      errors.add(:start_date, "Les dates ne doivent pas se chevauchées.") if WorkWeekExpectation.count(:conditions => ["(NOT((? < start_date) or (? > end_date)))", end_date, start_date ]) > 0
    end
end
