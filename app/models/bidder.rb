class Bidder < ScopedByAccount
  belongs_to :company
  belongs_to :project
  
  validates_presence_of :company_id, :message => "Il faut choisir un competiteur"
  validates_presence_of :project_id
  validates_numericality_of :bid
  
  after_save :update_positions
  after_destroy :update_positions
  
  def name
    company.name
  end
  
  protected
  
    def update_positions
      self.project.update_bid_positions
      
      true
    end
    
end
