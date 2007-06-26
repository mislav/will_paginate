class Developer < User
  has_and_belongs_to_many :projects

  def self.per_page
    10
  end
end

class DeVeLoPeR < User
  set_table_name "developers"

  def self.per_page
    10
  end
end
