# == Schema Information
# Schema version: 20090408154321
#
# Table name: involvements
#
#  id         :integer(4)      not null, primary key
#  project_id :integer(4)      
#  party_id   :integer(4)      
#  role       :string(255)     
#  created_at :datetime        
#  deleted_at :datetime        
#

class Involvement < ScopedByAccount
  belongs_to :project
  belongs_to :party
  
  validates_presence_of :party_id, :message => _("Il faut choisir un contact déjà existant")
  validates_presence_of :project_id, :message => _("")
  
  named_scope :active, :conditions => ["involvements.deleted_at is null"], :order => 'involvements.role'
  named_scope :inactive, :conditions => ["involvements.deleted_at is not null"], :order => 'involvements.deleted_at desc'
  
  named_scope :internal, :conditions => ["parties.user_id is not null"], :include => [:party]
  named_scope :external, :conditions => ["parties.user_id is null"], :include => [:party]
  
  # Standard roles used in FO-033
  PROJECT_FOLLOWUP_KEYS = 
    {
      :owner => "Propriétaire", 
      :owner_resp => "Responsable propriétaire", 
      :inspector => "Inspecteur", 
      :inspector_resp => "Responsable inspecteur",
      :architect => "Architecte", 
      :architect_resp => "Responsable architecte", 
      :client_resp => "Responsable client", 
      :project_resp => "Responsable projet"
    }
  STANDARD_ROLES = PROJECT_FOLLOWUP_KEYS.values.freeze
  
  # Internal involvements methods
  INTERNAL_ROLES = {
    'project_manager' => _('Chargé de projet'),
    'estimator' => _("Estimateur"),
    'manager' => _("Gestionnaire de compte"),
    'foreman' => _("Contremaître"),
    'documenter' => _("Responsable documents")
  }
  
  def user_id
    party.user_id if party
  end
  
  def internal_role=(role)
    @internal_role = role
  end

  def before_validation
    if @internal_role
      user = User.find(@internal_role[:user_id])
      self.party = user.contact

      tag = @internal_role[:tag]
      if INTERNAL_ROLES.keys.include?( tag )
        self.role = INTERNAL_ROLES[tag]
        self.project.update_attribute("#{tag}_id", user.id)
      else
        self.role = @internal_role[:name]
      end
    end
  end
  
  # should never be destroyed by default, as we want to keep their history
  alias_method :force_destroy, :destroy
  def destroy(t = Time.now)
    self.update_attribute(:deleted_at, t) unless self.frozen?
  end
  
  def active?
    self.deleted_at.nil?
  end
end
