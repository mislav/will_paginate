class Developer < User
  has_and_belongs_to_many :projects, :include => :topics, :order => 'projects.name'

  def self.per_page() 10 end
end
