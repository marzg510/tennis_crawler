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
#$log.level = conf::LOG_LEVEL
$log.level = Logger::DEBUG

$log.info File.basename(__FILE__)+' start'

############# page convert html to json
$log.info "converting player page to json"

id=1035

infile = "#{HTML_OUTDIR}/player_#{id}.html"
doc = File.open(infile) {|f| Nokogiri::HTML(f) }

content = doc.at('div.mod-content')
name = content.at('h1').text.strip
#$log.debug "name=#{name}"
bio = content.at('div.player-bio')
country = bio.at('ul.general-info > li.first').text.strip
#$log.debug "country=#{country}"
plays = bio.at('ul.general-info > li:nth-child(2)').text.split(':')[1].strip
#$log.debug "plays=#{plays}"
turned_pro = bio.at('ul.general-info > li.last').text.split(':')[1].strip
#$log.debug "turned pro=#{turned_pro}"
metadata_li = bio.at('ul.player-metadata.floatleft').search('li')
birth_date = metadata_li[1].at('span').next.text.gsub(/\(.*\)/,'').strip
hometown = metadata_li[2].at('span').next.text.strip
height = metadata_li[3].at('span').next.text.strip
weight = metadata_li[4].at('span').next.text.strip
player = {
  :name => name,
  :country => country,
  :plays => plays,
  :turned_pro => turned_pro,
  :birth_date => Date.parse(birth_date),
  :hometown => hometown,
  :height => height,
  :weight => weight,
}
$log.debug player
FileUtils.mkdir_p(JSON_OUTDIR) unless Dir.exist?(JSON_OUTDIR)
outfile_full=File.join(JSON_OUTDIR,"player_#{player[:name].split.join}_#{id}.json")
File.write(outfile_full, JSON.pretty_generate(player))
$log.info {"converted successful #{infile} to #{outfile_full}"}

$log.info File.basename(__FILE__)+' end'
