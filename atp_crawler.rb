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

$agent = Mechanize.new
$agent.user_agent_alias = conf::USER_AGENT_ALIAS
$agent.log = $log

html_saver = PageSaver.new(:outdir=>HTML_OUTDIR,:log=>$log)

def get_page(url)
  begin
    return $agent.get(url)
    return page
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
############# player list page
$log.info "Getting players page"
url = "http://www.atpworldtour.com/en/content/ajax/fedex-performance-full-table/Roll/All/All"
list_page = get_page(url)
html_saver.save(list_page, :filename=>"atp_win_loss_index.html")

############# player page
rows = list_page.search('#winLossTableContent > tr')
rows.each do |r|
  player = r.at('td.player-cell > a')
  name = player.text.strip
  url = player.attr('href')
  $log.info "Getting #{name}"
  player_page = get_page(url)
  html_saver.save(player_page, :filename=>"atp_player_#{name.split.join}.html")
  ############# ranking history
  url = player_page.search('#profileTabs > ul > li > a[data-ga-label="Rankings History"]').attr("href")
  $log.info "Getting #{name}'s Ranking History"
  ranking_history_page = get_page(url)
  html_saver.save(ranking_history_page, :filename=>"atp_player_ranking_history_#{name.split.join}.html")
end

$log.info {"#{File.basename(__FILE__)} normal end"}
