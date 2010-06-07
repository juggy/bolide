class TimeEntry < ScopedByAccount
  belongs_to :user
  belongs_to :project
  belongs_to :category, :class_name => "TimeEntryCategory", :foreign_key => "category_id"
  
  validates_presence_of :user_id
  validates_numericality_of :time, :greater_than => 0
  
  named_scope :recent, :order => 'date DESC, id DESC', :limit => 20
  
end
