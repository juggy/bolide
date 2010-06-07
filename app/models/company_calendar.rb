class CompanyCalendar
  class << self
    
    def works_on?(date)
      !date.weekend? && !holiday_on?(date)
    end
    
    def holiday_on(date)
      cached_holiday(date)
    end
    
    def holiday_on?(date)
      cached_holiday(date).present?
    end
    
    def planned_day_weight_on( date, department = "contract")
      if department == "contract"
        work_week_ex = cached_expectations.detect {|ex| ex.includes?(date) }
        work_week_ex ? work_week_ex.day_weight : 1.0
      else
        1.0
      end
    end
    
    protected
    def cached_expectations
      cache = CurrentRequestCache.get(:work_week_expections_cache)
      cache[:collection] ||= WorkWeekExpectation.all
    end
    
    def cached_holiday(date)
      holidays_cache = CurrentRequestCache.get(:holiday_cache)
      holidays_cache[date] ||= (Holiday.find_by_date(date) || "")
    end
    
  end
end