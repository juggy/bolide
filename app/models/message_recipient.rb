# == Schema Information
# Schema version: 20090408154321
#
# Table name: message_recipients
#
#  id         :integer(4)      not null, primary key
#  message_id :integer(4)      
#  user_id    :integer(4)      
#  state      :string(20)      
#  email      :string(255)     
#  kind       :string(20)      default("to")
#  name       :string(255)     
#  party_id   :integer(4)      
#  created_at :datetime        
#

# == Schema Information
# Schema version: 76
#
# Table name: message_recipients
#
#  id         :integer(11)     not null, primary key
#  message_id :integer(11)     
#  user_id    :integer(11)     
#  state      :string(255)     
#  email      :string(255)     
#  kind       :string(20)      default("to")
#  name       :string(255)     
#  party_id   :integer(11)     
#  created_at :datetime        
#
class MessageRecipient < ScopedByAccount
  cattr_reader :per_page
  @@per_page = 20
  
  belongs_to :message
  belongs_to :user
  belongs_to :party
  
  validates_presence_of :email, :on => :create, :message => "Destinataire invalide"
  validates_format_of   :email, :with => Email.email_regex
  
  delegate   :author, :subject, :body, :sender, :recipients, :to => :message
  
  named_scope :unread, :conditions => "state = 'unread'"
  named_scope :read, :conditions => "state = 'read'"
  named_scope :active, :conditions => "state NOT IN ('trash', 'archived', 'to_delete')"
  named_scope :trash, :conditions => "state = 'trash'"
  named_scope :archived, :conditions => "state = 'archived'"
  
  # renamed :to scope because of issue with rails 2.1
  named_scope :kind_to,     :conditions => "kind = 'to'"
  named_scope :cc,     :conditions => "kind = 'cc'"
  named_scope :mention,     :conditions => "kind = 'mention'"
  named_scope :kind_from,     :conditions => "kind = 'from'"
  
  named_scope :for_min_date, lambda { |d|
     return {} if d.blank?
     d = d.to_date
     {:conditions => ["created_at >= ?", d]}
  }
  
  named_scope :for_max_date, lambda { |d|
     return {} if d.blank?
     d = d.to_date
     {:conditions => ["created_at <= ?", d]}
  }
  
  def recipient
    #TODO: use user name or party instead when available?
    name.blank? ? email : "#{name} <#{email}>"
  end
  
  def recipient=(rec)
    self.email, self.name = Email.parse(rec)
  end
  
  def is_highlighted?
    email_highlighted = ["ventes@toit-couture.qc.ca", "vent.sthub@toit-couture.qc.ca"]
    if self.email
      return email_highlighted.include?(self.email.downcase) ? true : false
    else
      return false
    end
  end
  
  def before_create
    self.created_at = message.created_at
    
    # Attach first to a user, if none than try to a party
    self.user ||= User.find_by_email(self.email) if self.email
    pid = Email.find_party_id(self.email)
    if pid
      p = Party.find(pid)
      self.party_id = pid
    end
  end
  
  attr_accessor :internal_cc # used to make sure no recursive creation (but it also prevents redirect of a redirect, which could happen)
  def after_create
    # Create the desired cc for internal routing of messages
    unless @internal_cc
      ccs = Email.find_internal_ccs(self.email)
      for cc in ccs
        if !self.message.message_recipients.reload.any? {|r| r.party_id == cc.party_id }
          if cc.party.user_id
            self.message.message_recipients.create!(:user_id => cc.party.user_id, :email => self.email, :kind => 'bcc', :state => 'unread', :internal_cc => true)
          end
        end
      end
    end
  end
  
  def attach_to_party(options = {})
    if party
      party.linked_messages.create({:message_id => self.message_id}.merge(options))
    end
  end
  
  def inbox!
    update_attribute('state', 'read')
  end
  
  def trash!
    update_attribute('state', 'trash')
  end
  
  def archive!
    update_attribute('state', 'archived')
  end
  
  def mark_for_deletion!
    update_attribute('state', 'to_delete')
  end
  
  def archived?
    self.state == 'archived'
  end
  
  def trash?
    self.state == 'trash'
  end
  
  def read!
    update_attribute('state', 'read') if unread?
  end
  
  def read?
    self.state == 'read'
  end
  
  def unread?
    self.state == 'unread'
  end

end
