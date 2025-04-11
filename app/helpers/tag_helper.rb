# rubocop:disable all
module TagHelper
  include BootstrapHelper
  ####################################
  #         link_to_remote           #
  ####################################
  JS_ESCAPE_MAP = {
    '\\' => '\\\\',
    "</" => '<\/',
    "\r\n" => '\n',
    "\n" => '\n',
    "\r" => '\n',
    '"' => '\\"',
    "'" => "\\'",
    "\342\200\250" => "&#x2028;"
  }.freeze

  CALLBACKS = Set.new(%i[complete error] +
                        (100..599).to_a)

  def escape_javascript(javascript)
    if javascript
      result = javascript.gsub(%r{(\\|</|\r\n|\342\200\250|[\n\r"'])}u) { |match| JS_ESCAPE_MAP[match] }
      javascript.html_safe? ? result.html_safe : result
    else
      ""
    end
  end

  def escape_html(html, safe_html=false)
    html_ = ERB::Util.html_escape(html.to_s)
    safe_html ? html_.html_safe : html_
  end

  def link_to_remote(name, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options
      options = name
      name = block
    end
    options ||= {}
    html_options ||= {}
    link_to_function(name, remote_function(options), html_options || options.delete(:html), &block)
  end

  def link_to_function(name, function, html_options = {}, &block)
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || "#"
    content_tag(:a, name, html_options.merge(href: href, onclick: onclick), &block)
  end

  def remote_function(options = {})
    javascript_options = options_for_ajax(options)
    callbacks = build_callbacks(options)

    function = ""

    update = ''
    if options[:update] && options[:update].is_a?(Hash)
      update  = []
      update << "success:'#{options[:update][:success]}'" if options[:update][:success]
      update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
      update  = '{' + update.join(',') + '}'
    elsif options[:update]
      update << "'#{options[:update]}'"
    end

    function << "jQuery.ajax({"
    function << "type: '#{ options[:method] ? options[:method] : 'GET' }',"
    function << "url:  '#{ options[:url] ? url_for(options[:url]) : '#' }',"
    function << "data: #{ javascript_options },"
    callbacks.each {|callback,code| function << "#{callback.to_s}: #{code}, " } if callbacks.present?
    function << "success: function(data) {"
    function << options[:success] + '; ' if options[:success].present?
    function << if options[:position]
                  case options[:position].to_sym
                    when :top
                      "jQuery('##{options[:update]}').prepend(data); "
                    when :bottom
                      "jQuery('##{options[:update]}').append(data); "
                    when :before
                      "jQuery('##{options[:update]}').before(data); "
                    when :after
                      "jQuery('##{options[:update]}').after(data); "
                    when :colorbox
                      "jQuery.colorbox({html: data}) "
                    else
                      "jQuery('##{options[:update]}').html(data); "
                  end
                else
                  "jQuery('##{options[:update]}').html(data); "
                end
    function << "#{loading_close if options[:loading]}} });"


    function = "#{options[:before]}; #{function}" if options[:before]
    function = "#{function}; #{options[:after]};"  if options[:after]
    function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
    #function = "if (confirm('#{escape_javascript(options[:confirm])}')) { #{function}; }" if options[:confirm]
    if options[:confirm]
      function = "if (confirm('#{escape_javascript(options[:confirm])}')) { #{function}; } else {#{"#{loading_close};" if options[:loading]}}"
    end
    if options[:loading]
      function = "#{loading_open}#{function};"
    end

    return function.html_safe
  end

  def options_for_ajax(options)
    js_options = {}

    if options[:submit]
      submit = options[:submit]
      submit = [submit] if submit.is_a?(String)
      #カード番号の情報を除外して送る
      #js_options["parameters"] = "jQuery('#{submit.map { |i| "##{i} input, ##{i} textarea,  ##{i} select, ##{i}" }.join(',')}').serialize('')"
      js_options["parameters"] = "jQuery('#{submit.map { |i| "##{i} input, ##{i} textarea,  ##{i} select, ##{i}" }.join(',')}').not(\".delete_card_info\").serialize('')"
    elsif options[:with]
      js_options["parameters"] = options[:with]
    end
    if protect_against_forgery? && !options[:form]
      if js_options["parameters"]
        js_options["parameters"] << " + '&"
      else
        js_options["parameters"] = "'"
      end
      js_options["parameters"] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}')"
    end

    js_options["parameters"] = {} if js_options["parameters"].blank?

    js_options["parameters"]
  end

  def build_callbacks(options)
    callbacks = {}
    options.each do |callback, code|
      callbacks[callback] = "function(request){#{code}}" if CALLBACKS.include?(callback)
    end
    callbacks
  end

  def link_to_modal(name, options = {}, html_options = {}, mode = "bootstrap4modal")
      options[:update] = "modal-body"

      # complete = "disableEnterKeySubmission();"
      complete = ""
      case mode
      when "colorbox"
        complete += "$.colorbox.resize();"
        complete += "jQuery.colorbox.reloadOnClosed();" if options[:reload]
      when "bootstrap4modal"
        modal_size = options[:size] || "90%"
        # complete += "$('.modal-content').css('width', '#{modal_size}');"
        complete += "$('.modal-xl').css('min-width', '#{modal_size}');"
        complete += "$('#modal').modal('show');"
        complete += "$('#modal .modal-close').click(function(){ $('#modal').modal('hide'); set_select2();});"
      end

      options[:complete] = "#{options[:complete]};#{complete}"

      html_options[:href] = "#modal-body"
      html_options[:data] = { :"#{mode}".to_sym => true }
      link_to_remote(name, options, html_options)
  end
  def html_text_js(html_ids)
    html_mode = []
    html_ids.each do |html_id|
      html_mode << (<<-HTML
      var editor_#{html_id} = CodeMirror.fromTextArea(document.getElementById("#{html_id}"), {
        mode: "text/html",
        lineNumbers: true,
        lineWrapping: true,
        extraKeys: {"Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); }},
        foldGutter: true,
        height: "100%",
        gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
      });
      HTML
      )
    end
    html_mode.join("\n").html_safe
  end
  #TODO:summernote使う場合
  def rich_text_js(team_id,html_ids=[],opt={})
    html_ =  html_ids.map do |html_id|
      <<-HTML
         $('##{html_id}').summernote({
            height: #{opt[:height] || "305"},
            fontNames: ["YuGothic", "Yu Gothic", "Hiragino Kaku Gothic Pro", "Meiryo", "sans-serif", "Arial", "Arial Black", "Comic Sans MS", "Courier New", "Helvetica Neue", "Helvetica", "Impact", "Lucida Grande", "Tahoma", "Times New Roman", "Verdana"],
            lang: "ja-JP",
            toolbar: [
              ['style', ['bold', 'italic', 'underline', 'clear']],
              ['font', ['strikethrough']],
              ['fontsize', ['fontsize']],
              ['color', ['color']],
              ['table', ['table']],
              ['insert', ['link', 'picture']],
              ['view', ['fullscreen', 'codeview']],
              ['para', ['ul', 'ol', 'paragraph']],
            ],
            callbacks: {
              onImageUpload: function(files) {
                  #{loading_open}
                  sendFile#{html_id}(files[0]);
              },
              onChange: function(e) {
                
              }
        }
        });
        function sendFile#{html_id}(file) {
            data = new FormData();
            data.append("file", file);
            $.ajax({
                data: data,
                type: "POST",
                url: "#{"xxx"}",
                cache: false,
                contentType: false,
                processData: false,
                success: function(data) {
                    $('##{html_id}').summernote('insertImage', data.url);
                    #{loading_close}
                },error: function(data) {
                  alert('このファイルは設定できません');
                  #{loading_close}
                }
            })
        }
      HTML
    end
    return html_.join("\n").html_safe
  end

  def input_mode(mode = :text)
    mode_text =
      case mode
      when :zip, :tel, :number
        "tel"
      when :date
        "date"
      when :email
        "email"
      when :url
        "url"
      else
        "text"
      end
    mode_text
  end
  def date_select_ja(object_name, method, options = {}, html_options = {})
    options[:include_blank]     ||= true
    options[:use_month_numbers] ||= true
    options[:start_year]        ||= Time.now.year
    options[:end_year]          ||= 1900
    options[:default]           ||=  Date.new(Date.today.year - 25, 1, 1)
    options[:date_separator]    ||=  '%s'

    _object = instance_variable_get("@#{object_name}")
    if _object&.send(method).blank? && @target_config.default_birthday_use.available?
      options[:selected]          ||=  Time.now.year - @target_config.birthday_year_default.to_i
    end

    options = options.merge(
      year_format: ->(year) {
        year_ja = case year
                  when 0..1911     ; "明治#{year - 1867}"
                  when 1912        ; "大正元年"
                  when 1913..1925  ; "大正#{year - 1911}"
                  when 1926        ; "昭和元年"
                  when 1927..1988  ; "昭和#{year - 1925}"
                  when 1989        ; "平成元年"
                  when 1990..2018  ; "平成#{year - 1988}"
                  when 2019        ; "令和元年"
                  else             ; "令和#{year - 2018}"
                  end
        "#{year}(#{year_ja})"

      }) unless options[:year_format]
    (" <div class='input_single single_flex input_year'>
      <div class='select_wrap form_num'>
        #{sprintf(
      date_select(object_name, method, options , html_options),
      '</div> <p>年</p></div><div class="input_single single_flex input_month"><div class="select_wrap form_num">',
      '<p>月</p></div></div><div class="input_single single_flex input_day"><div class="select_wrap form_num">') +
      '<p>日</p></div></div>'}").html_safe
  end


  def ime_mode(mode = :auto)
    mode_ = {
      auto: "ime-mode: auto;",
      active: "ime-mode: active; ",
      kana: "ime-mode: active; ",
      disabled: "ime-mode: disabled;",
      inactive: "ime-mode: inactive;"
    }
    mode_[mode]
  end
  def loading_open(mode=:admin)
    _js = "loading_open();"
    _js.html_safe
  end
  def loading_close(mode=:admin)
    _js = "loading_close();"
    _js.html_safe
  end
end
# rubocop:enable all
