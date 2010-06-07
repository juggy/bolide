class MaterialCategory < ScopedByAccount
  has_many :materials, :foreign_key => 'category_id'
  validates_presence_of :name
  belongs_to :unit_type
  
  named_scope :active
end
