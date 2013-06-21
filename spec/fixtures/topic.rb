class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :project

  scope :mentions_activerecord, lambda {
    where(['topics.title LIKE ?', '%ActiveRecord%'])
  }
  scope :distinct, lambda {
    select("DISTINCT #{table_name}.*")
  }
end
