require 'rails_helper'

RSpec.describe VideosController, type: :controller do
  let(:video_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'sample.mp4'), 'video/mp4') }

  before(:all) do
    Video.destroy_all
  end

  def create_video
    video = Video.create(
      title: "Sample one",
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'sample.mp4'), 'video/mp4'),
      content_type: 'video/mp4'
    )
  end

  describe 'POST #create' do
    context 'when the video is uploaded successfully' do
      it 'returns a success message and creates a video' do
        post :create, params: { video: { title: 'Test Video', file: video_file } }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Video uploaded successfully')
        expect(Video.count).to eq(1)
      end
    end

    context 'when the file size exceeds the limit' do
      it 'returns an error message' do
        # Mocking class to reproduce file size limit error 
        allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return((MAX_FILE_SIZE_MB + 1).megabyte)

        post :create, params: { video: { title: 'Test Video', file: video_file } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq("File is too large. Maximum allowed size is #{MAX_FILE_SIZE_MB} MB.")
      end
    end

    context 'when no file is uploaded' do
      it 'returns an error message' do
        post :create, params: { video: { title: 'Test Video' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('No file uploaded')
      end
    end
  end

  describe 'GET #show' do
    context 'when the video exists' do
      it 'returns the video details' do
        video = create_video
        get :show, params: { id: video.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['video']['id']).to eq(video.id)
        expect(JSON.parse(response.body)['download_url']).to be_present
      end
    end

    context 'when the video does not exist' do
      it 'returns an error message' do
        get :show, params: { id: '-99' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Video unavailable')
      end
    end
  end

  describe 'POST #trim' do
    let(:trim_video) { create_video }
    context 'when the trim parameters are valid' do
      it 'returns a success message and trims the video' do
        post :trim, params: { id: trim_video.id, start_time: 1, end_time: 5 }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Video trimmed successfully')
      end
    end

    context 'when the trim parameters are invalid' do
      it 'returns an error message for invalid start_time and end_time' do
        post :trim, params: { id: trim_video.id, start_time: 0, end_time: 10 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid start_time or end_time')
      end
    end

    context 'when the video cannot be trimmed' do
      it 'returns an error message' do
        allow_any_instance_of(VideoManipulator).to receive(:trim).and_return(false)

        post :trim, params: { id: trim_video.id, start_time: 1, end_time: 7 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Failed to trim video')
      end
    end
  end

  describe 'POST #merge' do
    let(:video1) { create_video }
    let(:video2) { create_video }

    context 'when the merge parameters are valid' do
      it 'returns a success message and merges the videos' do
        post :merge, params: { video1_id: video1.id, video2_id: video2.id }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Videos merged successfully')
      end
    end

    context 'when one or both videos are not found' do
      it 'returns an error message' do
        post :merge, params: { video1_id: 'dummy', video2_id: video2.id }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('One or both videos not found')
      end
    end

    context 'when merging fails' do
      it 'returns an error message' do
        allow_any_instance_of(VideoManipulator).to receive(:merge).and_return(double(errors: double(full_messages: ['Merge failed'])))

        post :merge, params: { video1_id: video1.id, video2_id: video2.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Failed to merge videos: Merge failed')
      end
    end
  end

  describe 'GET #download' do
    let(:video) { create_video }
    context 'when the video exists and has an attachment' do
      it 'returns the video file' do
        get :show, params: { id: video.id }, format: :json
        key = JSON.parse(response.body)['download_url'].split('=').last
        get :download, params: { video: key }

        expect(response).to have_http_status(:ok)
        expect(response.header['Content-Type']).to eq('video/mp4')
        expect(response.header['Content-Disposition']).to include('attachment')
      end
    end

    context 'when the video does not exist' do
      it 'returns an error message' do
        get :download, params: { video: 'dummy' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Video unavailable to download')
      end
    end

    context 'when the video does not have an attachment' do
      it 'returns an error message' do
        get :show, params: { id: video.id }, format: :json
        key = JSON.parse(response.body)['download_url'].split('=').last
        video.update_column(:attachment_id, nil)

        get :download, params: { video: key }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('File not found')
      end
    end
  end
end