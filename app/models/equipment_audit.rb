# == Schema Information
# Schema version: 20090408154321
#
# Table name: equipment_audits
#
#  id            :integer(4)      not null, primary key
#  equipment_id  :integer(4)      
#  borrower_id   :integer(4)      
#  borrowed_date :date            
#  borrowed_note :text            
#  created_at    :datetime        
#  updated_at    :datetime        
#  status_id     :integer(4)      
#  user_id       :integer(4)      
#

class EquipmentAudit < ScopedByAccount
  belongs_to :equipment
  belongs_to :borrower, :class_name => "User", :foreign_key => "borrower_id"
  belongs_to :status, :class_name => "EquipmentStatus"
  belongs_to :user
  
  before_create :default_date_to_today
  before_create :log_current_user
  
  def location
    self.borrower ? self.borrower.full_name : Equipment::DEFAULT_LOCATION
  end
  
  def status_name
    self.status ? self.status.name : Equipment::DEFAULT_STATUS
  end
  
  def user_name
    self.user ? self.user.full_name : ''
  end
  
  protected
    def default_date_to_today
      self.borrowed_date ||= Time.now
    end
    
    def log_current_user
      self.user = User.current_user
    end
end
