require 'logger'
require 'nokogiri'
require 'json'
require './page_saver.rb'
require './config_loader.rb'

############## Initialize
conf = ConfigLoader.load('tennis.conf')
JSON_OUTDIR = conf::JSON_OUT_DIR || 'file/json'
HTML_OUTDIR = conf::HTML_OUT_DIR || 'file/html'
logdir = conf::LOG_DIR || 'log'
#$log = Logger.new("#{logdir}/#{File.basename(__FILE__)}.log",'daily')
$log = Logger.new(STDOUT)
$log.level = conf::LOG_LEVEL

$log.info File.basename(__FILE__)+' start'

############# page convert html to json
$log.info "converting player page to json"

infiles = Dir.glob("#{HTML_OUTDIR}/atp_player_*.html")
#$log.debug infiles
#$log.debug infiles.reject!{|f| f =~ /.*ranking_history.*/}
infiles.reject!{|f| f =~ /.*ranking_history.*/}
infiles.each do |infile|
#  $log.debug infile.match(/atp_player_.*/)[0].gsub(/atp_player_/,'').gsub(/.html/,'')
  id = infile.match(/atp_player_.*/)[0].gsub(/atp_player_/,'').gsub(/.html/,'')
#  id="RogerFederer"
#infile = "#{HTML_OUTDIR}/atp_player_#{id}.html"
  doc = File.open(infile) {|f| Nokogiri::HTML(f) }
  
  first_name = doc.at('div.player-profile-hero-name > div.first-name').text.strip
  last_name = doc.at('div.player-profile-hero-name > div.last-name').text.strip
  name = "#{first_name} #{last_name}"
  country_code = doc.at('div.player-flag-code').text.strip
  birthday = doc.at('span.table-birthday').text.gsub(/(\(|\))/,'').strip
  turned_pro = doc.at('//div[contains(text(),"Turned Pro")]').parent.at('div.table-big-value').text.strip
  weight_lbs = doc.at('span.table-weight-lbs').text.strip
  height_ft = doc.at('span.table-height-ft').text.strip
  birthplace = doc.at('//div[contains(text(),"Birthplace")]').parent.at('div.table-value').text.strip
  residence = doc.at('//div[contains(text(),"Residence")]').parent.at('div.table-value').text.strip
  plays = doc.at('//div[contains(text(),"Plays")]').parent.at('div.table-value').text.strip
  coach = doc.at('//div[contains(text(),"Coach")]').parent.at('div.table-value').text.strip
  player = {
    :id => id,
    :name => name,
    :country_code => country_code,
    :birthday => Date.parse(birthday),
    :turned_pro => turned_pro,
    :weight_lbs => weight_lbs,
    :height_ft => height_ft,
    :birthplace => birthplace,
    :residence => residence,
    :plays => plays,
    :coach => coach,
  }
  #$log.info JSON.pretty_generate(player)
  FileUtils.mkdir_p(JSON_OUTDIR) unless Dir.exist?(JSON_OUTDIR)
  outfile_full=File.join(JSON_OUTDIR,"player_#{id}.json")
  File.write(outfile_full, JSON.pretty_generate(player))
  $log.info {"converted successful #{infile} to #{outfile_full}"}
end
$log.info File.basename(__FILE__)+' end'
