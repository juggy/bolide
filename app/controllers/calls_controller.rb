class CallsController < ApplicationController
  
  require_permission 'create_calls', :only => [:new, :create, :destroy]
  
  def search
    begin
      address = Address.build_sphinx_fuzzy_search( params[:call][:address] )
      
      terms = 
        [address, 
        "#{params[:call][:phone_number]}".gsub(/\D/,""),
         params[:call][:contact_name],
         params[:call][:company_name]
      ].reject(&:blank?).map {|t| "(#{t})"}
      
      unless terms.empty?
        search = "#{ terms.join(" | ") }" # OR search
        @search_results = ThinkingSphinx.search( search , :classes => [Contact,Company,Building], :match_mode => :extended2, :with => {:account_id => Account.current_account_id})
      else
        @search_results = []
      end
    rescue
    ensure  
      @results = @search_results.group_by(&:class)
    end
    render :partial => 'search_results'
  end

  def show
    @project = params[:project_id].blank? ? Project.find(params[:id]) : Project.find(params[:project_id])
    @call = @project.call
      
    respond_to do |wants|
      wants.html
      wants.pdf { send_data NewCallSheetPdf::generate(@project), :filename => "feuille_appel_#{@project.call_number}.pdf" }
    end
  end

  def new
    @call = Call.new
  end

  def create
    @call = Call.new(params[:call])

    respond_to do |format|
      if @call.save
        flash[:notice] = 'Call was successfully created.'
        format.html { redirect_to @call.project }
      else
        format.html { render :action => "new" }
      end
    end
  end

end
