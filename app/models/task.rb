# == Schema Information
# Schema version: 20090408154321
#
# Table name: activities
#
#  id                   :integer(4)      not null, primary key
#  type                 :string(255)     
#  user_id              :integer(4)      
#  party_id             :integer(4)      
#  title                :string(255)     
#  body                 :text            
#  scheduled_at         :datetime        
#  created_at           :datetime        
#  updated_at           :datetime        
#  closed_at            :datetime        
#  activity_category_id :integer(4)      
#  private              :boolean(1)      
#  project_id           :integer(4)      
#  message_sender       :string(255)     
#  position             :integer(4)      
#  calendar             :boolean(1)      
#  message_id           :integer(4)      
#

class Task < Activity

  # acts_as_solr :fields => [:body], :if => lambda {|task| task.activity_category_id != PROCESS_CATEGORY_ID}
  define_index do
    indexes body
    where "activity_category_id != 1"
    # set_property :delta => true
    has :account_id
  end
  
  validates_presence_of :body, :message => _("Vous devez entrer un texte")
  
  named_scope :active, lambda { {:conditions => ["closed_at is NULL AND #{Task.private_condition}"], :order => 'scheduled_at, position asc'} } 
  named_scope :completed, lambda{ {:conditions => ["closed_at is not NULL AND #{Task.private_condition} "], :order => 'closed_at desc'} }
  named_scope :of_today, :conditions => ["DATE(scheduled_at) = CURDATE()"], :order => 'scheduled_at asc'
  named_scope :for_user, lambda {|user| user.blank? ? {} : {:conditions => ["user_id = ?", user]} }
  named_scope :for_category, lambda { |category_id| 
    return {} if category_id.blank?
    if category_id.to_s == "-1"
      category_id = ActivityCategory.find_by_name('processus').id
      {:conditions => ["activity_category_id <> ? OR activity_category_id IS NULL", category_id] }
    else
      {:conditions => ["activity_category_id = ?", category_id] }
    end
  }
  named_scope :for_date, lambda { |date_specified, date|
    return {} if date_specified == "false"
    d = date.to_date rescue Time.now.to_date
    {:conditions  => ["DATEDIFF(scheduled_at, ?) = 0", d]}
  }
  
  named_scope :min_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["scheduled_at >= ?", date] }
  }
  named_scope :max_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["scheduled_at <= ?", date] }
  }
  
  named_scope :for_completed_date, lambda { |date_specified, date|
    return {} if date_specified == "false"
    d = date.to_date rescue Time.now.to_date
    {:conditions  => ["DATEDIFF(closed_at, ?) = 0", d]}
  }
  
  named_scope :calendar, lambda {|only| only ? {:conditions => ["calendar = ?", only] } : {} }
  
  before_save do |task|
    # This is only to make it easier to filter items using only sql
    task.calendar = task.scheduled_date.time_specified?
    true
  end
  
  def complete(t = nil)
    t ||= Time.now
    begin
      self.class.record_timestamps = false
      self.updated_at = self.closed_at = t
      self.save
    ensure
      self.class.record_timestamps = true
    end
  end
  
  def scheduled_date
    @scheduled_date ||= FuzzyDate.new(self.scheduled_at)
  end
  
  def scheduled_date=(options)
    @scheduled_date = FuzzyDate.new_from_options(options)
    self.scheduled_at = @scheduled_date.time
    @scheduled_date
  end
  
  # Task List Helpers
  def self.categorize(tasks)
    ranges = tasks.to_set.classify {|i| i.scheduled_date.qualify }
    categories = []
    FuzzyDate::Qualifications.each do | q |
      sorted_value = ranges[q] ? ranges[q].to_a.sort_by {|t| [(t.scheduled_date or Time.utc(0) ), (t.position or 0 )] } : []
      categories <<  [q, sorted_value]
    end
    categories
  end
  
  protected
  def self.private_condition
    "(private = 0 OR ( private = 1 AND user_id = #{User.current_user.id.to_s}) )"
  end
end
