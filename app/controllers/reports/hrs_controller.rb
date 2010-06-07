class Reports::HrsController < ApplicationController
  require_permission 'access_human_resource_infos'
  
  def courses
    if params[:id]
      @course = Course.find(params[:id]) 
      @competences = @course.competences.min_course_date(params[:min_start_date]).
                                         max_course_date(params[:max_start_date])
    end
    render :layout => 'fullscreen'
  end
  
  def next_courses
    @competences = Competence.next_courses
    render :layout => 'fullscreen'
  end
  
  def plan_group_course
    @course = Course.find(params[:group_course][:course_id])
    @date = params[:group_course][:date]

    @contacts = Contact.find((params[:contacts] || {}).keys)
    
    @contacts.each do |contact|
      competence = contact.competences.find_or_initialize_by_course_id(@course.id)
      competence.update_attributes(:next_course_date => @date)
    end

    redirect_to :action => :courses, :id => @course
  end
  
  def competences_table
    csv_string = Competence.csv_table(Course.all, Team.all, current_user.separator)
    send_data replace_UTF8(csv_string),
              :type => 'text/csv; header=present',
              :disposition => "attachment; filename=tableau_certifications.csv"
  end
  
  def expired_competences
    @employees = Competence.expires_soon.group_by(&:employee)
  end

  def birthdays
    @current_month = (params[:month] || Time.now.month).to_i
    @employees = EmployeeInfo.find(:all, 
      :conditions => ["MONTH(birthday) = ?", @current_month],
      :order => "DATE_FORMAT(birthday, '%m%d') ASC"
    )
    @employees.reject! {|e| !e.contact.is_employee? }
  end
  
  def absences
    params[:min_start_date] ||= Time.now.beginning_of_year.strftime('%Y-%m-%d')
    params[:max_start_date] ||= Time.now.end_of_year.strftime('%Y-%m-%d')
    
    render :layout => 'fullscreen'
  end
  
end
