class MessagesController < ApplicationController
  require_permission 'create_messages', :except => [:show, :preview]
  
  def auto_complete_for_ccs
    term = (params[:message][:to] or params[:message][:cc])
    @parties = Party.find(:all, :conditions => ["LOWER(name) LIKE ?", "%#{term.downcase}%"], :limit => 10)
    render :partial => 'auto_complete_for_ccs'
  end
  
  def show
    @message = Message.find(params[:id])
    
    @message_recipient = current_user.received_messages.find(:first, :conditions => ["message_id = ?", @message.id])
    @message_recipient.read! if @message_recipient
    respond_to do |wants|
      wants.html { render :action => "show"}
      wants.print { render :layout => false }
    end
  end
  
  def new
    
    if params[:reply_to]
      reply = Message.find(params[:reply_to])
      @message = reply.new_reply
    elsif params[:reply_to_all]
      reply = Message.find(params[:reply_to_all])
      @message = reply.new_reply_all
    elsif params[:forward]
      @forwarded = Message.find(params[:forward])
      @message = @forwarded.new_forward
    else
      to = params[:email_id] ? Email.find(params[:email_id]) : nil
      to ||= (MailingList.find(params[:mailing_list_id]).recipients if params[:mailing_list_id])
      @message = Message.new(:author_id => current_user.id, :to => to.to_s)
    end
  end
  
  def create
    attachments = extract_multifile

    @message = Message.new(params[:message].merge(:uploaded_attachments => attachments) )
    
    if params[:forward]
      if @forwarded = Message.find(params[:forward])
        @forwarded.attachments.each do |att|
          clone = att.clone
          clone.temp_data = File.read(att.full_filename)
          @message.attachments << clone
        end
      end
    end
    
    respond_to do |format|
      if @message.save
        #flash[:notice] = 'Message'
        format.html do
          redirect_for_sent_message
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @message = Message.find(params[:id])
    if !@message.draft?
      redirect_to @message
      return
    end
    render :action => 'new'
  end
  
  def update
    @message = Message.find(params[:id])
    respond_to do |wants|
      if @message.update_attributes(params[:message]) && @message.message_recipients.each(&:save)
        wants.js { render :text => 'ok' }
        wants.html { redirect_for_sent_message }
      else
        wants.html { render :action => 'edit' }
      end
    end
  end
  
  #TODO : better name
  def preview
    @message = Message.find(params[:id])
    render :partial => 'preview'
  end
  
  # TODO: maybe use update?
  # def read_status
  #   respond_to do |format|
  #     if params[:message_id]
  #       @message = Message.find(params[:message_id])
  #       if current_user.has_permission?("admin")
  #         @mail = MessageRecipient.find(:first, :conditions => ["message_id = ? and (recipient_id = ? or recipient_id is null)", @message.id, current_user.id])
  #       else
  #         @mail = MessageRecipient.find(:first, :conditions => ["message_id = ? and recipient_id = ?", @message.id, current_user.id])
  #       end
  #       @mail.change_read_status
  # 
  #       format.js
  #     end
  #   end
  # end
  
  def extract_multifile
    i = 0
    attachments = []
    while params['file_'+i.to_s]
       attachments << {:uploaded_data => params['file_'+i.to_s]}
       i += 1
    end
    attachments
  end
  
  def redirect_for_sent_message
    if @message.draft?
      redirect_to edit_message_url(@message)
    else
      redirect_to inbox_url 
    end
  end
end