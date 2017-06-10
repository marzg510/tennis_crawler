require 'logger'
require 'mechanize'
require './page_saver.rb'
require './config_loader.rb'

############## Initialize
conf = ConfigLoader.load('tennis.conf')
JSON_OUTDIR = conf::JSON_OUT_DIR
HTML_OUTDIR = conf::HTML_OUT_DIR
logdir = conf::LOG_DIR
#$log = Logger.new("#{logdir}/#{File.basename(__FILE__)}.log",'daily')
$log = Logger.new(STDOUT)
$log.level = conf::LOG_LEVEL

$log.info {"#{File.basename(__FILE__)} start"}

agent = Mechanize.new
agent.user_agent_alias = conf::USER_AGENT_ALIAS
agent.log = $log

html_saver = PageSaver.new(:outdir=>HTML_OUTDIR,:log=>$log)

############# result page
$log.info "Getting result pages"
id = 1035
#id = 55555
[*(2000..Date.today().year)].each do |year|
#  year = 2017
  #year = 1900
  url = "http://www.espn.com/tennis/player/results/_/id/#{id}/year/#{year}"
  begin
    page = agent.get(url)
    next if page.body.include?("No tournaments played.")
    html_saver.save(page, :filename=>"player_result_#{id}_#{year}.html")
  rescue Timeout::Error => e
    $log.warn {e}
    $log.warn {"timeout occured,retry"}
    retry
  rescue => e
    $log.fatal {"Exception Occured at get url !"}
    $log.fatal {e}
    $log.info {"#{File.basename(__FILE__)} abnormal end"}
    exit 9
  end
end
$log.info {"#{File.basename(__FILE__)} normal end"}
