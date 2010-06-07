# == Schema Information
# Schema version: 20090408154321
#
# Table name: competences
#
#  id          :integer(4)      not null, primary key
#  employee_id :integer(4)      
#  course_id   :integer(4)      
#  course_date :date            
#  expires_on  :date            
#  note        :text            
#  created_at  :datetime        
#  updated_at  :datetime        
#
require 'fastercsv'

class Competence < ScopedByAccount
  belongs_to :employee, :class_name => "Contact", :foreign_key => "employee_id"
  belongs_to :course
  has_many :audits, :class_name => "CompetenceAudit", :dependent => :destroy
  validates_presence_of :employee_id, :course_id
  validates_uniqueness_of :course_id, :scope => [:account_id, :employee_id]
  
  named_scope :expires_soon, lambda { {:conditions => ["expires_on <= ?", 3.months.from_now]} }
  named_scope :next_courses, lambda { {:conditions => ["next_course_date >= ?", Time.now], :include => [:course, :employee], :order => 'next_course_date ASC, courses.name ASC, parties.last_name ASC'} }
  
  named_scope :min_course_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["course_date >= ?", date] }
  }
  named_scope :max_course_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["course_date <= ?", date] }
  }
  
  before_save :create_audit
  
  def name
    course.name
  end
  
  def expired?
    expires_on.blank? ? false : Time.now > self.expires_on
  end
  
  def expires_soon?
    expires_on.blank? ? false : Time.now.advance(:months => 3) > self.expires_on
  end
  
  
  #### CSV
  # 
  def self.csv_table(courses, teams, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header
      csv << ["employé"] + courses.collect(&:name)
      teams.each do |team|
        team.all_members.each do |member|
          name = member.full_name 
          name = "* " + name if (member == team.leader)
          competences = courses.collect do |course|
            if member.contact
              competence = member.contact.competences.detect {|comp| comp.course_id == course.id}
              (competence && !competence.expired?) ? "x" : ""
            else
              ""
            end
          end
          csv << [name] + competences
        end
      end
    end
  end
  
  
  
  protected
    def create_audit
      if !self.new_record? && (course_date_changed? || expires_on_changed? || next_course_date_changed? )
        self.audits.create(:course_date => self.course_date_was, :expires_on => self.expires_on_was, :next_course_date => self.next_course_date_was)
      end
    end
end
