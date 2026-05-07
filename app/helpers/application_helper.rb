module ApplicationHelper
  def markdown_to_html(text)
    return ''.html_safe if text.blank?

    renderer = Redcarpet::Render::HTML.new(tables: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, tables: true, autolink: true, strikethrough: true)
    sanitize(markdown.render(text), tags: sanitizer_allowed_tags, attributes: sanitizer_allowed_attributes)
  end

  private

  def sanitizer_allowed_tags
    ActionView::Base.sanitized_allowed_tags.to_a +
      %w[table thead tbody tfoot tr th td colgroup col]
  end

  def sanitizer_allowed_attributes
    ActionView::Base.sanitized_allowed_attributes.to_a + %w[align]
  end
end
