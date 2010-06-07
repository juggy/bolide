class ActivityCategory < ScopedByAccount
  set_table_name 'config_activity_categories'
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  
  has_many :activities, :dependent => :nullify
  
  def to_s; name;end
end
