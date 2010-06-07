module TimeEntriesHelper
  
  def time_entry(time)
    if !time.nil? && time != 0.0
      haml_tag :strong, :style => 'font-size: 120%' do
        haml_concat time_with_fractions( time )
        # haml_concat number_with_precision( time, :precision => 2)
        # haml_concat time 
      end
    end
    haml_tag :span, :style => 'color:#666' do
      haml_concat "hrs"
    end
  end
  
  def time_with_fractions( time )
    rounded_time = time.floor.to_i
    fraction = (time - rounded_time) * 100
    frac = case fraction
      when 88..100
        rounded_time + 1
      when 63..87
        "&frac34;"
        # "¾"
      when 38..63
        "&frac12;"
        # "½"
      when 13..38
        "&frac12;"
        # "¼"
      end
    
    "#{rounded_time if rounded_time > 0}#{frac}"
  end
end
