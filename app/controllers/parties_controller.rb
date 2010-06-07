class PartiesController < ApplicationController
  
  before_filter :set_context
  
  def search
    find
    render :partial => "/parties/search_result_list"
  end
  
  def auto_complete_for_party_name
    find
    render :partial => '/parties/auto_complete_list'
  end
  
  def history
    restore_session_params("party_history_filter", :defaults => {:user_id => current_user.id})
    @party = Party.find(params[:id])
    @history = @party.activities.history.by_type(params[:activity_type]).by_user(params[:user_id]).by_category(params[:category_id])
    render :template => '/parties/history'
  end
  
  def projects
    @party = Party.find(params[:id])
    render :template => '/parties/projects'
  end
  
  def involvements
    @party = Party.find(params[:id])
    render :template => '/parties/involvements'
  end
  
  # Merge
  def find_duplicate
    @party = Party.find(params[:id])
    render :template => '/parties/find_duplicate'
  end
  
  def merge
    @party = Party.find(params[:id])
    if params[:duplicate] && params[:duplicate][:duplicate_id]
      @duplicate = Party.find(params[:duplicate][:duplicate_id])
      @party.merge!(@duplicate)
      redirect_to @party
    else
      flash.now[:warning] = "Veuillez sélectionner un contact"
      render :template => '/parties/find_duplicate'
    end
  rescue
    flash.now[:warning] = "La fusion n'a pas fonctionné. Veuillez contacter Code Génome."
    render :template => '/parties/find_duplicate'
  end
  
  
  protected
  def find
    collection = Party
    # collection = [Building, Company, Contact, Project] if params[:collection] == "ALL"
    collection = Building if params[:collection] == "building"
    collection = Contact if params[:collection] == "contact"
    collection = Company if params[:collection] == "company"
    
    term = params[:party_name]
    @parties = collection.auto_complete_search(term)
       
    if params[:collection] == "ALL"
      term = term.split(" ").map {|t| "*#{t}*"}.join(" ")
      term = term.gsub("-", "") # TODO: check why this change with update to sphinx
      @parties.concat ThinkingSphinx.search(term, :classes => [Project], :per_page => 10, :with => {:account_id => Account.current_account_id})
    end
    
    if params[:reject_id]
      @parties.reject! {|p| p.id == params[:reject_id].to_i}
    end
  end
  
  def set_context
    @context = "Party"
  end
end