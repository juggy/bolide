class Team
  attr_reader :department, :leader, :members, :all_members
  def initialize(department, leader, members = nil)
    @department = department
    @members = members || leader.team_members.all(:include => :contact)
    @leader = leader
    @all_members = [@leader] + @members
  end
  
  def self.for_department(department)
    build_department_teams(department)
  end

  def self.all
    Department.all.map do |dept|
      build_department_teams(dept)
    end.flatten
  end
  
  protected
  
  def self.build_department_teams(department)
    department.team_leaders.collect do |leader|
      Team.new(department, leader)
    end
  end
end