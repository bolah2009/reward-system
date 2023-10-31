module RewardSystem
  class Node
    attr_accessor :points

    def initialize(invitee_name, inviter_node = nil)
      @name = invitee_name
      @inviter = inviter_node
      @accepts_invite = false
      @points = 0
      @node_depth = 0
    end

    def parent
      return @inviter if @accepts_invite

      nil
    end

    def remove_invite
      @inviter = nil
    end

    def accepted_invite?
      @accepts_invite
    end

    def accept_invite
      @accepts_invite = true
    end
  end
end
