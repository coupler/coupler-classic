module Coupler
  class DataUploader < CarrierWave::Uploader::Base
    def store_dir
      Coupler::Config.get(:upload_path)
    end
  end
end
