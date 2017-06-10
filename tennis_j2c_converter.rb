require 'logger'
require 'json'
require 'csv'
require './page_saver.rb'
require './config_loader.rb'

############## Initialize
conf = ConfigLoader.load('tennis.conf')
JSON_OUTDIR = conf::JSON_OUT_DIR || 'file/json'
CSV_OUTDIR = conf::CSV_OUT_DIR || 'file/csv'
logdir = conf::LOG_DIR || 'log'
#$log = Logger.new("#{logdir}/#{File.basename(__FILE__)}.log",'daily')
$log = Logger.new(STDOUT)
#$log.level = conf::LOG_LEVEL
$log.level = Logger::DEBUG

$log.info File.basename(__FILE__)+' start'

############# page convert html to json
$log.info "converting result table to json"

id=1035

FileUtils.mkdir_p(CSV_OUTDIR) unless Dir.exist?(CSV_OUTDIR)
outfile_full="#{CSV_OUTDIR}/player_result_#{id}.csv"
CSV.open(outfile_full,"w") do |csv|
  csv << ["year","tournament_seq","round","result"]
  Dir.glob("#{JSON_OUTDIR}/*_#{id}_*.json").each do |infile|
    result = File.open(infile) {|f| JSON.load(f) }
#    $log.debug {result}
#    $log.debug {"#{result["year"]}"}
#    $log.debug {"#{result["tournaments"]}"}
    result["tournaments"].each_with_index do |t,i|
#      $log.debug {"#{result['year']},#{i+1},#{t['name']}"}
      t["matches"].select {|m| m['result'] !~ /(-|BYE)/ }.each do |m|
        $log.debug {"#{result['year']},#{i+1},#{m['round']},#{m['result']}"}
        csv << [result['year'],i+1,m['round'],m['result']]
      end
    end
    $log.info {"converted successful #{infile} to #{outfile_full}"}
#    break
  end
end

$log.info File.basename(__FILE__)+' end'
