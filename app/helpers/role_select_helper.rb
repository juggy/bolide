module RoleSelectHelper
  
  def grouped_foreman_select_options
    @_grouped_foreman_select_options ||= Department.all.collect do |department|
      ["chef d'équipe #{department}", department.foremen.collect {|u| [u.full_name, u.id]} ]
    end
  end
  
end