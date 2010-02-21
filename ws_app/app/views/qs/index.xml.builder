xml.instruct!
xml.qs :account=>@account._id do
  @qs.each do |q|
    xml.q :id=>q._id do 
			xml.msg_count q.msg_count
			xml.token q.token
			xml.expire_on q.expire_on
		end
  end
end