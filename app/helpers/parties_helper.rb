module PartiesHelper
  
  def auto_complete_party_id_text_field( object, method, options = {})
    text_field_tag( "party_name", options.delete(:value) || "", {:autocomplete => "off", :id => "#{object.to_s}_party_name" }.merge( options.except(:url, :id) ) ) +
    hidden_field_tag( "#{object.to_s}[#{method.to_s}]", "", :id => "#{method.to_s}" ) +
    content_tag("div","", :id => "#{object.to_s}_party_name_auto_complete", :class => "auto_complete", :style => "display:hidden;") +
    auto_complete_field( "#{object.to_s}_party_name", 
          {:url => {:controller => 'parties', :action => 'auto_complete_for_party_name'}.merge(options[:url] || {}),
          :select => 'informal',
          :after_update_element => 
            "function(element,value)  {
               var nodes = value.getElementsByClassName('auto_id') || [];
               if(nodes.length>0) id_value = Element.collectTextNodes(nodes[0],'auto_id');
               $('#{method.to_s}').value = id_value;
               #{options[:after_update_id] unless options[:after_update_id].blank?}
             }"
            } ) 
  end
  
  # TODO: DRY methods
  def auto_complete_project_id_text_field( object, method, options = {})
    text_field_tag( "project_no_search", "", {:autocomplete => "off", :id => "#{object.to_s}_project_no" } ) +
    hidden_field_tag( "#{object.to_s}[#{method.to_s}]", "", :id => "#{method.to_s}" ) +
    content_tag("div","", :id => "#{object.to_s}_project_no_auto_complete", :class => "auto_complete", :style => "display:hidden;") +
    auto_complete_field( "#{object.to_s}_project_no", 
          {:url => {:controller => 'projects', :action => 'auto_complete_for_project_no'},
          :select => 'informal',
          :after_update_element => 
            "function(element,value)  {
               var nodes = value.getElementsByClassName('auto_id') || [];
               if(nodes.length>0) id_value = Element.collectTextNodes(nodes[0],'auto_id');
               $('#{method.to_s}').value = id_value;
               #{options[:after_update_id] unless options[:after_update_id].blank?}
             }"
            } ) 
  end
  
  def display_contact_data( item, options = {})
    str = "#{item.name}#{':' unless item.name.blank?} #{item.value}" 
    if options[:link_prefix] == "mailto:"
      #mail_link(item.value, item.party.id)
      if Account.current_account.tc?
        link_to item.value, new_message_path(:email_id => item.id)
      else
        mail_to item.value
      end
    else
      if options[:link_prefix]
        link_to str, "#{options[:link_prefix]}#{item.value}"
      else
        str
      end
    end
  end
  
  def display_address(address, map_link = true)
    link = map_link ? link_to( _("carte"), address.map_url, :popup => true, :class => "google_map") : ""
    content_tag("address",
        address.to_s.gsub("\n", "<br />") + link
      )
  end
end