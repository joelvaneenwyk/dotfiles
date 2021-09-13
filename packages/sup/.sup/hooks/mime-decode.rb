require 'shellwords'

unless sibling_types.member? "text/plain"
  case content_type
  when "text/html"
    `html2markdown #{Shellwords.escape filename} latin_1 | sed 's/&nbsp_place_holder;/ /g'`
  end
end

