module ExpensesHelper
  def reset_expenses_lines
    page.select('[class~=edition]').each do |element|
      page.visual_effect :fade, element.readAttribute('id'), :queue => 'end', 
                         :afterFinish => "function(effect){$(effect.element).removeClassName('edition').update('')}"
    end
    page.select('[class~=editing]').each do |element|
      page.visual_effect :appear, element.readAttribute('id'), :queue => 'end', 
                         :afterFinish => "function(effect){$(effect.element).removeClassName('editing')}"
    end
  end
  
  def show_expense_edition(expense)
    page.replace_html "EditGasto_#{expense.id}", :partial => 'form', :locals => {:table => true}
    page.visual_effect :fade, "ShowGasto_#{expense.id}", :queue => 'end',
                       :afterFinish => "function(effect){$(effect.element).addClassName('editing')}"
    page.visual_effect :appear, "EditGasto_#{expense.id}", :queue => 'end', 
                       :afterFinish => "function(effect){$(effect.element).addClassName('edition')}"
    page.visual_effect :highlight, "EditGasto_#{expense.id}", :queue => 'end'
  end

  def hide_expense_edition(expense, modified)
    if modified
      page.replace_html "ShowGasto_#{expense.id}", :partial => 'expense_line', :locals => {:expense => expense}
    end
    page.visual_effect :fade, "EditGasto_#{expense.id}", :queue => 'end', 
                       :afterFinish => "function(effect){$(effect.element).removeClassName('edition').update('')}"
    page.visual_effect :appear, "ShowGasto_#{expense.id}", :queue => 'end',
                       :afterFinish => "function(effect){$(effect.element).removeClassName('editing')}"
    page.visual_effect :highlight, "ShowGasto_#{expense.id}", :queue => 'end'
  end

  def show_add_form(copying)
    #page.replace_html "NuevoGasto", :partial => 'form', :locals => {:table => false}
    page.replace_html "NuevoGasto", :partial => 'form', :locals => {:table => false} if copying
    show_element_if_hidden 'adding'
  end

  def show_import
    show_element_if_hidden 'importing'
  end

  def show_filter
    show_element_if_hidden 'filtering'
  end

  def hide_add_form
    hide_element_if_shown 'adding'
    #page.visual_effect :blind_up, 'NuevoGasto', :queue => 'end', :afterFinish => "function(effect){$(effect.element).removeClassName('adding').addClassName('notadding').update('')}"
  end

  def hide_import
    hide_element_if_shown 'importing'
  end

  def hide_filter
    hide_element_if_shown 'filtering'
  end

  def hide_upper_divs
    hide_add_form
    hide_import
    hide_filter
  end

  private

  def show_element_if_hidden(css_class)
    page.select("[class~=not#{css_class}]").each do |element|
      page.visual_effect :blind_down, element.readAttribute('id'), :queue => 'end', 
                         :afterFinish => "function(effect){$(effect.element).removeClassName('not#{css_class}').addClassName('#{css_class}')}"
    end
  end

  def hide_element_if_shown(css_class)
    page.select("[class~=#{css_class}]").each do |element|
      page.visual_effect :blind_up, element.readAttribute('id'), :queue => 'end', 
                         :afterFinish => "function(effect){$(effect.element).removeClassName('#{css_class}').addClassName('not#{css_class}')}"
    end
  end

end
