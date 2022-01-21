module RewardSystem
  class Calculator
    def initialize(data)
      @data = ParseData.new(data)
      @tree = Tree.new
    end

    def generate_scores
      populate_data
      @tree.scores
    end

    private

    def populate_data
      @data.transform.each do |row|
        case row[:action]
        when :recommend
          @tree.add_node(row[:invitee], row[:inviter])
        when :accept
          @tree.accept_invite(row[:accepter])
        end
      end
    end
  end
end
