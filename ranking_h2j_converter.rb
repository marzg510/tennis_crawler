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

############# ranking convert html to json
$log.info "converting ranking history page to json"

id="RogerFederer"

infile = "#{HTML_OUTDIR}/atp_player_ranking_history_#{id}.html"
doc = File.open(infile) {|f| Nokogiri::HTML(f) }

rankings = {
  :id => id,
  :ranking_history => []
}
rows = doc.search('#playerRankHistoryContainer > table > tbody > tr')
rows.each do |r|
  rankings[:ranking_history] << {
    :date => Date.parse(r.at('td:nth-child(1)').text.strip),
    :singles => r.at('td:nth-child(2)').text.strip,
    :doubles => r.at('td:nth-child(3)').text.strip,
  }
end
#$log.info JSON.pretty_generate(rankings)
FileUtils.mkdir_p(JSON_OUTDIR) unless Dir.exist?(JSON_OUTDIR)
outfile_full=File.join(JSON_OUTDIR,"rankings_#{id}.json")
File.write(outfile_full, JSON.pretty_generate(rankings))
$log.info {"converted successful #{infile} to #{outfile_full}"}

$log.info File.basename(__FILE__)+' end'
