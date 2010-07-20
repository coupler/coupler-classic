module Coupler
  class DataUploader < CarrierWave::Uploader::Base
    def store_dir
      Coupler::Config.get(:upload_path)
    end

    def cache_dir
      File.join(Coupler::Config.get(:upload_path), 'tmp')
    end

    def filename
      if @filename
        @stored_filename ||= Digest::SHA1.hexdigest([@filename,
          Time.now.utc, rand].join) + File.extname(@filename)
      else
        super
      end
    end
  end
end
