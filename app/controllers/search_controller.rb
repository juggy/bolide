class SearchController < ApplicationController

  def index
    if request.post?
      begin
        @results = ThinkingSphinx.search("#{params[:term]}", :per_page => 50, :with => {:account_id => Account.current_account_id})
        @results.reject! do |r|
          r.respond_to?(:private) && r.private && r.user_id != current_user.id
        end
      rescue
        @results = []
      end
    end
  end
  
end