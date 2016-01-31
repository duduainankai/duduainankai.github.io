module Jekyll
  class CategoryListTag < Liquid::Tag
    def render(context)
      html = ""
      categories = context.registers[:site].categories.keys
      categories.sort.each do |category|
        posts_in_category = context.registers[:site].categories[category].size
        category_dir = context.registers[:site].config['category_dir']
        category_url = File.join(category_dir, category.gsub(/_|\P{Word}/u, '-').gsub(/-{2,}/u, '-').to_url.downcase)
        font_size = 20
        if posts_in_category <= 6
            font_size = (posts_in_category - 1) * 2 + 20
        elsif posts_in_category > 6
            font_size = (posts_in_category - 6) * 0.8 + 30
        end
        html << "<li class='category'><a href='/#{category_url}/' style='font-size: #{font_size}px;' >#{category} (#{posts_in_category})</a></li>\n"
      end
      html
    end
  end
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)