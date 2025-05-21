class Affiliate < ApplicationRecord
  belongs_to :merchant

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :website_url, url: { allow_nil: true }
  validates :email, presence: true, email: { mode: :strict, require_fqdn: true }, uniqueness: { scope: :merchant_id }
  validates :commissions_total, numericality: { greater_than_or_equal_to: 0 }
end
