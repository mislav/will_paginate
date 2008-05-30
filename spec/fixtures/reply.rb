class Reply < ActiveRecord::Base
  belongs_to :topic, :include => [:replies]

  named_scope :recent, :conditions => ['replies.created_at > ?', 15.minutes.ago]
  
  validates_presence_of :content
end
