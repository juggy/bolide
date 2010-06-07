# == Schema Information
# Schema version: 20090408154321
#
# Table name: messages
#
#  id                     :integer(4)      not null, primary key
#  author_id              :integer(4)      
#  state                  :string(20)      
#  sender_email           :string(255)     
#  sender_name            :string(255)     
#  subject                :string(255)     
#  body                   :text            
#  content_type           :string(255)     
#  rfc2822_message_id     :string(255)     
#  rfc2822_in_reply_to_id :string(255)     
#  created_at             :datetime        
#  updated_at             :datetime        
#  linked_messages_count  :integer(4)      default(0)
#  no_inbox               :boolean(1)      
#  private                :boolean(1)      
#  text_body              :text            
#  send_retries           :integer(4)      default(0)
#

class Message < ScopedByAccount
  
  cattr_reader :per_page
  @@per_page = 20
  
  belongs_to :author, :class_name => "User"
  has_many :message_recipients, :dependent => :destroy
  
  has_many :user_recipients, :class_name => 'MessageRecipient', :foreign_key => 'message_id', :conditions => 'user_id is not null'
  
  
  has_many :attachments, :as => :attachable, :dependent => :nullify
  has_many :linked_messages, :dependent => :destroy
  has_many :parties, :through => :linked_messages
  
  validates_associated :message_recipients, :on => :create, :message => "Destinataire invalide"
  validates_uniqueness_of :rfc2822_message_id, :on => :create, :message => "Message pre-existant"
  
  named_scope :unsent, :conditions => "state = 'unsent'"
  named_scope :draft, :conditions => "state = 'draft'"
  named_scope :sent, :conditions => "state = 'sent'"
  named_scope :error, :conditions => "state = 'error'"
  named_scope :no_inbox, :conditions => "state = 'received' and no_inbox = 1 and linked_messages_count = 0", :order => 'created_at desc'
  
  attr_accessor :from, :to, :cc, :mentions, :project_no
  
  define_index do
      indexes :subject, :body, :text_body
      indexes message_recipients.email, message_recipients.name
      set_property :delta => true
      has :account_id, :created_at
  end
  
  def to
    @to || to_list.join(", ")
  end
  def cc
    @cc || cc_list.join(", ")
  end
  
  def from
    @from || from_list.join(", ")
  end
  
  def to_list
    message_recipients.kind_to.collect {|r| r.party }.compact
  end
  
  def cc_list
    message_recipients.cc.collect {|r| r.party }.compact
  end
  
  def from_list
    message_recipients.kind_from.collect {|r| r.party }.compact
  end
  
  def mention_list
    message_recipients.mention.collect {|r| r.party }.compact
  end
  
  def party_list
    #all tos, ccs, sender and mention
    (from_list | to_list | cc_list | mention_list).uniq
  end
  
  def sender(format = :long)
    if author
      format == :email ? "#{author.full_name} <#{author.email}>" : author.full_name
    else
      sender_name.blank? ? sender_email : 
        (format == :short) ? sender_name :
        "#{sender_name} <#{sender_email}>"
    end
  end
  
  def sender=(from)
    self.sender_email, self.sender_name = Email.parse(from)
  end
  
  def text
    self.text_body ? self.text_body : (text? ? self.body : "")
  end
  
  def text?
    content_type == "text/plain" || content_type.nil?
  end
  
  def received?
    self.state == 'received'
  end
  
  def sent?
    self.state == 'sent'
  end
  
  def error?
    self.state == 'error'
  end
  
  def draft?
    self.state == 'draft'
  end
  
  attr_accessor :draft
  def draft
    draft?
  end
  def draft=(d)
    if d == true || d == "1"
      self.state = 'draft'
    else
      self.state = 'unsent'
    end
  end
  
  def has_attachments?
    self.attachments.size > 0
  end
  
  def attached?
    self.linked_messages_count > 0
  end
  
  def type_title
    return _("Message reçu") if self.received? 
    return _("Message envoyé") if self.sent?
    return _("Ce message n'a pu être envoyé") if self.error?
    return _("Message non envoyé")
  end
  
  
  def new_reply(author = User.current_user)
    Message.new(:to => self.sender(:email), :subject => reply_subject, :body => reply_body, :rfc2822_in_reply_to_id => self.rfc2822_message_id, :author => author)
  end
  
  def new_reply_all(author = User.current_user)
    tos = ((self.to_list - [author.email]) << sender(:email)).join(", ")
    ccs = self.cc_list.join(", ")
    Message.new(:to => tos, :cc => ccs, :subject => reply_subject, :body => reply_body, :rfc2822_in_reply_to_id => self.rfc2822_message_id, :author => author)
  end
  
  def new_forward(author = User.current_user)
    Message.new(:subject => forward_subject, :body => forward_body, :rfc2822_in_reply_to_id => self.rfc2822_message_id, :author => author)
  end
  
  def reply_subject
    subject.sub(/^(Re: )?/, "Re: ")
  end
  
  def forward_subject
    subject.sub(/^(Tr: )?/, "Tr: ")
  end
  
  def reply_body
    "\r\n\r\n" + 
    word_wrap(text, 80).gsub(/^/, "> ")
  end
  
  def forward_body
    lines = ["\r\n"]
    lines << "----- Message Original ------"
    lines << "> De: #{self.sender}"
    lines << "> A: #{self.to_list.join(", ")}"
    lines << "> Envoyé: #{self.created_at.localize(:long)}"
    lines << "> Sujet: #{self.subject}"
    lines << reply_body
    lines.join("\r\n")
  end
  
  def sent!(tmail)
    self.rfc2822_message_id = tmail.message_id
    self.state = 'sent'
    attach_to_recipients
    self.save!
  end
  
  def error!
    self.update_attribute('state', 'error')
  end
  
  def can_be_made_private?(user)
    can_be_modified_by?(user)
  end
  
  def can_be_modified_by?(user)
    user.id == self.author_id || self.user_recipients.empty? || (self.user_recipients.any? {|r| r.user_id == user.id})
  end
  
  # This method should only be called by the mail sender, 
  # after the message was succesfully sent 
  def attach_to_recipients
    message_recipients.each { |rec| rec.attach_to_party(:user_id => self.author_id, :private => self.private) }
  end
  
  def uploaded_attachments=(files)
    files.each do |f|
      self.attachments.build(f)
    end
  end
  
  # sets boolean flag in db to easily detect messages that no user would get
  # should only be called by mail receiver
  def check_for_inbox!
    c = self.user_recipients.count
    update_attribute('no_inbox', true) if c == 0
  end
  
  def before_save
    self.state ||= 'unsent'
    
    self.sender_name = self.sender_name.gsub(',','') if self.sender_name
  end
  
  def after_save
    if @project_no
      self.linked_messages.create(:project_id => @project_no)
    end
    
    party_list.each do |p|
      self.linked_messages.create(:party_id => p.id, :user_id=>self.author_id) if p
    end
    
    self.linked_messages.each do |l|
      if l.private != self.private
        l.private = self.private
        l.save
      end
    end
  end
  
  
  def before_validation
    RAILS_DEFAULT_LOGGER.info "TO: #{@to}"
    
    author = User.find_by_email(sender_email)
    create_recipients(:from, [sender_email]) if sender_email
    create_recipients(:to, @to) if @to && !@to.empty?
    create_recipients(:cc, @cc) if @cc && !@cc.empty?
    create_recipients(:mention, @mentions) if @mentions && !@mentions.empty?
  end
  
  def destroy
    if !attached? || sent?
      super
    end
  end
  
  protected
  def create_recipients(kind, recipients)
    message_recipients.find(:all, :conditions => {:kind => kind.to_s}).each(&:destroy)
    
    recipients = recipients.split(%r{,\s*}) if recipients.is_a?(String)
    recipients = [recipients] unless recipients.is_a?(Array)
    recipients.each do |r|
      if received?
        # we want to skip 'invalid' email from the receiver, because it might just be a mailing list or just a bcc
        has_email = !Email.parse(r)[0].blank? rescue false
        if has_email
          message_recipients.build(:recipient => r, :kind => kind.to_s, :state => 'unread')
        end
      else
        message_recipients.build(:recipient => r, :kind => kind.to_s, :state => 'unread')
      end
    end
  end
  
  
  # Taken from action pack
  def word_wrap(text, line_width = 80)
    text.split("\n").collect do |line|
      line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end
