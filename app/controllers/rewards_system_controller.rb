class RewardsSystemController < ApplicationController
  def reward_points
    points = RewardSystemService::Calculator.new(data).generate_scores

    render json: points, status: :ok
  end

  def data
    request.raw_post
  end
end
