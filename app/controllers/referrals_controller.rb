class ReferralsController < ApplicationController
  before_action :check_session
  before_action :set_referral, only: [:update, :edit, :destroy, :show]
  before_action :determine_status, only: [:update, :edit, :show]
  before_action :check_correct_owners, only: [:show, :edit, :update, :destroy]
  before_action :store_location #enables linking back

  # after_update :check_interest

  #TODO set up params to align with the right owner****
  def index
	  # @search = Referral.search(params[:q])
  	# @referrals = @search.result
    @referrals = Referral.all
    @jobs = Job.all
  end

  def new
    @referral = Referral.new
    if !params[:ref_type].nil?
      @job = Job.find(params[:job_id])
      @ref_type = params[:ref_type]
    else
      redirect_to jobs_path, notice: "Please select a job to create a referral"
    end
   # @your_name = current_user.first_name && current_user.last_name || ""
  end

  def create
    #
    referral = Referral.new(referral_params)
    admin = referral.job.admin

    if current_admin.nil?
      referral.user_id = current_user.id
      requester = User.find(current_user.id)
    else
      referral.admin_id = current_admin.id
      requester = Admin.find(current_admin.id)
    end



    if referral.check_email(requester) #protected method to check if there is a self-referral.
      if referral.save
        if referral.ref_type == "refer"
          ReferralMailer.deliver_ref_email(referral)
        else
          ReferralMailer.deliver_ask_email(referral, requester)
        end
        check_whitelist(referral)
        redirect_to referral
      else
        flash[:error] = "Please fill in all the required fields"
        redirect_to new_referral_path(:job_id => referral.job_id, :ref_type => referral.ref_type)
      end
    else
      flash[:error] = "Sorry, you cannot refer yourself."
      redirect_to new_referral_path(:job_id => referral.job_id, :ref_type => referral.ref_type)
    end
  end


  def show
    @referral
    @job = Job.find(@referral.job_id)
    @my_status
  end

  def edit
    @job = Job.find(@referral.job_id)
    @ref_type = @referral.ref_type
    @my_status
    #name logic
    if @referral.admin_id.nil?
      @user = User.find(@referral.user_id)
      @referrer_FN = @user.first_name
      @referrer_LN = @user.last_name
    else
      @admin = Admin.find(@referral.admin_id)
      @referrer_FN = @admin.first_name
      @referrer_LN = @admin.last_name
    end
  end

  def update
    @referral

    #TODO REFACTOR IT OUT
    if current_admin.nil?
      requester = User.find(current_user.id)
    else
      requester = Admin.find(current_admin.id)
    end

    if @referral.update(referral_params)
      #logic?
      redirect_to @referral
    else
      flash[:error] = "There was an issue with your update. Please review your updates."
      #TODO FIX ERROR
      render 'edit'
    end
  end

  def destroy
    if @referral.destroy
      flash[:notice] = "You successfully removed the referral"
      redirect_to referrals_path
    else
      flash[:notice] = "Referral could not be deleted."
      render action: 'edit'
    end
  end


  protected

  def set_referral
    @referral = Referral.find(params[:id])
  end

  def referral_params
    params.require(:referral).permit(:name, :job_id, :referral_name, :referral_email, :relationship, :additional_details, :linked_profile_url, :status, :github_profile_url, :relevance, :user_id, :admin_id, :ref_type, :status, :referee_name, :referee_email, :personal_note, :is_interested, :is_admin_notified)
  end

  #only correct user and admin can destroy
  def check_correct_owners
    if current_admin.nil?
      if @referral.referral_email != current_user.email && @referral.user != current_user
        redirect_to(new_user_session_path, notice: "You cannot view this referral. Please login to the correct account.")
      end
    else
      if @referral.job.admin != current_admin && @referral.admin_id != current_admin.id
        redirect_to(new_user_session_path, notice: "You cannot view this referral. Please login to the correct account.")
      end
    end
  end

  def determine_status
    if current_admin.nil? #user logic checks
      if @referral.user == current_user
        @my_status = "Sender"
      else
        @my_status = "Receiver-U"
      end
    else #admin logic checks
      if @referral.admin_id == current_admin.id
        @my_status = "Sender"
      else
        @my_status = "Receiver-A"
      end
    end
  end

  def check_session
    if current_user.nil? && current_admin.nil?
      redirect_to(new_user_session_path, notice: "Please sign-in to make referrals")
    end
  end

  def check_whitelist(referral)
    if referral.ref_type == "refer"
      unless Whitelist.exists?(:email => params[:referral][:referral_email])
        Whitelist.create(:email => params[:referral][:referral_email], :is_admin => false)
      end
    else
      unless Whitelist.exists?(:email => params[:referral][:referee_email])
        Whitelist.create(:email => params[:referral][:referee_email], :is_admin => false)
      end
    end
  end
  #NEED TO MOVE THIS METHOD TO THE MODEL



end
