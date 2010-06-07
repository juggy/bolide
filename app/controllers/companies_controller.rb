class CompaniesController < PartiesController

  cache_sweeper :party_sweeper, :only => [ :update, :destroy ]
  
  require_permission 'create_companies', :only => [:new, :create, :destroy]
  require_permission 'destroy_companies', :only => [:find_duplicate, :destroy, :delete, :merge]
  
  def index
    if params.has_key?(:tag)
      unless params[:tag].blank?
        @companies = Company.paginate(Company.find_tagged_with(params[:tag]), :order => :name, :per_page => 40, :page => params[:page])
      else
        @companies = Company.paginate(:all, :order => :name, :per_page => 40, :page => params[:page])
      end
    else
      @companies = Company.last_created
    end
  end

  def print
    unless params[:tag].blank?
      @companies = Company.for_manager(params[:manager_id]).find_tagged_with(params[:tag], :order => :name).collect(&:id)
      @companies = Company.scoped( :conditions => {:id => @companies},
            :include => [:contract_type,
                         {:relationships => [:third_party]},
                         :manager,
                         :addresses,
                         :phone_numbers,
                         :emails,
                         :websites,
                         :other_contact_data] )
    else
      @companies = Company.find(:all, :order => :name)
    end
    render :layout => 'report'
  end
  
  def show
    @company = Company.find(params[:id])
  end

  def new
    @company = Company.new
  end

  def edit
    @company = Company.find(params[:id])
  end

  def create
    @company = Company.new(params[:company])

    if @company.save
      flash[:notice] = 'Company was successfully created.'
      redirect_to company_url(@company)
    else
      render :action => "new"
    end

  end

  def update
    @company = Company.find(params[:id])

    if @company.update_attributes(params[:company])
      flash[:notice] = 'Company was successfully updated.'
      redirect_to company_url(@company)
    else
      render :action => "edit"
    end

  end

  def destroy
    @company = Company.find(params[:id])
    @company.destroy

    redirect_to companies_url
  end
  
  def contracts
    @company = Company.find(params[:id])
    @contracts = @company.contracts
  end
  
  def aged_account
    @company = Company.find(params[:id])
    @aged_account = @company.aged_account
  end
  
  def certifications
    @company = Company.find(params[:id])
  end
end
