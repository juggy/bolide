module MessagesHelper
  
  def display_recipient_list(recipients, format = :link)
    links = []
    recipients.each do |r|
      links << ((r.party && format == :link) ? link_to( r.party.name, r.party, :title => r.email ) : h(r.recipient) )
    end
    links.join(", ")
  end
  
  def message_list(collection, &proc)
    if collection.size > 0
      concat will_paginate(collection).to_s, proc.binding
      yield
      concat will_paginate(collection).to_s, proc.binding
    else
      concat render( :partial => '/widgets/blank' ), proc.binding
    end
  end
  
  def subject_wrap(message)
    email_title = message.subject.blank? ? "Pas de titre" : h(message.subject)
    url = message.draft? ? edit_message_url(message) : message
    title_link = link_to email_title , url, {:class => "subject_text"}
    body_snippet = link_to truncate(h(message.text), :length => 100), url, {:class => "snippet"}
    %(<div class="subject_wrap">
        #{title_link}
      <div class="snippet_wrap">
        #{body_snippet}
      </div>
    </div>)
  end
  
  def check_all_delete(options = {}, &proc)
    options.reverse_merge!( { :delete_label => _("Supprimer les messages"), :confirm => 'Êtes-vous sûr de vouloir définitivement supprimer ces messages?' } )
    check_box = "#{check_box_tag( 'checkAll' )}&nbsp;<label for='checkAll'>#{_("cocher tout")}</label>"
    delete_button = button_to_function options[:delete_label], "#{"if (confirm('#{options[:confirm]}'))" if options[:confirm]} form.submit();" unless options[:no_delete]
    observer = observe_field('checkAll', :function => 
      "$$('#inbox_messages tr input[type=checkbox]').each(function(checkbox){
          checkbox.checked = $('checkAll').checked;
      })") 
    
    note = options[:note] ? "<br/>#{options[:note]}" : ""
    
    concat "#{check_box} #{delete_button}", proc.binding
    yield if block_given?
    concat "#{observer} #{note}", proc.binding
  end
  
  def check_all_trash_options
    options = {:no_delete => true}
    if current_user.has_permission?('destroy_messages')
      options = {:note => 'Note: Seuls les messages non liés à un contact peuvent être supprimés.'}
    end
    options
  end
  
  def message_icons(message)
    icons = []
    icons << image_tag("attachment.png") if message.has_attachments?
    icons << image_tag("link.png") if message.attached?
    icons.join(" ")
  end
  
  def message_status(message_recipient)
    return "class='trash_message'" if message_recipient.trash?
    return "class='new_message'" if !message_recipient.read?
    ""
  end
  
  def sent_status(message)
    return "class='error_message'" if message.error?
    return "class='draft_message'" if message.draft?
    return "class='unsent_message'" if !message.sent?
    ""
  end
  
  def generate_signature(user)
    Signature.new(user).render
  end
  
  def text_around_filter(f, text, truncate_size = 60)
    return "" if text.nil? || text.empty?
    return truncate(text, :length=>truncate_size, :omission=>"...") if f.nil? || f.empty?
    return text if text.size <= truncate_size
    
    match = text =~ /#{f}/i
    if(match)
      size = text.size
      length = (truncate_size - f.size)/2
      
      first = match - length
      second = match + length
      
      #do not overrun
      if(first < 0)
        over = 0 - first
        first = 0
        second += over
      end
      if(second >= size)
        over = second - size
        second = size - 1 
        first -= over
        first = 0 if first < 0
      end
      prepend = (first == 0 ? "" : "...")
      append = (second == size - 1 ? "" : "...")
      return prepend + text[first..second] + append
    end
    return truncate(text, :length=>truncate_size, :omission=>"...")
  end
  
  def highlight_filter(f, text)
    return "" if text.nil? || text.empty?
    return text if f.nil? || f.empty?
    text.gsub(/(#{f})/i, '<em>\1</em>')
  end
  
  # private

  # def alt_status(message)
  #   user_message = MessageRecipient.find(:first, :conditions => ["message_id = ? and recipient_id = ?", message.message_id, current_user.id]) || nil
  #   user_message.is_read? ? "unread" : "read" if user_message
  # end
end