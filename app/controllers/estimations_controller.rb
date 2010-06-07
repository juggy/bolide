class EstimationsController < ApplicationController
  layout 'estimation'
  
  before_filter :set_full_layout, :except => [:index]
  
  def index
    @estimations = Estimation.all
  end

  def show
  end

  def new
    @estimation = Estimation.new
    @estimation.save
    redirect_to edit_estimation_url(@estimation.id)
  end

  # def create
  #   @estimation = Estimation.new(params[:estimation])
  #   @estimation.save
  #   redirect_to edit_estimation_url(@estimation.id)
  # end
  
  def edit
    @estimation = Estimation.get(params[:id])
    @assemblies = TableauTemplate.all.sort_by {|as| as.title.downcase }
  end

  def update
    @estimation = Estimation.get(params[:id])
    json = JSON.parse(params[:estimation])
    json.delete("updated_at")
    json.delete("created_at")
    json.delete("_rev")
    json.delete("_id")
    json.delete("couchrest-type")
    pp json
    @estimation.update_attributes(json)
    render :text => 'ok'
  end

end