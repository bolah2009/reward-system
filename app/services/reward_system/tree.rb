module RewardSystem
  class Tree
    SCORE_FACTOR = 0.5

    def initialize
      @store = {}
      @root_node = nil
    end

    # 2018-06-12 09:41 A (inviter) recommends B (invitee)
    def add_node(invitee_name, inviter_name)
      # dont accept any other invite except from the first invite
      return if node_exists? invitee_name

      inviter_node = find_or_create_inviter_node(inviter_name)
      create_node(invitee_name, inviter_node)
    end

    # 2018-06-14 09:41 B accepts
    def accept_invite(invitee_name)
      # dont accept invite for invitation that does not exist
      return unless node_exists?(invitee_name)

      invitee_node = @store[invitee_name]
      invitee_node.accept_invite

      assign_score invitee_node
    end

    def scores
      @store
        .transform_values(&:points)
        .reject { |_key, val| val <= 0 }
    end

    private

    def node_exists?(node_name)
      @store[node_name].present?
    end

    def assign_score(node)
      node = node.parent
      level = 0
      while node.present?
        node.points += score(level)
        level += 1
        node = node.parent
      end
    end

    def score(level)
      SCORE_FACTOR**level
    end

    def find_or_create_inviter_node(inviter_name)
      return @store[inviter_name] if node_exists?(inviter_name)

      create_node(inviter_name)
    end

    def create_node(node_name, parent = nil)
      node = Node.new(node_name, parent)
      @store[node_name] = node
      node
    end
  end
end
