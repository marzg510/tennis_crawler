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
$log.info "converting result table to json"

id=1035

Dir.glob("#{HTML_OUTDIR}/player_result_#{id}_*.html").each do |infile|
  doc = File.open(infile) {|f| Nokogiri::HTML(f) }
  #$log.debug {doc}

  player = doc.at('div#my-players-table').at('div.player-stats').text.split[0..1].join(' ')
  #$log.debug "player=#{player}"
  tour_head = doc.at('//h4[contains(text(),"TOURNAMENTS")]')
  #$log.info tour_head.text
  year = tour_head.text.split[0]
  ts_top = tour_head.parent.parent

  tour_details = ts_top.search('div.game-details')
  tournaments = []
  tour_details.reverse.each_with_index do |t,i|
  #  $log.debug {"t=#{t}"}
    # replace br to TAB
    p=t.at('p')
  #  $log.debug {"p=#{p}"}
    p.search('br').each do |br|
      br.replace('\t')
    end
    # search table
  #  $log.debug {"t.parent=#{t.parent}"}
  #  $log.debug {"t.parent.parent=#{t.parent.parent}"}
    table = t.parent.next_element
  #  $log.debug {"table=#{table}"}
    matches = []
    game_type = nil
    table.search('tr').each do |tr|
  #    $log.debug {"tr=#{tr}"}
      if tr.attribute('class').value == 'total' then
  #      $log.debug {"total row found"}
        game_type = tr.text.strip.gsub(/(\s)+/," ")
      elsif tr.attribute('class').value == 'colhead' then
      else
        tds = tr.search('td')
        round = tds[0].text.strip
        opponent = tds[1].text.strip.gsub(/(\s)+/," ")
        result = tds[2].text.strip
        scores = tds[3].text.split(',').map{|t| t.strip}
        match = {:round => round,
                 :opponent => opponent,
                 :result => result,
                 :scores => scores
                }
        matches << match
      end
    end
    tournament = {:detail_url=>p.at('a').attribute('href').text.strip,
                  :name=>p.at('a').text.strip,
                  :place=>p.text.split('\t')[0].strip.gsub(/(\s)+/," "),
                  :period=>p.text.split('\t')[1].strip,
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

  FileUtils.mkdir_p(JSON_OUTDIR) unless Dir.exist?(JSON_OUTDIR)
  outfile_full=File.join(JSON_OUTDIR,"#{player.split.join}_#{id}_#{year}.json")
  File.write(outfile_full, JSON.pretty_generate(player_result))
  $log.info {"converted successful #{infile} to #{outfile_full}"}
end

$log.info File.basename(__FILE__)+' end'
