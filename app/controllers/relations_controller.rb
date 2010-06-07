class RelationsController < ApplicationController

  before_filter :set_party
  
  def index
    @relationships = @party.relationships
  end

  # def show
  #   @relation = Relation.find(params[:id])
  # end

  def new
    @relation = Relation.new_for_party(@party)
  end

  def edit
    @relation = Relation.find(params[:id])
  end

  def create
    rel = params[:relation]
    new_relation = { 
      Party.find(rel[:first_party_id]) => rel[:description], 
      Party.find(rel[:third_party_id]) => rel[:description_2] 
    }
    @relation = Relation.create(new_relation, (params[:relationship] || {}) )
    
    flash[:notice] = 'Relation was successfully created.'
    
    redirect_to party_relations_url(@party)

  rescue
    render :action => "new"
  end

  def update
    @relation = Relation.find(params[:id])
  
    if @relation.update_attributes(params[:relation])
      #flash[:notice] = 'Relation was successfully updated.'
      redirect_to party_relations_url(@party)
    else
      render :action => "edit"
    end
  
  end
  
  def restore
    @relation = Relation.find(params[:id])
    @relation.restore
    redirect_to party_relations_url(@party)
  end
  
  def destroy
    @relation = Relation.find(params[:id])
    if !@relation.active? && current_user.has_permission?("admin")
      @relation.force_destroy
    else
      @relation.destroy
    end
    redirect_to party_relations_url(@party)
  end
  
  protected
  def set_party
    @party = Party.find(params[:party_id])
  end
end
