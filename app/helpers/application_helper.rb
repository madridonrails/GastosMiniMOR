require 'digest/sha1'

module ApplicationHelper
  include FormatterHelper
  include LoginUrlHelper

  # The application logo as an image tag.
  def gastosmini_logo
    image_tag 'logo-gastosmini.png', :alt => "#{APP_NAME}: gastos fácil", :title => "#{APP_NAME}: gastos fácil"
  end
  
  # Returns the logo of the application already linked to the (public) home.
  def gastosmini_logo_linked_to_home
    link_to gastosmini_logo, "http://www.#{account_domain}"
  end

  def video_tag(filename, width, height, options={})
    if filename =~ /\.flv$/
      flash_video(filename, width, height, options)
    else
      quicktime_video(filename, width, height, options)
    end
  end

  # Based on the output of Pageot (http://www.qtbridge.com/pageot/pageot.html).
  def quicktime_video(filename, width, height, options={})
    url = "/videos/#{filename}"    
    return <<-HTML
    <object classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" width="#{width}" height="#{height}" codebase="http://www.apple.com/qtactivex/qtplugin.cab">
      <param name="src" value="#{url}" />
      <param name="controller" value="true" />
      <param name="autoplay" value="false" />
      <param name="showlogo" value="false" />
      <param name="cache" value="false" />
      <param name="href" value="#{url}" />
      <param name="SaveEmbedTags" value="true" />
      <embed
       src="#{url}"
       width="#{width}" height="#{height}"
       controller="true"
       autoplay="false"
       showlogo="false"
       cache="false"
       href="#{url}"
       SaveEmbedTags="true"
       type="video/quicktime"
       pluginspage="http://www.apple.com/quicktime/download/">
      </embed>
    </object>
    HTML
  end
  
  # Based on http://labnol.blogspot.com/2006/08/how-to-embed-flv-flash-videos-in-your.html.
  # We use the same stuff but put the player and the skin in our tree to avoid generating
  # traffic in the website pointed by the blog entry.
  def flash_video(filename, width, height, options={})
    url = CGI.escape("/videos/#{filename}")
    return <<-HTML
      <object width="#{width}" height="#{height}" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,19,0">
        <param name="salign" value="lt">
        <param name="quality" value="high">
        <param name="scale" value="noscale">
        <param name="wmode" value="transparent"> 
        <param name="movie" value="/flash/flvplay.swf">
        <param name="FlashVars" value="&amp;streamName=#{h(url)}&amp;skinName=/flash/flvskin&amp;autoPlay=true&amp;autoRewind=false">
        <embed width="#{width}" height="#{height}" 
          flashvars="&amp;streamName=#{h(url)}&amp;autoPlay=true&amp;autoRewind=false&amp;skinName=/flash/flvskin"
          quality="high"
          scale="noscale"
          salign="LT"
          type="application/x-shockwave-flash"
          pluginspage="http://www.macromedia.com/go/getflashplayer"
          src="/flash/flvplay.swf"
          wmode="transparent">
        </embed>
      </object>
    HTML
  end
  
  # Returns a link to a hot editable template.
  def link_to_hot_editable(name, action, section=nil, html_options={})
    link_to(name, {:controller => 'public', :action => action, :section => section}, html_options)
  end
    
  # See http://www.eulerian.com/en/opensource/datepicker-prototype-scriptaculous
  def date_picker(relative_to)
    return <<-HTML    
    <script type="text/javascript" charset="utf-8">
      new DatePicker({relative: '#{relative_to}', language: 'sp'});
    </script>    
    HTML
  end

  # We need the flag select_current_project in expense edition, where it is false.
  def project_selector(object, method, account, prompt, selected, options={}, html_options={})
    projects = project_combo_options(account)
    options = {:prompt => prompt, :selected => selected}.merge(options)
    select object, method, projects, options, html_options
  end

  def project_combo_options(account)
    account.projects.map {|p| [p.name, p.id]}
  end

  # We need the flag select_current_expense_type in expense edition, where it is false.
  def expense_type_selector(object, method, account, prompt, selected, options={}, html_options={})
    expense_types = expense_type_combo_options(account)
    options = {:prompt => prompt, :selected => selected}.merge(options)
    select object, method, expense_types, options, html_options
  end

  def expense_type_combo_options(account)
    account.expense_types.map {|et| [et.name, et.id]}
  end

  def envelope_combo_options(account)
    account.envelopes.map {|e| [e, e]}
  end

  def plain_selector_constructor(name, selected_id, combo, options={})
    option_tags = ''
    option_tags << combo.map do |n, i|
      selected = !selected_id.blank? && selected_id.to_s == i.to_s ? ' selected="selected"' : nil
      %Q{<option value="#{i}"#{selected}>#{n}</option>}
    end.join('')
    select_tag name, option_tags, options    
  end

  # Returns the project name linked to the projects show view.
  def link_to_project(project)
    link_to CGI.escapeHTML(project.name), :controller => 'projects', :action => 'show', :id => project
  end

  # Returns the expense type name linked to the projects show view.
  def link_to_expense_type(expense_type)
    link_to CGI.escapeHTML(expense_type.name), :controller => 'expense_types', :action => 'show', :id => expense_type
  end

  # Returns a link to the action that prepares a new expense for the given project.
  def link_to_new_expense_for(name, project)
    link_to name, :controller => 'expenses', :action => 'new', :from => 'project', :id => project
  end

  # Returns a link to the action that prepares a new expense for the given expense type.
  def link_to_new_expense_for_type(name, expense_type)
    link_to name, :controller => 'expenses', :action => 'new', :from => 'type', :id => expense_type
  end

  # Returns a link to the action that prepares a new expense from a given one.
  def link_to_new_expense_copying(name, expense)
    link_to name, :controller => 'expenses', :action => 'new', :from => 'copying', :id => expense
  end
  
  # Returns a link to the action that destroys an expense. It includes a confirmation dialog,
  # and uses POST.
  def link_to_destroy_expense(name, expense)
    link_to(
      name, 
      {:controller => 'expenses', :action => 'destroy', :id => expense},
      {:confirm => "Esta acción es irreversible.\n¿Está seguro de que desea borrar este gasto?", :method => :post}
    )
  end
  
  # Auxiliary helper to have a link in the view that shows a message
  # in a JavaScript dialog.
  def not_yet_implemented(name, msg="Not Yet Implemented", options={})
    link_to_function name, "alert('#{escape_javascript(msg)}')", options
  end

  # Returns a link to the previous page according to the browser's history,
  # that's plain-old JavaScript.
  def link_to_back(name)
    %Q{<a href="#" onclick="history.go(-1)">#{ERB::Util.html_escape(name)}</a>}
  end
  
  # If the object has validation errors on method, returns the list of messages.
  # We prepend a BR to each error message and the list is wrapped in a SPAN with
  # class "error" and id "errors_for_object_method". If there's no error message
  # the SPAN is still returned so that it is available to Ajax forms.
  #
  # This helper is thought for displaying error messages below their corresponding
  # fields.
  #
  # The HTML is coupled with the one generated by create_for_expense.rjs.
  def errors_for_attr(object, method)
    err_list = ''
    err = instance_variable_get("@#{object}").send(:errors).on(method)
    if err
      err = [err] if err.is_a?(String)
      err_list = %Q{<br />#{err.join("<br />")}}
    end
    return %Q(<span id="errors_for_#{object}_#{method}" class="error">#{err_list}</span>)
  end

  # Returns a question mark icon with a tooltip attached to it.
  def help(msg)
    tooltip_for_icon('icon-help.gif', msg)
  end
  
  # Returns an exclamation icon with a tooltip attached to it.
  def tooltip(msg, formatting=false, line_width=0)
    if msg.blank?
      return ''
    elsif formatting
      text = simple_format_without_p(word_wrap(msg, line_width))
    else
      text = msg
    end
    tooltip_for_icon('icon-comentario.gif', text)
  end
  
  def tooltip_for_icon(icon, text)
    tooltip_id = GastosminiUtils.random_hex_string
    tooltip_id = "a#{tooltip_id}" # HTML can't start with a number
    return <<-HTML
    #{image_tag("#{icon}", :class => 'question-mark', :title => '', :alt => '', :width => 16, :height => 16, :onmouseover => "TagToTip('#{tooltip_id}')")}
    <span id="#{tooltip_id}" style="display:none">#{text}</span>
    HTML
  end

  def simple_format_without_p(text)
    text.to_s.
      gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
      gsub(/\n/, "<br />\n")                  # 1 newline   -> br
  end

  # Renders the header of tables for listings, taking into account order and direction.
  # This helper had initially no embedded styles, but some CSS classes where added with
  # the final designs. Does not feel too clean but we will put them here by now.
  def table_header_remote(options, params={})
    options = {
      :non_orderable     => [],
      :current_order_by  => @current_order_by,
      :current_direction => @current_direction
    }.merge(options)
    
    html = '<tr class="table-row-head">'
    options[:url] ||= {}
    options[:update] ||= 'list'
    params.each { |param, value| options[:url][param.to_sym] = value }
    options[:url].merge!(:page => options[:current_page])
    options[:labels].each_with_index do |label, c|
      html << "<td class='TextTable11Grey#{2 if c.zero?}' nowrap='nowrap'>"
      if options[:non_orderable].include?(c)
        html << label
      else
        options[:url][:order_by] = c
        icon = ''
        if c == options[:current_order_by]
          icon = '&nbsp;' + (options[:current_direction] == 'ASC' ? image_tag('ico_arrow_up.png', :height => 11, :width => 11) : image_tag('ico_arrow_down.png', :height => 11, :width => 11))
          options[:url][:direction] = (options[:current_direction] == 'ASC' ? 'DESC' : 'ASC')
        else
          options[:url][:direction] = 'ASC'
        end
        html << link_to_remote(
          "#{label}#{icon}",
          :update => (options[:update]),
          :url    => options[:url]
        )
      end
      html << '</td>'
    end
    html << '</tr>'
    html
  end
  
  # Returns the links to pages for paginated listings.
  def pagination_browser(options, params={})
    options[:update] ||= 'list'
    options[:url][:action] ||= @current_action
    options[:success] = 'scroll(0,0)' # scroll to the top of the page
    html = []
    paginator = options[:paginator]
    params.each { |param, value| options[:url][param.to_sym] = value }
    if paginator.current.number > 1
      options[:url][:page] = paginator.first.number
      html << link_to_remote(
        image_tag('flecha_inicio.gif', :align => 'absmiddle'),
        options
      )
      options[:url][:page] = paginator.current.number - 1
      html << link_to_remote(
        image_tag('flecha_anterior.gif', :align => 'absmiddle'),
        options
      )      
    end
    html << "&nbsp;Página #{paginator.current.number} de #{paginator.length}&nbsp;"
    if paginator.current.number < paginator.length
      options[:url][:page] = paginator.current.number + 1
      html << link_to_remote(
        image_tag('flecha_siguiente.gif', :align => 'absmiddle'),
        options
      )
      options[:url][:page] = paginator.last.number
      html << link_to_remote(
        image_tag('flecha_ultima.gif', :align => 'absmiddle'),
        options
      )
    end
    html.join('&nbsp;')
  end
  
  # Returns an image tag with a default icon, which is an orange star. We use this while
  # we wait for icons in development, but should have no other occurrence in production.
  def missing_icon
    tooltip_id = GastosminiUtils.random_hex_string
    tooltip_id = "a#{tooltip_id}" # HTML can't start with a number
    return <<-HTML
    #{image_tag("missing-icon.png", :class => 'question-mark', :title => '', :alt => '', :width => 25, :height => 25, :style => 'vertical-align: middle', :onmouseover => "TagToTip('#{tooltip_id}')")}
    <span id="#{tooltip_id}" style="display:none">Icono pendiente</span>
    HTML
  end
  
  def colgroup_for_data_tables
    return <<-COLGROUP
    <colgroup>
      <col width="20%" />
      <col width="80%" />
    </colgroup>
    COLGROUP
  end

  #Formulario para upload de ficheros
  def form_remote_upload_tag(options={})
     options[:html] ||= {}
     options[:html][:id] = options[:html][:id] || 'remote_upload_form' #this needs to generate a unique ID
     options[:html][:target] = 'iframe-remote-upload-' + options[:html][:target] || 'iframe_remote_upload' 
     options[:html][:action] = options[:html][:action] || url_for(options[:url])
     options[:html][:action] += "?remote_upload_id=#{options[:html][:target]}" 
      
     tag('form', options[:html], true)
    
  end
  
  #Cierre del tag del formulario para upload de ficheros
  def end_form_remote_upload_tag(id)
    iframeid = 'iframe-remote-upload-' + id
    "<iframe id='#{iframeid}' name='#{iframeid}' style='height: 0pt; width: 0pt;' frameborder='0'></iframe></form>"
  end
  
end
