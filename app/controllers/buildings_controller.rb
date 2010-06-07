class BuildingsController < PartiesController
  require_permission 'create_buildings', :only => [:new, :create, :destroy]
  require_permission 'destroy_buildings', :only => [:find_duplicate, :destroy, :delete, :merge]
  # TODO: doesn't need caching now, but watch out for later
  # cache_sweeper :party_sweeper, :only => [ :update, :destroy ]
  
  def duplicates
    a = Address.new(params[:building][:address_attributes])
    @duplicates = Building.find_duplicates( a )
  end
  
  def index
    if params.has_key?(:tag)
      unless params[:tag].blank?
        @buildings = Building.find_tagged_with(params[:tag], :order => :name)
      else
        @buildings = Building.paginate(:all, :include => [:address], :order => :name, :page => params[:page], :per_page => 30)
      end
    else
      @buildings = Building.last_created
    end
    
    # @buildings = Building.paginate(:all, :include => [:address], :order => :name, :page => params[:page], :per_page => 30)
  end

  def show
    @building = Building.find(params[:id])
  end
  
  def instruction
    show
    @view = "instruction"
    render :action => "show"
  end
  
  def new
    @building = Building.new
  end

  def create
    @building = Building.new(params[:building])
    if @building.save
      redirect_to building_url(@building)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @building = Building.find(params[:id])
  end
  
  def update
    @building = Building.find(params[:id])
    if @building.update_attributes(params[:building])
      redirect_to building_url(@building)
    else
      render :action => 'edit'
    end
  end
  
  def contracts
    @building = Building.find(params[:id])
    @contract = @building.contract
  end
  
end
