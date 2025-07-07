require "digest"

class CreditController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :new, :create ]
  before_action :check_rate_limit, only: [ :create ]  # Only check on form submission

  def index
    # Redirect to new action if someone hits the index
    redirect_to apply_for_credit_path
  end

  def new
    @credit_application = CreditApplication.new
  end

  def create
    @credit_application = CreditApplication.new(credit_application_params)

    # Check that all required fields are present and checkbox is checked
    if validate_required_fields && @credit_application.valid?
      # Save to database
      @credit_application.save!

      # Increment submission counter AFTER successful submission
      increment_submission_counter

      # Send email notification to admin
      CreditApplicationMailer.new_application(@credit_application).deliver_now

      # Determine qualification based on income
      qualification_result = determine_qualification(@credit_application.gross_income)

      # Send result email to applicant
      CreditApplicationMailer.application_result(@credit_application, qualification_result).deliver_now

      flash[:notice] = qualification_result[:message]
      
      # Redirect to order page regardless of approval status
      redirect_to orders_path
    else
      flash[:alert] = "Please correct the errors below and ensure all required fields are completed."
      render :new
    end
  end

  private

  def validate_required_fields
    # Check all required fields are present and not empty
    required_fields = [
      :email, :re_enter_email, :first_name, :last_name,
      :city, :state, :zip, :gross_income, :ssn_last_four
    ]
    
    missing_fields = []
    
    required_fields.each do |field|
      value = @credit_application.send(field)
      if value.blank?
        missing_fields << field.to_s.humanize
      end
    end
    
    # Check if emails match
    if @credit_application.email != @credit_application.re_enter_email
      @credit_application.errors.add(:re_enter_email, "must match the email address")
    end
    
    # Check if apply_for_credit checkbox is checked
    unless @credit_application.apply_for_credit
      @credit_application.errors.add(:apply_for_credit, "must be checked to proceed")
    end
    
    # Add errors for missing fields
    missing_fields.each do |field|
      @credit_application.errors.add(:base, "#{field} is required")
    end
    
    return missing_fields.empty? && @credit_application.email == @credit_application.re_enter_email && @credit_application.apply_for_credit
  end

  def credit_application_params
    params.require(:credit_application).permit(
      :email, :re_enter_email, :first_name, :last_name,
      :city, :state, :zip, :gross_income, :ssn_last_four, :apply_for_credit
    )
  end

  def check_rate_limit
    # Prevent duplicate submissions - max 3 successful submissions per user per hour
    user_key = generate_user_key
    cache_key = "credit_submissions_#{user_key}"
    applications_count = Rails.cache.read(cache_key) || 0

    if applications_count >= 3
      flash[:alert] = "Too many applications submitted. Please try again later."
      redirect_to apply_for_credit_path and return
    end
  end

  def increment_submission_counter
    # Increment counter with 1 hour expiry after successful submission
    user_key = generate_user_key
    cache_key = "credit_submissions_#{user_key}"
    applications_count = Rails.cache.read(cache_key) || 0
    Rails.cache.write(cache_key, applications_count + 1, expires_in: 1.hour)
  end

  def generate_user_key
    # Create a consistent key based on user identity (email + name)
    email = params.dig(:credit_application, :email).to_s.downcase.strip
    first_name = params.dig(:credit_application, :first_name).to_s.downcase.strip
    last_name = params.dig(:credit_application, :last_name).to_s.downcase.strip

    # Create a hash to avoid storing personal info in cache keys
    Digest::SHA256.hexdigest("#{email}#{first_name}#{last_name}")
  end

  def determine_qualification(gross_income)
    if gross_income >= 20000
      {
        qualified:    true,
        message:      "Congratulations! You are qualified for a credit line.
        A credit card will be sent to you in the mail.",
        credit_limit: calculate_credit_limit(gross_income),
      }
    else
      {
        qualified:    false,
        message:      "We're sorry, you do not qualify for a credit line at this time.",
        credit_limit: 0,
      }
    end
  end

  def calculate_credit_limit(gross_income)
    # Simple calculation: 10% of annual income, max $5000
    limit = (gross_income * 0.10).round
    [ limit, 5000 ].min
  end
end
