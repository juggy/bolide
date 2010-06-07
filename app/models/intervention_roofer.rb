class InterventionRoofer < ScopedByAccount
  belongs_to :intervention
  belongs_to :roofer, :class_name => "User", :foreign_key => "roofer_id"
  belongs_to :absence
  belongs_to :condition, :class_name => "RooferInterventionCondition", :foreign_key => "condition_id"
  
  validates_presence_of :intervention_id, :roofer_id
  validates_uniqueness_of :roofer_id, :scope => [:account_id, :intervention_id]
  
  accepts_nested_attributes_for :absence , :reject_if => proc {|attrs| attrs["status"] != 'absent'}

  before_create :check_for_planned_absence
  before_save :check_dangling_absence
  
  # STATUS
  def verified?
    status != 'planned'
  end
  
  def absent?
    status == 'absent' || planned_absence?
  end

  protected
  def check_for_planned_absence
    date = self.intervention.date
    absence = self.roofer.absence_for( date )
    if absence
      self.absence = absence
      self.status = 'absent'
      self.planned_absence = true
    end
  end
  
  def check_dangling_absence
    if status_changed? && status_was == 'absent' && !planned_absence
      self.absence.destroy
    end
  end
end
