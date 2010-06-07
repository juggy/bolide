class ContactsController < PartiesController
  skip_before_filter :login_required, :only => [:address_book]
  before_filter :authenticate_access_key, :only => [:address_book]
  
  require_permission 'destroy_contacts', :only => [:find_duplicate, :destroy, :delete, :merge]
  require_hr_permission :only => [:hr]
  
  cache_sweeper :party_sweeper, :only => [ :update, :destroy ]
  
  def auto_complete_for_contact_company_name
    @companies = Company.find(:all, :conditions => ["LOWER(name) LIKE ?", "%#{params[:contact][:company_name].downcase}%"], :limit => 10)
    render :inline => "<%= auto_complete_result(@companies,:name) %>"
  end
  
  def index
    if params.has_key?(:tag)
      unless params[:tag].blank?
        @contacts = Contact.find_tagged_with(params[:tag], :order => "last_name, first_name")
      else
        @contacts = Contact.paginate(:all, :order => "last_name, first_name",  :per_page => 40, :page => params[:page])
      end
    else
      @contacts = Contact.last_created
    end
  end
  
  def phone_book
    @contacts = Contact.find_tagged_with(params[:tag], :order => "last_name, first_name", :include => :phone_numbers)
    
    respond_to do |wants|
      wants.html { render :layout => 'report' }
      wants.csv do
        csv_string = Contact.phone_book_csv(@contacts, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=liste_telephonique_#{params[:tag]}.csv"
        
      end
    end
    
  end
  
  # Blackberry Only
  def address_book
    unless params[:party_name].blank?
      find
      flash[:notice] = []
    else
      flash[:notice] = 'Veuillez saisir les premieres lettres du nom de votre contact....'
    end    
    render :layout => "blackberry"
  end
  
  def show
    @contact = Contact.find(params[:id])
  end

  def new
    @contact = Contact.new(:company_name => params[:company_name])
  end

  def edit
    @contact = Contact.find(params[:id])
  end

  def create
    @contact = Contact.new(params[:contact])

    if @contact.save
      flash[:notice] = 'Contact was successfully created.'
      redirect_to contact_url(@contact)
    else
      render :action => "new"
    end

  end

  def update
    @contact = Contact.find(params[:id])

    if @contact.update_attributes(params[:contact])
      flash[:notice] = 'Contact was successfully updated.'
      redirect_to contact_url(@contact)
    else
      render :action => "edit"
    end

  end

  def hr
    @contact = Contact.find(params[:id])
    render :layout => 'fullscreen'
  end
  
  # html warning form
  def delete
    @contact = Contact.find(params[:id])
  end
  
  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy

    redirect_to contacts_url
  end
  
  def load_hr_user
    @contact = Contact.find(params[:id])
    @contact.user
  end
  
  private
  def authenticate_access_key
    current_user = User.find_by_access_key(params[:access_key])
    if current_user.blank?
      raise "Unauthorized"
    end
  end
end
