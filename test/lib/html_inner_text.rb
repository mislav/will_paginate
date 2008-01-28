require 'action_controller/test_process'

module HTML
  class Node
    def inner_text
      children.map(&:inner_text).join('')
    end
  end
  
  class Text
    def inner_text
      self.to_s
    end
  end

  class Tag
    def inner_text
      childless?? '' : super
    end
  end
end
