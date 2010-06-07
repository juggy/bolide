module ProjectsHelper
  def possible_contract_options_for_project(project)
    opts = []
    opts.concat( project.building.projects.collect {|p| [p.display_name_with_numbers,p.id] } ) if project.building
    #opts.concat( project.client.projects.collect {|p| [p.display_name_with_numbers,p.id] } ) if project.client
    
    (opts.reject! {|opt| opt[1] == project.id} || [] ).uniq!
    options_for_select(opts)
  end
  
end
