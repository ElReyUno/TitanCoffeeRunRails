class CreditApplicationMailer < ApplicationMailer
  default from: "noreply@titanscoffeerun.com"

  def new_application(credit_application)
    @credit_application = credit_application
    mail(
      to:      "admin@titanscoffeerun.com",
      subject: "New Credit Application Received"
    )
  end

  def application_result(credit_application, qualification_result)
    @credit_application = credit_application
    @qualification_result = qualification_result

    subject = qualification_result[:qualified] ?
              "Credit Application Approved!" :
              "Credit Application Update"

    mail(
      to:      @credit_application.email,
      subject: subject
    )
  end
end
