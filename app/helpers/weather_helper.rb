module WeatherHelper
  
  def weather_select_options
    DailySchedule::WEATHER.map {|w| [ I18n.t(w, :scope => :weather), w ] }
  end
  
  def weather_icon(object)
    weather = object.weather # || 'na'
    image_tag "weather/#{weather}.png", :title => I18n.t(object.weather, :scope => :weather)
  end
  
end