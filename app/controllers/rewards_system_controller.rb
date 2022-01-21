class RewardsSystemController < ApplicationController
  def reward_points
    service = RewardSystemService::Main.new data
    return render json: { errors: service.errors }, status: :unprocessable_entity if service.invalid?

    render json: service.generate_scores, status: :ok
  end

  def data
    request.raw_post
  end
end
