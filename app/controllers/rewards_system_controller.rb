class RewardsSystemController < ApplicationController
  def reward_points
    Rails.logger.info request.raw_post.inspect.to_s
    points = RewardSystemService::Calculator.new(data).generate_scores

    render json: points, status: :ok
  end

  def data
    request.raw_post
  end
end
