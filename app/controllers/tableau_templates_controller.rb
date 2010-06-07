require 'pp'
class TableauTemplatesController < ApplicationController
  layout 'estimation'
  
  before_filter :set_full_layout, :except => [:index]
  
  def index
    @tableau_templates = TableauTemplate.all
  end

  def show
  end

  def new
    @tableau_template = TableauTemplate.new
    @tableau_template.save
    redirect_to edit_tableau_template_url(@tableau_template.id)
  end

  def create
    json = JSON.parse(params[:tableau_template])
    
    @tableau_template = TableauTemplate.new(json)
    @tableau_template.save
    render :text => 'ok'
    
  end
  
  def edit
    @tableau_template = TableauTemplate.get(params[:id])
  end

  def update
    @tableau_template = TableauTemplate.get(params[:id])
    json = JSON.parse(params[:tableau_template])
    json.delete("updated_at")
    json.delete("created_at")
    json.delete("_rev")
    json.delete("_id")
    json.delete("couchrest-type")
    pp json
    @tableau_template.update_attributes(json)
    render :text => 'ok'
  end
  
end
