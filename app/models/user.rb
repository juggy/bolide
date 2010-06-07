# == Schema Information
# Schema version: 20090408154321
#
# Table name: users
#
#  id                        :integer(4)      not null, primary key
#  first_name                :string(255)     
#  last_name                 :string(255)     
#  email                     :string(255)     
#  login                     :string(255)     
#  identity_url              :string(255)     
#  crypted_password          :string(40)      
#  salt                      :string(40)      
#  remember_token            :string(255)     
#  remember_token_expires_at :datetime        
#  deleted                   :boolean(1)      
#  my_language               :string(20)      
#  last_login                :datetime        
#  created_at                :datetime        
#  updated_at                :datetime        
#  project_letter            :string(1)       
#  html_signature            :text            
#  phone                     :string(255)     
#  cell                      :string(255)     
#  can_email                 :boolean(1)      default(TRUE)
#  access_key                :string(255)     
#  separator                 :string(255)     default(";")
#  suffix                    :string(255)     
#

require 'digest/sha1'
class User < ScopedByAccount
  
  strip_attributes! :only => [:email, :login]
  
  acts_as_authentic do |c|
    c.act_like_restful_authentication = true
    c.validations_scope = :account_id
    
    c.merge_validates_length_of_email_field_options     :if => :system_user?, :message => 'Email trop court'
    c.merge_validates_format_of_email_field_options     :if => :system_user?, :message => "Email n'est pas valide"
    c.merge_validates_uniqueness_of_email_field_options :if => :system_user?, :message => "Email déjà associé à un autre usager"
    
    c.merge_validates_format_of_login_field_options     :if => :system_user?, :message => 'Identifiant ne peut contenir que des lettres, chiffres et .-_'
    c.merge_validates_length_of_login_field_options     :if => :system_user?, :message => 'Identifiant doit avoir au moins 4 caractères'
    c.merge_validates_uniqueness_of_login_field_options :if => :system_user?, :message => 'Cet identifiant est déjà utilisé par un autre usager'
    
    c.merge_validates_confirmation_of_password_field_options        :if => :password_required?, :message => 'Le mot de passe ne concorde pas avec la confirmation'
    c.merge_validates_length_of_password_confirmation_field_options :if => :password_required?, :message => 'Le mot de passe doit contenir au moins 4 caractères'
    c.merge_validates_length_of_password_field_options              :if => :password_required?, :message => 'Le mot de passe doit contenir au moins 4 caractères'
  end

  ACCESS_LEVELS = [
    ['opération (niveau 0)',  0].freeze,
    ['soutien (niveau 1)',   10].freeze,
    ['direction (niveau 2)', 20].freeze
  ].freeze
  
  # cattr_accessor :current_user (non thread safe)
  ### Funky evil stuff (thread_safe)
  def self.current_user
    Thread.current[:current_user]
  end
  
  def self.current_user=(user)
    Thread.current[:current_user] = user
  end
  
  attr_protected :role_ids, :permission_ids
    
  # Application specific stuff
  has_many :activities
  has_many :tasks
  
  has_one :contact
  belongs_to :team_leader, :class_name => "User", :foreign_key => "team_leader_id"
  has_many :team_members, :class_name => "User", :foreign_key => "team_leader_id"
  belongs_to :technology
  belongs_to :department
  
  has_many :received_messages, :class_name => 'MessageRecipient', :foreign_key => 'user_id', :order => 'created_at desc'
  has_many :sent_messages, :class_name => 'Message', :foreign_key => 'author_id', :order => 'created_at desc'
  
  has_many :permissions
  
  has_many :time_entries
  
  named_scope :ascend_by_name, :order => "users.last_name, users.first_name"
  named_scope :active, :conditions => ["deleted = ?",false], :order => "users.last_name, users.first_name"
  named_scope :system_user, :conditions => {:system_user => true}
  named_scope :non_system_user, :conditions => {:system_user => false}
  named_scope :can_see_their_emails, lambda { |current_user|
    ids = User.
            find(:all, :include => :permissions, :conditions => {:permissions => {:name => 'create_messages'} } ).
            reject {|user| user.access_level == 20}.
            map {|u| u.id}
            
    return {} if ids.empty? 
    {:conditions => ["id IN (?)", ids] }
  }
  
  # named_scope :documenter, :conditions => ["id IN (?)",  ], :order => "last_name, first_name"
  def self.documenter
    Role.find_by_name('responsable documents').users.active
  end
  
  named_scope :with_role, lambda { |role_name|
    { :include => :roles, :conditions => {:roles => {:name => role_name} }}
  }
  
  def self.schedulable
    self.active.with_role(["couvreur", "chef d'équipe"])
  end
  
  
  def self.to_select_options(options = {}, collection = nil)
    options.reverse_merge!(:all_label => "choisir une personne...")
    select = ( collection || self.active  ).map {|u| [options[:size] == "short" ? u.short_name : u.full_name, u.id] }
    select.unshift([options[:all_label],nil]) unless options[:all_label].nil?
    select
  end
  
  attr_accessor :has_contact

  validates_presence_of     :first_name,  :message => "Prénom requis"
  validates_presence_of     :last_name,   :message => "Nom requis"
  validates_presence_of     :separator,   :message => "Choisissez ',' ou ';' en fonction de votre ordinateur."
    
  after_create :create_contact
  
  has_many :role_memberships
  has_many :roles, :through => :role_memberships
  
  def full_name
    self.last_name + " " + self.first_name
  end
  
  def available_on?(date)
    if unavailable_from.present? && unavailable_to.present?
      date < unavailable_from || date >= unavailable_to
    else 
      true
    end
  end
  
  def name_and_level
    name = self.to_s
    level = employee_level
    level.present? ? "#{name} (#{level})" : name
  end
  
  def short_name
    [ first_name_initials, self.last_name ].compact.join(" ")
  end
  
  def first_name_initials
    initials = self.first_name.split("-")
    initials = initials.map {|i| i.mb_chars[0,1].capitalize }
    "#{initials.join("-")}."
  end
  
  def to_s
    if technology_id
      "#{full_name} (#{technology})"
    else
      full_name
    end
  end
  
  def role_list
    roles.collect(&:name).join(", ")
  end
  
  def active?
    !self.deleted
  end
  
  # Hack for authlogic to deny access
  def approved?
    self.system_user?
  end
  
  def employee_number
    self.contact.employee_info.employee_number rescue nil
  end
  
  def employee_level
    self.contact.employee_info.level.to_s rescue nil
  end
  
  def absence_for(date)
    if self.contact
      self.contact.absences.find(:first, :conditions => ["(start_date = ? AND end_date is NULL) OR (start_date <= ? AND end_date >= ?)", date, date, date] )
    end
  end
  
  def self.has_no_contact( current_user_id = nil)
    sql = "OR id = #{current_user_id}" if current_user_id
    self.find_by_sql("select * from users where (id NOT IN (select IFNULL(user_id, 0) from parties) #{sql} ) AND deleted = false AND users.account_id = #{Account.current_account_id} ORDER by last_name, first_name")
  end
  
  # emails = "ben@2ret.com, bthouret@codegenome.com"
  def self.recipients(emails_to, emails_cc)
    ids = "'" + (emails_to + emails_cc).join("','") + "'"
    User.find(:all, :conditions => "email IN (#{ids})")
  end
  
  
  ### PERMISSIONS
  def has_permission?(permission)
    raise "invalid permission" unless Permission::PERMISSIONS.include?(permission)
    
    @permission_names ||= self.permissions.collect(&:name)
    return true if @permission_names.include?("admin")
    
    (@permission_names.include?(permission.to_s) )
  end
  
  def has_this_permission?(permission)
    @permission_names ||= self.permissions.collect(&:name)
    (@permission_names.include?(permission.to_s) )
  end
  
  
  def set_permissions(new_permissions)
    Permission.transaction do
      
      # remove old permission
      self.permissions.each do |p|
        p.destroy unless new_permissions.include?(p.name)
      end
      
      # add new permissions
      new_permissions.each do |perm|
        next if self.permissions.detect {|p| p.name == perm}
        self.permissions.create(:name => perm)
      end
    end
    
    self.permissions.reload
    nil
  end
  
  def has_hr_permission?( employee )
    other_user = employee.is_a?(User) ? employee : employee.user
    return false unless other_user
    return true if self.has_permission?('admin')
    # 
    self.access_level > other_user.access_level &&
    self.has_permission?("access_human_resource_infos")
  end
  
  def access_level_name
    ACCESS_LEVELS.detect {|al| self.access_level == al[1] }[0]
  end
  
  def can_create_users?
    has_permission?('admin') || has_permission?('access_human_resource_infos')
  end
  
  ##### OLD ROLES
  
  def has_role?(role)
    @role_names ||= self.roles.collect(&:name).compact
    #return true if @role_names.include?("admin")
    (@role_names.include?(role.to_s) )
  end
  
  def set_roles(role_ids)
    self.role_memberships.clear
    self.roles << Role.find(role_ids) if role_ids.size > 0
  end

  protected
  
  # after filter
  def create_contact
    if has_contact == "1"
      company = Company.find(SystemSetting.owner_id)
      contact = Contact.create(:first_name => first_name, :last_name => last_name, :company_name => company.name, :user_id => id) if company
      contact.emails.create(:value => email) if contact && !self.email.blank?
    end
  end
  
  def password_required?
    self.system_user? && (crypted_password.blank? || !password.blank?)
  end
end
