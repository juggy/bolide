class MailingListsController < ApplicationController

  def index
    @mailing_lists = MailingList.find(:all)
  end

  def show
    @mailing_list = MailingList.find(params[:id])
  end

  def new
    @mailing_list = MailingList.new
  end

  def edit
    @mailing_list = MailingList.find(params[:id])
  end

  def create
    @mailing_list = MailingList.new(params[:mailing_list])

    if @mailing_list.save
      flash[:notice] = 'MailingList was successfully created.'
      redirect_to(mailing_lists_url)
    else
      render :action => "new"
    end
  end

  def update
    @mailing_list = MailingList.find(params[:id])

    if @mailing_list.update_attributes(params[:mailing_list])
      flash[:notice] = 'MailingList was successfully updated.'
      redirect_to(mailing_lists_url)
    else
      render :action => "edit"
    end
  end

  def destroy
    @mailing_list = MailingList.find(params[:id])
    @mailing_list.destroy

    redirect_to(mailing_lists_url)
  end
end
