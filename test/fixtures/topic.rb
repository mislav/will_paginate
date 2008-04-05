class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :project

  named_scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']
end
