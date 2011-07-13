module Coupler
  class DataUploader < CarrierWave::Uploader::Base
    def store_dir
      Coupler.upload_path
    end

    def cache_dir
      File.join(store_dir, 'tmp')
    end

    def filename
      if @filename
        @stored_filename ||= @filename.sub(/\..+?$/, "") + '-' + Digest::SHA1.hexdigest([@filename,
          Time.now.utc, rand].join) + File.extname(@filename)
      else
        super
      end
    end
  end
end
