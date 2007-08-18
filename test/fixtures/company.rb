class Company < ActiveRecord::Base
  attr_protected :rating
  set_sequence_name :companies_nonstd_seq

  validates_presence_of :name
  def validate
    errors.add('rating', 'rating should not be 2') if rating == 2
  end  

  def self.with_best
    with_scope :find => { :conditions => ['companies.rating > ?', 3] } do
      yield
    end
  end

  def self.find_best(*args)
    with_best { find(*args) }
  end

  def self.calculate_best(*args)
    with_best { calculate(*args) }
  end
end
