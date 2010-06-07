class QuoteEvent < Struct.new(:event_type, :date, :user, :project)
  
  def self.find(start_date, end_date, search_params)
    events = []

    quote_by_projects = Project.searchlogic(search_params).find(:all, :conditions => 
        ['(close_quote_by >= ? AND close_quote_by <= ?)', start_date, end_date])
    
    quote_by_projects.each do |project|
      events << self.new('soumission', project.close_quote_by, project.estimator, project)
    end
    
    visit_projects = Project.searchlogic(search_params).find(:all, :conditions => 
        ['(visit_date >= ? AND visit_date <= ?)', start_date, end_date])
        
    visit_projects.each do |project|
      events << self.new('visite', project.visit_date, project.visitor, project)
    end
    
    events
  end
  
  
  def done?
    project.category == :quote_in_progress
  end
  
end