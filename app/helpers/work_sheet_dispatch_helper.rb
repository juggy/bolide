module WorkSheetDispatchHelper
  
  def render_interventions(foreman, date, options = {})
    options.reverse_merge!( :drop => true, :new => true )
    collection = select_interventions(foreman, date)
    str = content_tag(
      'div',
            [ content_tag( 'div',
                (options[:new] ? add_intervention_link(foreman, date).to_s : '&nbsp;'),
                :class => 'add_intervention_wrapper'),
              render( :partial => 'intervention', :collection => collection )
            ].join(" "),
      :id => dom_id(foreman, date), :class => 'interventions')
      
    content_tag('div', '&nbsp;', :id => dom_id(foreman, "#{date}_form"), :class => 'intervention_form') +
    ( options[:drop] ? 
      str + intervention_drop_zone(foreman,date).to_s : str )
  end
  
  def select_interventions(foreman, date)
    (@interventions[foreman.id] || []).select {|i| i.date.strftime("%Y%m%d") == date }
  end
  
  def add_intervention_link(foreman, date)
    if current_user.has_permission?('update_schedule')
    
      link_to_remote( "ajouter bon", 
                 { :url => new_dispatch_intervention_url( :intervention => { :foreman_id => foreman.id, :date => date } ), 
                   :update => dom_id(foreman, "#{date}_form"), 
                   :before => "remove_previous_form();" },
                 {
                   :class => 'add_intervention'
                 } )
    end
  end
  
  def intervention_drop_zone(foreman,date)
    if current_user.has_permission?('update_schedule')
      drop_receiving_element dom_id(foreman, date), 
                        :url => hash_for_reschedule_dispatch_interventions_path("foreman_id" => foreman.id, "date" => date), 
                        :accept => 'intervention', 
                        :hoverclass => 'hover'
    end
  end
  
  def display_interventions(worksheet)
    interventions_count = worksheet.interventions.length
    content_tag('span', pluralize(interventions_count, 'intervention'), :id => dom_id(worksheet), :class => "#{interventions_count == 1 ? '' : 'highlight'}")
  end
end
