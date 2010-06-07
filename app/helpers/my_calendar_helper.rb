module MyCalendarHelper
  def link_to_previous_month( current_month )
    previous_month = current_month - 1.month
    link_to "&lt;&lt; #{DateLocalization.date_helper_month_names[previous_month.month]}", {:month => previous_month.month, :year => previous_month.year}
  end
  
  def link_to_next_month( current_month )
    next_month = current_month + 1.month
    link_to "#{DateLocalization.date_helper_month_names[next_month.month]} &gt;&gt;", {:month => next_month.month, :year => next_month.year}
  end
  
  def link_to_previous_week( current_week )
    previous_week = current_week - 1.week
    link_to "&lt;&lt; #{previous_week}", {:week_of => previous_week}
  end
  
  def link_to_next_week( current_week )
    next_week = current_week + 1.week
    link_to "#{next_week} &gt;&gt;", {:week_of => next_week}
  end
  
  def calendar_classes_for(day)
    classes = []
    if(day == @today)
      classes << 'today'
    end
    if day.weekend?
      classes << 'weekend'
    end
    if CompanyCalendar.holiday_on?(day)
      classes << 'holiday'
    end
    classes.join(" ")
  end
  
end