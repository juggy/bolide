class MessageSender < ActionMailer::Base

  def message(msg, sent_at = Time.now)
    email_builder = ActionView::Base.new
    @subject    = msg.subject

    @recipients = msg.to_list
    @cc         = msg.cc_list
    @from       = (msg.author ? msg.author.email : msg.sender_email) #TODO: maybe refactor so that sender_email is always set
    @sent_on    = sent_at
    @headers    = {"In-Reply-To" => msg.rfc2822_in_reply_to_id}
    
    content_type "text/html"
    @charset = "utf-8"
    if msg.author
      @body['body'] = email_builder.render(
            :inline => simple_format(msg.body) + "<br />---<br />" + Signature.new(msg.author).render,
            :locals => {:first_name => msg.author.first_name, :last_name => msg.author.last_name, :my_phone => msg.author.phone, :my_email => msg.author.email, :my_suffix => msg.author.suffix }
          )
    else
      @body['body'] = simple_format(msg.body)
    end
    
    #end
    
    msg.attachments.each do |file|

      attachment file.content_type do |a|
        a.body = File.read(file.full_filename)
        a.filename = Attachment.normalize_filename(file.filename)
      end

    end
    
  end
  
  private

  def simple_format(text)
    text = text.gsub(/\r\n?/, "\n") 
    text = text.gsub(/\n\n+/, "</p>\n\n<p>")
    text = text.gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')
    return "<p>#{text}</p>"
  end
end