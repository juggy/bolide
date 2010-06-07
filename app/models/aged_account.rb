# == Schema Information
# Schema version: 20090408154321
#
# Table name: aged_accounts
#
#  id            :integer(4)      not null, primary key
#  client_id     :integer(4)      
#  total_due     :decimal(10, 2)  default(0.0)
#  countercharge :decimal(10, 2)  default(0.0)
#  due_30_to_60  :decimal(10, 2)  default(0.0)
#  due_60_to_90  :decimal(10, 2)  default(0.0)
#  due_90_to_120 :decimal(10, 2)  default(0.0)
#  due_over_120  :decimal(10, 2)  default(0.0)
#  created_at    :datetime        
#  updated_at    :datetime        
#

class AgedAccount < ScopedByAccount
  belongs_to :client, :class_name => "Company", :foreign_key => "client_id"
  validates_presence_of :client_id
end
