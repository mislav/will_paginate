class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :project

  # pretend find and count were extended and accept an extra option
  class << self
    # if there is a :foo option, prepend its value to collection
    def find(*args)
      more = []
      more << args.last.delete(:foo) if args.last.is_a?(Hash) and args.last[:foo]
      res = super(*args)
      more.empty?? res : more + res
    end

    # if there is a :foo option, always return 100
    def count(*args)
      return 100 if args.last.is_a?(Hash) and args.last[:foo]
      super(*args)
    end
  end
end
