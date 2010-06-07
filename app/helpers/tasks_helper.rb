module TasksHelper
  
  def task_header(sym)
    {
      :late => _("En retard"),
      :today => _("Aujourd'hui"),
      :tomorrow => _("Demain"),
      :this_week => _("Cette semaine"),
      :next_week => _("La semaine prochaine"),
      :later => _("Plus tard")
    }[sym]
  end
  
  def involved_parties_select(project)
    [["Aucun", nil], 
      (["#{project.building.name} (Immeuble)", project.building.id] if project.building ), 
      (["#{project.client.name} (Client)", project.client.id] if project.client )
    ].compact.concat(
      project.involved_parties.map {|party| [party.name, party.id] }
    )
  end
end
