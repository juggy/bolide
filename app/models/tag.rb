# == Schema Information
# Schema version: 20090408154321
#
# Table name: tags
#
#  id   :integer(4)      not null, primary key
#  name :string(255)     
#

class Tag < ScopedByAccount
  has_many :taggings
  
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  validates_uniqueness_of :name, :scope => :account_id
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end
  
  # Application extensions
  def self.find_most_used_tag_by_type(type_name)
    if ['Contact', 'Building', 'Company'].include?(type_name)
      self.find_by_sql(
      "SELECT count(1) as count, tags.name FROM tags WHERE tags.account_id = #{Account.current_account_id} AND id IN 
          (SELECT tag_id FROM taggings t WHERE taggable_type = 'Party' AND taggable_id IN 
              (SELECT id FROM parties WHERE type = '#{type_name}')) GROUP BY tags.id ORDER BY count LIMIT 5")
            
    else
      self.find_by_sql(
      "SELECT count(1) as count, tags.name FROM tags WHERE tags.account_id = #{Account.current_account_id} AND id IN 
          (SELECT tag_id FROM taggings t WHERE taggable_type = '#{type_name}') GROUP BY tags.id ORDER BY count LIMIT 5")
    end.collect(&:name)
  end
  
  def self.find_by_type(type_name)
    if ['Contact', 'Building', 'Company'].include?(type_name)
      self.find_by_sql(
      "SELECT * FROM tags WHERE tags.account_id = #{Account.current_account_id} AND id IN 
          (SELECT tag_id FROM taggings t WHERE taggable_type = 'Party' AND taggable_id IN 
              (SELECT id FROM parties WHERE type = '#{type_name}')) ORDER BY name")
            
    else
      self.find_by_sql(
      "SELECT * FROM tags WHERE tags.account_id = #{Account.current_account_id} AND id IN 
          (SELECT tag_id FROM taggings t WHERE taggable_type = '#{type_name}') ORDER BY name")
    end
  end
end
