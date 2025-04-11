module BootstrapHelper
  def alert_message(**options)
    color    = options[:color]
    title    = options[:title]
    messages = options[:messages] || ''
    messages = [messages] if messages.is_a?(ApplicationRecord)

    if messages.is_a?(Array)
      messages = messages.map do |i|
        i.is_a?(ApplicationRecord) ? i.generate_error_messages : i
      end.flatten.uniq
    end

    return '' if title.blank? && messages.blank?

    if title.present?
      title = "<h6 class=\"alert-heading\">#{title}</h6><hr>"
    end
    html = <<~HTML
      <div class="alert alert-#{color} alert mb-0">
        #{title}
        <p class="mb-0">
          #{messages.to_lists.join('<br/>')}
        </p>#{'   '}
      </div>
    HTML
    html.html_safe
  end
  #########   ACTION ICON   #########

  def icon_add
    '<i class="fas fa-plus"></i>'.html_safe
  end

  def icon_del
    '<i class="fas fa-trash-alt"></i>'.html_safe
  end

  #########   ACTION COLOR   #########
  def color_new
    color_info
  end

  def color_edit
    color_warning
  end

  def color_show
    color_success
  end

  def color_destroy
    color_danger
  end

  def color_add
    color_info
  end

  def color_submit
    color_success
  end

  def color_copy
    color_info
  end

  def color_search
    color_primary
  end

  def color_clear
    color_secondary
  end

  def color_file_generate
    color_success
  end

  def color_download
    color_secondary
  end

  def color_item_normal
    color_primary
  end

  def color_item_periodical
    color_success
  end

  #########   BASE COLOR   #########
  def color_primary
    'primary'
  end

  def color_secondary
    'secondary'
  end

  def color_success
    'success'
  end

  def color_warning
    'warning'
  end

  def color_info
    'info'
  end

  def color_danger
    'danger'
  end
end