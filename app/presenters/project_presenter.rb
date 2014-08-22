module Coupler
  class ProjectPresenter
    include Lotus::Presenter

    def forme_input(form, field, opts)
      opts = {
        key:   field,
        value: @object.send(field),
        label: label_for(field) + ':',
        labeler: :explicit,
        wrapper: :div
      }.merge(opts)
      type = :text

      Forme::Input.new(form, type, opts)
    end

    def label_for(field)
      case field
      when :name then 'Name'
      when :description then 'Description'
      end
    end
  end
end
