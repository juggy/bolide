class Department < ScopedByAccount
  cannot_be_deleted
  
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  
  has_many :projects
  has_many :work_sheets
  
  def to_s;name; end
  
  def foremen
    Role.users_with_role("chef d'équipe").scoped(:conditions => {:department_id => self.id})
    #Role.users_with_role("chef d'équipe" + self.name).scoped(:conditions => {:department_id => self.id})
  end
  
  def team_leaders
    users = foremen
    users.send(:preload_associations, users, :contact)
    users
  end
  
end