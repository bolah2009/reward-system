require 'rails_helper'

RSpec.describe 'RewardsSystemController', type: :request do
  describe 'POST /rewards' do
    let(:json_response) { JSON.parse response.body }

    before { post '/rewards', params: params, headers: { 'Content-Type': 'text/plain' } }

    shared_examples 'responding with a failed response' do
      it 'fails' do
        expect(response).to have_http_status(:unprocessable_entity)
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

    context 'with valid params' do
      let(:params) do
        <<-DATA
          2020-02-09 02:21 A recommends B
          2020-03-19 05:51 B accepts
          2020-04-29 08:01 B recommends C
        DATA
      end

      it 'succeeds' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a valid score' do
        expect(json_response).to have_key 'A'
      end
    end
  end
end
