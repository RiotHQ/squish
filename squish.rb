require 'json'

pages = {}

Dir.glob("*.html").each do |page|
   raw = File.read(page)
   
   body = raw.match(/<body(.*)<\/body>/m).to_s.gsub("<body>", "").gsub("</body>", "").to_s
   title = raw.match(/<title>(.*)<\/title>/m).to_s.gsub("<title>", "").gsub("</title>", "").to_s
   
   pages[page] = {title: title, body: body, filename: page}
end

js = File.read("assets/js/squish.js").gsub("\"{{SQUISH}}\"", pages.to_json)

File.open("assets/js/squish.js", "w") do |file|
  file.puts(js)
end