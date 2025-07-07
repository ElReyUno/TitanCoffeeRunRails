class CreditApplication < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :re_enter_email, presence: true
  validates :first_name, presence: true, length: { minimum: 2 }
  validates :last_name, presence: true, length: { minimum: 2 }
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :zip, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/ }
  validates :gross_income, presence: true, numericality: { greater_than: 0 }
  validates :ssn_last_four, presence: true, format: { with: /\A\d{4}\z/ }
  validates :apply_for_credit, acceptance: true

  validate :emails_must_match

  private

  def emails_must_match
    if email.present? && re_enter_email.present? && email != re_enter_email
      errors.add(:re_enter_email, "must match the email address")
    end
  end
end
