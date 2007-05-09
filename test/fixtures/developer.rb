class Developer < ActiveRecord::Base
  has_and_belongs_to_many :projects

  def self.per_page
    10
  end
end

class DeVeLoPeR < ActiveRecord::Base
  set_table_name "developers"

  def self.per_page
    10
  end
end
