class CompetencesController < ResourceController::Base
  require_hr_permission
  
  belongs_to :contact
  
  destroy.success.wants.html { redirect_to hr_contact_path(@contact) }
  update.success.wants.html  { redirect_to hr_contact_path(@contact) }
  create.success.wants.html  { redirect_to hr_contact_path(@contact) }
  create.failure.wants.html do
    @show_competence_form = true
    render :template => 'contacts/hr'
  end
  
  def load_hr_user
    parent_object.user
  end
  
end