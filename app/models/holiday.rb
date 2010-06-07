class Holiday < ScopedByAccount
  validates_presence_of :date
  
  attr_accessor :end_date # only use for form
  def self.range_create( attrs )
    end_date = attrs.delete(:end_date)
    if end_date.present?
      start_date = attrs.delete(:date)
      (start_date.to_date..end_date.to_date).each do |date|
        self.create(:name => attrs[:name], :date => date)
      end
    else
      self.create(attrs)
    end
  end
  
end
