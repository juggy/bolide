module ReportsHelper
  
  def format_field(field, type)
    case type
    when :money
      number_to_currency field, :precision => 0
    when :time
      number_with_precision field, :precision => 2
    when :pct
      number_to_percentage field, :precision => 2
    else
      field
    end
  end
  
  def grouped_by
    stats_group.find {|g| params[:group] == g[1] }[0]
  end
  
  def report_group_dom_id(group)
    dom_id(group) rescue "report_group_nil_id"
  end
  
  def report_group_name(group) 
    group.to_s.blank? ? "non défini" : group.to_s
  end
  
end