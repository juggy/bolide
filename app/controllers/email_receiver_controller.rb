require 'fastercsv' 
require 'net/http'
require 'tmail'
require 'tempfile'

class LocalFile
 # The filename, *not* including the path, of the "uploaded" file
 attr_accessor :original_filename
 # The content type of the "uploaded" file
 attr_accessor :content_type

 def initialize(name, file, type)
  @content_type = type
  @original_filename = name
  @tempfile = file
 end

 def path #:nodoc:
  @tempfile.path
 end
 alias local_path path

 def method_missing(method_name, *args, &block) #:nodoc:
  @tempfile.send(method_name, *args, &block)
 end
end


class EmailReceiverController < ApplicationController
  skip_before_filter :set_current_project
  
  def create
    message = nil
    
    #check if there are any attachments
    attachments = []
    params[:attachments].to_i.times do |i|
      att = request.env["rack.request.form_hash"]["attachment#{i + 1}"]
      attachments << create_attachment(att)
    end
    
    #check from params to see if it matches the user emails
    unless email_for_user?(TMail::Address.parse(params[:from]).address)
      logger.info("Invalid Message for user #{current_user.full_name}.")
      render :nothing=>true
      return
    end
    
    Message.transaction do 
      # let's create the entry
      message = Message.create!( {
        :author_id => current_user.id,
        :sender => params[:from],
        :subject =>   TMail::Unquoter.unquote_and_convert_to(params[:subject], 'utf-8'),  
        :body => MailReceiver.convert_to_utf8(params[:html]),
        :text_body => MailReceiver.convert_to_utf8(params[:text]),
        :state => "received", 
        :to => @mail.to_addrs,
        :cc => @mail.cc_addrs,
        :content_type=>@mail.content_type,
        :mentions => find_mentions(params[:text]),
        :created_at => email_date(@mail),
        :rfc2822_message_id => get_message_id(@mail),
        :rfc2822_in_reply_to_id  => (@mail.in_reply_to || []).first
      })
      
      #create the attachments
      attachments.each do |att|
        message.attachments.create(:uploaded_data=>att)
      end
      
    end
    logger.info("Message (id=#{message.id}) saved.")
    render :nothing=>true
  end
  

  
protected

  def dropbox
    unless @dropbox
      #find the account based on the dropbox name used.
      @mail = TMail::Mail.parse(params[:headers])
      
      dropboxes = []
      dropboxes = dropboxes | find_dropbox(@mail.to_addrs) if @mail.to_addrs
      dropboxes = dropboxes | find_dropbox(@mail.cc_addrs) if @mail.cc_addrs
      dropboxes = dropboxes | find_dropbox([@mail.header["delivered-to"]]) if @mail.header["delivered-to"]
      dropboxes.flatten!
      @dropbox = dropboxes.first
    end
    @dropbox
  end

  def current_user
    unless @current_user 
      if dropbox
        
        begin
          matches = dropbox.address.match( /^reception-(.*)@(.*)\.ccubeapp\.com/i )
          @current_user = User.find(matches[1])
        rescue ActiveRecord::RecordNotFound => e
          notify_hoptoad(e)
        end
          
      end
    end
    @current_user
  end
  
  def require_user
    unless current_user
      logger.info("Rejected email " + params[:subject])
      render :nothing=>true, :status=>200
    end
  end

  def load_current_account
    @no_account_redirect = true
    #should have a single drop box
    if dropbox
      matches = dropbox.address.match( /^reception-(.*)@(.*)\.ccubeapp\.com/i ) 
      @account_domain = matches[2]
      logger.info("Email account found #{@account_domain}")
    end
    begin
      super
    rescue ScopedByAccount::MissingAccountError => e
      notify_hoptoad(e)
      render :nothing=>true, :status=>200
    end
  end

  def account_subdomain
    @account_domain
  end

  def find_dropbox(addrs)
    addrs.select do |a|
      ((a.address =~ /^reception-.*@.*\.ccubeapp\.com/i) == 0)
    end
  end
  
  def create_attachment(att)
    #get the attachment from the tmp url
    LocalFile.new(att[:filename],  att[:tempfile], att[:type])
  end
  
  def email_date(mail)
    begin 
     
     return mail.date
     
    rescue ArgumentError => e
     logger.error "problem with email date"
     logger.error e.message
     logger.error e.backtrace
     return Time.now
    end
  end
  
  def get_message_id(mail)
    mail.message_id ? mail.message_id : (mail.header["message-id"].instance_variable_get(:@body) || "").strip
  end
  
  def find_mentions(text)
    mentions = text.scan(/(#{Email.email_name_regex}@#{Email.domain_head_regex}#{Email.domain_tld_regex})/io).flatten.uniq
    mentions.collect { |party| TMail::Address.parse(party) }
  end
  
  def email_for_user?(email)
    Party.find_by_email(email).each do |p|
      return true if p.user_id == current_user.id
    end
    return false
  end
  
  def user_for_email(email)
    pid = Email.find_party_id(self.email)
    p = Party.find(pid)
    return User.find_by_id(p.user_id) if(p && p.user_id)
  end

end