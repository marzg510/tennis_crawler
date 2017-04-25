require 'logger'
require 'mechanize'
require 'json'
require './page_saver.rb'
require './config_loader.rb'

############## Initialize
conf = ConfigLoader.load('crawler.conf')
JSON_OUTDIR = conf::JSON_OUT_DIR || 'file/json'
HTML_OUTDIR = conf::HTML_OUT_DIR || 'file/html'
logdir = conf::LOG_DIR || 'log'
#$log = Logger.new("#{logdir}/#{File.basename(__FILE__)}.log",'daily')
$log = Logger.new(STDOUT)
$log.level = conf::LOG_LEVEL

$log.info File.basename(__FILE__)+' start'

agent = Mechanize.new
agent.user_agent_alias = conf::USER_AGENT_ALIAS || 'Windows IE 10'
agent.log = $log

html_saver = PageSaver.new(:outdir=>HTML_OUTDIR,:log=>$log)

############# **** page
$log.info "Getting **** page"
url = 'http://www.espn.com/tennis/player/results/_/id/1035/kei-nishikori'
page = agent.get(url)
html_saver.save(page)
#$log.debug page

$log.info "converting result table to json"
player = page.at('div#my-players-table').at('div.player-stats').text.split[0..1].join(' ')
$log.debug "player=#{player}"
tour_head = page.at('//h4[contains(text(),"TOURNAMENTS")]')
$log.info tour_head.text
year = tour_head.text.split[0]
ts_top = tour_head.parent.parent

tour_details = ts_top.search('div.game-details')
tournaments = []
tour_details.each_with_index do |t,i|
  # replace br to TAB
  p=t.at('p')
  p.search('br').each do |br|
    br.replace('\t')
  end
  # search table
  table = t.parent.next
  matches = []
  game_type = nil
  table.search('tr').each do |tr|
#    puts "tr=#{tr}"
    if tr.attribute('class').value == 'total' then
      game_type = tr.text
    elsif tr.attribute('class').value == 'colhead' then
    else
      tds = tr.search('td')
      round = tds[0].text
      opponent = tds[1].text
      result = tds[2].text
      scores = tds[3].text.split(',').map{|t| t.strip}
      match = {:round => round,
               :opponent => opponent,
               :result => result,
               :scores => scores
              }
      matches << match
    end
  end
  tournament = {:detail_url=>p.at('a').attribute('href').text,
                :name=>p.at('a').text,
                :place=>p.text.split('\t')[0],
                :period=>p.text.split('\t')[1],
                :game_type=>game_type,
                :matches=>matches,
                }
  tournaments << tournament
end

player_result = {
  :player => player,
  :year => year,
  :tournaments => tournaments,
}

#puts tournaments

File.write(File.join(JSON_OUTDIR,"#{player.split.join}_#{year}.json"),
           JSON.pretty_generate(player_result)
          )

$log.info File.basename(__FILE__)+' end'
