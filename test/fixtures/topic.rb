class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :project

  named_scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']
  
  named_scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }
end
