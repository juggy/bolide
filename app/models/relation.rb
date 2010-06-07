# A relation is the 2-way relationships between two parties
# this class handles both relationships
class Relation
  
  EMPLOYEE = ["employé par", 'employee']
  EMPLOYER = ["employeur de", 'employer']
  attr_reader :first, :second
  
  def initialize(first, second)
    @first = first
    @second = second
  end
  
  def self.new_for_party(party)
    first = Relationship.new(:first_party => party)
    second = Relationship.new(:third_party => party)
    
    self.new(first, second)
  end
  
  def self.create(params, attributes = {})
    
    raise ArgumentError("Expected a hash with two elements") unless params.is_a?(Hash) && params.size == 2
    
    first = params.keys[0]
    first_options =  params[first].to_a
    second = params.keys[1]
    second_options = params[second].to_a
    
    Relationship.transaction do
      first_relation  = first.relationships.build(
            {:third_party => second, :description => first_options[0] }.reverse_merge(attributes)
          )
      first_relation.tag = first_options[1].to_s if first_options[1]
      first_relation.save!
    
      second_relation = second.relationships.build(
            {:third_party => first, :description => second_options[0], 
              :created_at => first_relation.created_at }.reverse_merge(attributes)
          )
      second_relation.tag = second_options[1].to_s if second_options[1]
      second_relation.save!
      
      self.new(first_relation,second_relation)
    end
  end
  
  def destroy
    Relationship.transaction do
      @first.destroy
      @second.destroy(@first.deleted_at)
    end
  end
  
  def restore
    Relationship.transaction do
      @first.update_attributes(:deleted_at => nil)
      @second.update_attributes(:deleted_at => nil)
    end
  end
  
  def force_destroy
    Relationship.transaction do
      @first.force_destroy
      @second.force_destroy
    end
  end
  
  def update_attributes(attrs)
    Relationship.transaction do
      @first.update_attributes(:description => attrs[:first_description], :principal => attrs[:principal].to_s == "1")
      @second.update_attributes(:description => attrs[:second_description], :principal => attrs[:principal].to_s == "1")
    end
  end
  
  def self.find(first_relation)
    first_relation = Relationship.find(first_relation) unless first_relation.is_a?(Relationship)
    
    second_relation = Relationship.find(:first, 
              :conditions => ["first_party_id = ? and third_party_id = ? and created_at = ?",
                                first_relation.third_party_id, first_relation.first_party_id, first_relation.created_at])
                                
    self.new(first_relation, second_relation)
  end
  
  def active?
    @first.active? && @second.active?
  end
  
  def principal?
    @first.principal? && @second.principal?
  end
  
  # Plumbing
  def reload
    @first.reload
    @second.reload
  end
  
  def to_params
    @first.id
  end
  
  def inspect
    "first #{@first.id} second #{@second.id}"
  end
  
  def ==(other)
    other = Relation.find(other) unless other.is_a?(Relation)
    [@first.id, @second.id].sort == [other.first.id, other.second.id].sort
  end
end