require 'httparty'
require './config.rb'

class RelayrClient
  include HTTParty
  base_uri 'http://localhost/api/v1'
  format :json
  debug_output $stdout
end

def client
  @client ||= RelayrClient
end

describe 'API' do
  before do
    [Story, Character, Paragraphe, Rule].each do |model|
      model.delete_all
    end
  end

  context 'GET /stories.json' do
    it 'returns no stories when there are no stories' do
      response = client.get('/stories.json')
      expect(response['stories'].size).to eq(0)
    end

    it 'returns stories when there are stories' do
      response = client.post('/stories.json', body: {title: 'story 1', size: '10', debug: 'off', paragraph: 'story 1 paragraph 1'})
      response = client.post('/stories.json', body: {title: 'story 2', size: '20', debug: 'off', paragraph: 'story 2 paragraph 1'})

      story_id = response['story']['id']
      2.upto(20) do |i|
        response = client.post("/stories/#{story_id}/paragraphs.json", body: {body: "story 2 paragraph #{i}"})
      end
      response = client.get('/stories.json')

      expect(response['stories'].size).to eq(2)

      # TODO: validate more properties
      expect(response['stories'][0]['title']).to eq('story 2')
      expect(response['stories'][0]['finished']).to eq(true)

      expect(response['stories'][1]['title']).to eq('story 1')
      expect(response['stories'][1]['finished']).to eq(false)
    end 
  end

  context 'POST /stories.json' do
    it 'creates story without rules' do
      response = client.post('/stories.json', body: {title: 'story 1', size: '10', debug: 'off', paragraph: 'story 1 paragraph 1'})
      expect(response['story']['id']).to be_numeric

      response = client.get('/stories.json')
      expect(response['stories'][0]['title']).to eq('story 1')
    end

    it 'creates story with rules' do
      response = client.post('/stories.json', body: {title: 'story 1', size: '10', debug: 'off', paragraph: 'story 1 paragraph 1'})
      expect(response['story_id']).to be_numeric
    end

    context 'errors' do
    end
  end

  context 'GET /stories/travel.json' do
  end

  context 'GET /stories/:id.json' do
    it 'returns only previous paragraph when story is not finished' do
    end

    it 'returns all paragraphs when story is not finished' do
    end
  end

  context 'POST /stories/:id/paragraphs.json' do
    context 'errors' do
    end
  end

  context 'GET /stories/:id/image_urls.json' do
  end

  context 'POST /stories/:id/characters.json' do
  end

  context 'DELETE /stories/:id/characters/:character_id.json' do
  end

  context 'PUT /stories/:id/characters.json' do
  end
end
