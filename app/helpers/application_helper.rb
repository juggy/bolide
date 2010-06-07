# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Zendesk::RemoteAuthHelper
  include CalendarHelper
  include PartiesHelper
  include TasksHelper
  include MessagesHelper
  include AuditHelper
  
  ActionView::Base.default_form_builder = RowFormBuilder
  
  
  def link_to_zendesk
    link_to "support", zendesk_auth_url, :popup => true
  end
  
  def ccube_logo
    "<span style='font-size:24px;font-family:\"Lucida Grande\";color:lightSkyBlue;'>C<sup>3</sup></span>"
  end
  
  def tooltip( name )
    haml_tag :a, :href => "#", :class => "tooltip" do
      haml_concat name
      haml_tag :span do
        yield
      end
    end
  end
  
  def alt_tr(options = {})
    options[:class] = "#{options[:class]} #{cycle('odd', 'even')}"
    haml_tag :tr, options do
      yield
    end
  end
  
  def pagination( collection )
    content_tag('div', will_paginate( collection ), :class => "group w-pagination")
  end
  
  def shortest_date(date)
    now = Time.now
    if date > now.beginning_of_day && date < now.tomorrow.beginning_of_day
      return date.localize("%I:%M%p")
    elsif date > now.beginning_of_year
      return date.localize("%e %b")
    else
      return date.localize(:date)
    end
  end
  
  
  def party_alert
    party = nil
    party = @company
    party ||= @party if @party && @party.is_a?(Party)
    party ||= @party.client if @party && @party.is_a?(Project)
    party ||= @project.client if @project
    
    if party && party.alert.present?
      content_tag("div", 
                    content_tag("h1", "Attention!!! : #{party.display_name}") +
                    simple_format(party.alert), 
                  :id => 'party_alert')
    end
    
  end
  
  def link_to_party(party)
    link_to party.name, party
  end
  
  def party_page_header(party)
    render :partial => "/#{party.class.to_s.tableize}/page_header", :locals => {:party => party}
  end
  
  def mailbox_page_header(opts = {:user_select => false})
    render :partial => '/shared/mailbox_page_header', :locals => opts
  end
  
  def form_submit(submit = nil )
    submit ||= submit_tag( _("Sauver"), :disable_with => 'en cours...') # :onclick => 'this.form.submit();this.disable();' )
    ou = _("ou")
    cancel = link_to _("annuler"), :back, :class => 'action'
    content_tag("div", "#{submit} #{ou} #{cancel}", :class => 'submit' )
  end
  
  # Field autocomplete will submit the form when pressing enter to select
  # This is a workaroud
  def button_form_submit
    form_submit( button_to_function( _("Sauver"), "this.form.submit();this.disable();") )
  end
  
  def error_messages(object)
    if object.errors.count > 0
      #contents = []
      header = "Attention, il y a #{pluralize( object.errors.count, "erreur")}! Vérifier les champs en rouge."
      error_messages = []
      object.errors.each do |attr, msg|
        next if msg.nil? || msg.match(/%\{fn\}/)
        error_messages << msg
      end
      
      error_messages = error_messages.map {|msg| content_tag(:li, msg) }
      msgs = content_tag("ul", error_messages)
      content_tag("div", header + msgs , :class => 'form_error')
    end
  end
  
  def select_options_from_table(model, options = {:all_label => "choisir..", :all => false})
    collection = options[:all] ? model.find(:all) : model.active
    (collection.collect {|m| [m.name,m.id] }).unshift([options[:all_label], nil])
  end
  
  def grouped_user_options(selected, options = {}, &block)
    options[:all_label] ||= nil
    options[:group1] ||= "Utilisateurs"
    options[:group2] ||= "Autres"

    @_users_to_group ||= User.active.find(:all, :include => [:roles], :select => "id, first_name, last_name, system_user")
    
    benchmark "partition" do
    @_grouped_users ||= if block_given?
        @_users_to_group.partition(&block)
      else
        @_users_to_group.partition {|u| u.system_user?}
      end
    end
    groups = @_grouped_users
    
    selected = selected.to_i
    
    select_options = ""
    select_options += options_for_select([ [options[:all_label], 0] ], selected)
    select_options += %Q{<optgroup label="#{h options[:group1]}">}
    select_options += options_for_select( User.to_select_options({:all_label => nil}, groups[0].sort_by {|u| u.full_name} ), selected )
    select_options += "</optgroup>"
    select_options += "<optgroup label='#{h options[:group2]}'>"
    select_options += options_for_select( User.to_select_options({:all_label => nil}, groups[1].sort_by {|u| u.full_name} ), selected )
    select_options += "</optgroup>"
    # options_for_select(User.to_select_options(:all_label => _("tout le monde")), selected)
  end
  
  def render_project_list(options, &proc)
    if options[:locals][:projects].size > 0
      yield
      concat render( options), proc.binding
    end
  end
  
  def tag_list(taggable)
    unless taggable.tag_list.empty?
      content_tag("p", taggable.tag_list, :class => 'tags')
    end
  end
  
  def init_display
    controller.action_name == 'new' ? "display: none;" : "display: block;"
  end
  
  def display_icon(item, text = nil)
    image_tag( item.class.name+".png", :border => 0) + "&nbsp;" + (text ? text : item.display_name)
  end  
  
  def display_activity_icon(item)
    item_class_name = item.class.name
    if item_class_name == "Note"
      item_name = _("Note")
    elsif item_class_name  == "LinkedMessage"
      item_name = item.message.type_title
      item_class_name = item.received? ? "ReceivedMessage" : "SentMessage"
    elsif item_class_name  == "Task"
      item_name = _("Tâche")
    elsif item_class_name  == "StateChange" || item_class_name  == "WorkSheetStateChange"
      item_name = _("Statut")
    elsif item_class_name  == "FileAttachment"
      item_name = _("Fichier")
    else
      item_name = item_class_name   
    end
    content_tag('span',item_name, :class=> item_class_name)
  end
  
  def highlight_current_user(user, priv = false)
    if user
      if user.id == current_user.id
        content_tag("span", user.full_name, :class => (priv ? 'private' : 'highlight') )
      else
        user.full_name
      end
    end
  end
  
  def text_field_with_inline_label(form, label, value, method_name, options = {})
    options = add_inline_options(label, value, options)
    form.text_field method_name, options
  end
  
  def text_area_with_inline_label(form, label, value, method_name, options = {})
    options = add_inline_options(label, value, options)
    form.text_area method_name, options
  end
  
  def inline_onfocus(value)
   function_to_return = "if (this.value == '#{value}') { this.value=''; $(this).removeClassName('blank'); };"
   
   return function_to_return
  end
  
  def inline_onblur(value)
   function_to_return = "if (this.value.match(/^ *$/)) { this.value='#{value}'; $(this).addClassName('blank'); };"
   
   return function_to_return
  end
  
  def format_date_time(date)
    date ? date.localize(:short) : "" 
  end
  
  def display_project_contract(project)
    display_contract_type(project.contract)
  end
  
  def display_contract_type(contract)
    if contract && contract.contract_type
      content_tag("span", contract.contract_type.name, :class => "contract_tag #{contract.contract_type.css_class}" )
    end
  end
  
  #TODO: temporary
  def display_party_contract(party)
    if party.contract_type
      content_tag("span", party.contract_type.name, :class => "value #{party.contract_type.css_class}" )
    end
  end
  
  def has_instruction(party, title = "Instructions")
    instruction = party.full_instructions rescue ""
    if instruction.blank?
      #content_tag("span", "Pas d'instructions!" , :id => "instructions", :class => "false" )
    else
      content_tag("span", "<a href='#' class='tooltip'>&raquo; #{title}<span>#{simple_format(instruction)}</span></a>", :id => "instructions", :class => "true" )
    end
  end
  
  def missing_data(item, method="", caption="indisponible")
    begin
      if item.nil?
        content_tag("span", caption, :class => 'missing_data')
      else
        content_tag("span", item.send(method), :style => 'padding: 3px 0px 2px 3px;')
      end
    rescue
      content_tag("span", caption, :class => 'missing_data')
    end
  end
  
  def late_date(date,format=:short)
    if date && (date.to_time <= Time.now)
      content_tag("span", date.localize(format), :class => "late_date" )
    else
      date.localize(format).gsub(/\s/, "&nbsp;")
    end
  end
  
  def display_project_name(item)
    if @include_project
      content_tag('td',
        (item.project.client ? content_tag('strong', item.project.client.name) : "" ) +
        content_tag('br') +
        link_to( item.project.display_name_with_numbers, item.project), :style => "padding: 10px; border-right: 1px solid #AAA; width: 300px;" )
    end
  end
  
  def display_days(days)
    content_tag('span', number_with_precision((days || 0.0), {:precision => 2}).to_s + ' j', :class=>'days')
  end
  
  def display_hours(hours)
    content_tag('span', number_with_precision((hours || 0.0), {:precision => 2}).to_s + 'h', :class=>'hours')
  end
  
  def display_work_sheet(work_sheet)
    c = display_contract_type(work_sheet.project.contract)
    i = content_tag('strong', "#{work_sheet.id} - #{work_sheet.call_number}")
    n = work_sheet.display_name
    "#{i} #{c} #{n}" # takes care of nil value and proper spacing
  end
  
  def display_work_type_or_call_type(call)
    if call.work_type
      call.work_type.name
    elsif call.call_type
      call.call_type.name
    else
      ''
    end
  end
  
  def display_flash(level)
    content_tag("p", flash[level], :class => 'flash_notice') if flash[level]
  end
  
  def edit_image_tag
    image_tag("edit.png", :border => 0, :alt => _("Modifier"))
  end
  
  def show_only_on_change(value, bucket = :default)
    @_show_on_change ||= {}
    if @_show_on_change[bucket] != value
      @_show_on_change[bucket] = value
      return value
    end
    nil
  end
  
  def std_calendar_field object, field
    calendar_field object, field, 
          { :class => 'calendar_class',
            :button_title => _("choisir une date")
          },
          { :firstDay => 0,
            # :ifFormat => '%d-%m-%y %H:%M',
            :range => [2000, 2030],
            :step => 1
          }
  end
  
  def std_calendar_date_field object, field
    calendar_field object, field, 
          { :class => 'calendar_class',
            :button_title => _("choisir une date")
          },
          { :firstDay => 0,
            :ifFormat => '%Y-%m-%d',
            :range => [2000, 2030],
            :step => 1
          }
  end

  protected
  def add_inline_options(label, value, options)
    options.merge!(:onfocus => inline_onfocus(label) , :onblur => inline_onblur(label))
    if value.blank?
      options[:class] ? options[:class] << " blank" : options[:class] = "blank"
      options[:value] = label
    end
    options
  end
end