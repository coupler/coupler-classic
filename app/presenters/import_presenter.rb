module Coupler
  class ImportPresenter
    include Lotus::Presenter

    def forme_input(form, field, opts)
      opts = {
        key:   field,
        label: label_for(field) + ':',
        labeler: :explicit,
        wrapper: :div
      }.merge(opts)

      type = :text
      case field
      when :path
        type = :file
      end

      Forme::Input.new(form, type, opts)
    end

    def label_for(field)
      case field
      when :path then 'File'
      end
    end
  end
end
