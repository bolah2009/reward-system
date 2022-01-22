require 'rails_helper'

RSpec.describe 'RewardsSystemController', type: :request do
  describe 'POST /rewards' do
    let(:json_response) { JSON.parse response.body }
    let(:file_input_data) { fixture_file_upload(filename, 'text/plain') }

    before { post '/rewards', params: params, headers: { 'Content-Type': 'text/plain' } }

    shared_examples 'responding with a failed response' do
      it 'fails' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    shared_examples 'responding with a successful response' do
      it 'succeeds' do
        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples 'responding with the correct score' do
      it_behaves_like 'responding with a successful response'

      it 'returns a valid score' do
        expect(json_response).to eq score
      end
    end

    context 'with empty params' do
      let(:params) { '' }

      it_behaves_like 'responding with a failed response'

      it 'respond with an error' do
        expect(json_response['errors']).to have_key 'data'
      end
    end

    context 'with non-empty invalid params' do
      let(:params) { '2020-02-09 02:21 A recommends' }

      it_behaves_like 'responding with a failed response'

      it 'respond with an error' do
        expect(json_response['errors']).to have_key 'format'
      end
    end

    context 'with non-empty invalid datetime' do
      let(:params) { '2020-82-09 72:21 A recommends B' }

      it_behaves_like 'responding with a failed response'

      it 'respond with an error' do
        expect(json_response['errors']).to have_key 'date'
      end
    end

    context 'when params is simple (1 level)' do
      let(:params) do
        <<-DATA
          2020-02-09 02:21 A recommends B
          2020-03-19 05:51 B accepts
        DATA
      end

      let(:score) { { 'A' => 1.0 } }

      it_behaves_like 'responding with the correct score'
    end

    context 'when params is complex (5 levels)' do
      let(:filename) { 'complex_5_level.txt' }
      let(:params) { { file_input_data: file_input_data } }

      let(:score) { { 'A' => 1.9375, 'B' => 1.875, 'C' => 1.75, 'D' => 1.5, 'E' => 1.0 } }

      it_behaves_like 'responding with the correct score'
    end

    context 'when params is not ordered chronologically' do
      let(:filename) { 'chronologically_unordered.txt' }
      let(:params) { { file_input_data: file_input_data } }
      let(:score) { { 'A' => 1.9375, 'B' => 1.875, 'C' => 1.75, 'D' => 1.5, 'E' => 1.0 } }

      it_behaves_like 'responding with a successful response'

      it 're-order data chronologically and respond with the correct score' do
        expect(json_response).to eq score
      end
    end

    context 'when params has multiple invites for same person' do
      let(:params) do
        <<-DATA
          2020-02-09 02:21 A recommends B
          2020-02-09 07:21 A recommends B
          2020-03-19 05:51 B accepts
        DATA
      end

      let(:score) { { 'A' => 1.0 } }

      it_behaves_like 'responding with a successful response'

      it 'only first invitation counts' do
        expect(json_response).to eq score
      end
    end

    context 'when params has multiple invites for different person' do
      let(:filename) { 'multiple_invites.txt' }
      let(:params) { { file_input_data: file_input_data } }
      let(:score) { { 'A' => 1.9375, 'B' => 1.875, 'C' => 1.75, 'D' => 1.5, 'E' => 1.0 } }

      it_behaves_like 'responding with a successful response'

      it 'only first invitation counts' do
        expect(json_response).to eq score
      end
    end

    context 'with joined tree-like network (single person with multiple recommendations)' do
      let(:filename) { 'joined_network.txt' }
      let(:params) { { file_input_data: file_input_data } }
      let(:score) { { 'A' => 4.75, 'B' => 7.5, 'C' => 3.0, 'D' => 3.0, 'E' => 3.0 } }

      it_behaves_like 'responding with the correct score'
    end

    context 'with disjoint tree-like network (single person with multiple recommendations)' do
      let(:filename) { 'disjoint_network.txt' }
      let(:params) { { file_input_data: file_input_data } }
      let(:score) { { 'A' => 2.5, 'B' => 2.0, 'C' => 1.0, 'E' => 2.0, 'F' => 2.0 } }

      it_behaves_like 'responding with the correct score'
    end

    context 'when users does not accept recommendations' do
      let(:params) do
        <<-DATA
        2020-02-09 02:21 A recommends B
        2020-02-09 02:21 B recommends C
        2020-02-09 02:21 C recommends D
        DATA
      end

      it_behaves_like 'responding with a successful response'

      it 'no score is awarded to inviter' do
        expect(json_response).to be_empty
      end
    end

    context 'when a user accepts recommendation after recommending another user' do
      let(:params) do
        <<-DATA
        2020-02-09 02:21 A recommends B
        2020-02-09 02:22 B recommends C
        2020-03-19 05:51 C accepts
        2020-03-19 05:51 B accepts
        DATA
      end

      let(:score) { { 'B' => 1.0 } }

      it_behaves_like 'responding with a successful response'

      it 'does not accept outdated invitation' do
        expect(json_response).to eq score
      end
    end
  end
end
