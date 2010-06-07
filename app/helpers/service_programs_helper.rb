module ServiceProgramsHelper
  
  # the program can have the same work sheet displayed multiple days
  # only the first must have the dom id used for drag and drop
  def first_dom_id_only(object)
    cache = (@_first_dom_ids_cache ||= {})
    id = dom_id(object)
    if cache.has_key?(id)
      return nil
    else
      cache[id] = id
    end
    id
  end
  
  def program_drop_zone( foreman, date, drop_zone_id )
    if current_user.has_permission?('update_schedule')
      on_drop = "function(element){ show_spinner(); new Ajax.Request('#{reschedule_service_programs_path()}', {asynchronous:true, evalScripts:true, parameters:'foreman_id=#{foreman ? foreman.id : nil}&department_id=#{foreman ? foreman.department_id : nil}&date=#{date}&id=' + encodeURIComponent(element.id)} ) }"
      drop_receiving_element drop_zone_id, 
                        :accept => 'work_sheet', 
                        :hoverclass => 'hover',
                        :onDrop => on_drop
    end
  end
  
  def drag_handle
    content_tag 'span', "&nbsp;", :class => "handle"
  end
  
  def draggable_work_sheet(current_dom_id)
    if current_dom_id && current_user.has_permission?('update_schedule') 
      draggable_element( 
              current_dom_id, 
              :revert => "'failure'", 
              :scroll => 'window', 
              :handle => "'handle'", 
              :onStart => "function(el, event){startDrag(el);}", 
              :onEnd => "function(el, event){endDrag(el);}" )
    end
  end
  
  def edit_work_sheet_link(work_sheet)
    if current_user.has_permission?('update_schedule')
      link_to_remote "#{work_sheet.contract_number} - #{work_sheet.call_number}",
                      { :url => edit_service_program_path( :id => work_sheet ), 
                        :method => 'get', 
                        :update => "edit_work_sheet_placeholder", 
                        :before => "remove_edit_form();",
                        :complete => "show_edit_form('#{dom_id(work_sheet)}');" }
    end
  end
  
  def daily_schedule_link( day )
    if (schedule = DailySchedule.find_by_date(day))
      "<br/>" +
      link_to( "(cédule)", daily_schedule_url(day) )
    end 
  end
  
end
