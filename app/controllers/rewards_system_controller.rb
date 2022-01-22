class RewardsSystemController < ApplicationController
  def reward_points
    service = RewardSystem::Main.new data
    return render json: { errors: service.errors }, status: :unprocessable_entity if service.invalid?

    render json: service.generate_scores, status: :ok
  end

  def data
    return params[:text_input_data] if params[:text_input_data].present?
    return params[:file_input_data].read if params[:file_input_data].present?

    request.raw_post
  end
end
