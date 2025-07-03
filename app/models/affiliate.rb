# frozen_string_literal: true

class Affiliate < ApplicationRecord
  belongs_to :merchant

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :website_url, url: { allow_nil: true }
  validates :email, presence: true, email: { mode: :strict, require_fqdn: true }, uniqueness: { scope: :merchant_id }
  validates :commissions_total, numericality: { greater_than_or_equal_to: 0 }
  scope :search, lambda { |term|
    where('LOWER(first_name) LIKE :term OR LOWER(last_name) LIKE :term OR LOWER(email) LIKE :term', term: "%#{term.downcase}%")
  }

  scope :filter_by_merchant, lambda { |slug|
    joins(:merchant).where('LOWER(merchants.slug) LIKE ?', "%#{slug.downcase}%")
  }

  scope :with_min_commission, lambda { |min|
    where(commissions_total: min.to_f..)
  }

  scope :with_max_commission, lambda { |max|
    where(commissions_total: ..max.to_f)
  }
end
