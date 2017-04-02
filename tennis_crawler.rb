require 'logger'
require 'mechanize'
require 'csv'
require './file_saver.rb'

def load_conf(file)
  mod = Module.new
  mod.module_eval File.read(file)
  mod
end

############## Initialize
conf = load_conf('crawler.conf')
CSV_OUTDIR = conf::CSV_OUT_DIR || 'file/csv'
HTML_OUTDIR = conf::HTML_OUT_DIR || 'file/html'
logdir = conf::LOG_DIR || 'log'
#$log = Logger.new("#{logdir}/#{File.basename(__FILE__)}.log",'daily')
$log = Logger.new(STDOUT)
$log.level = conf::LOG_LEVEL

$log.info File.basename(__FILE__)+' start'

agent = Mechanize.new
agent.user_agent_alias = conf::USER_AGENT_ALIAS || 'Windows IE 10'
agent.log = $log

def save_page(page,seq=nil)
  pre_seq="#{seq && "#{seq}_"}"
  filename = "#{HTML_OUTDIR}/#{pre_seq}#{page.filename}"
  saved_filename = page.save!("#{filename}")
  $log.info "Page #{page.uri} saved to #{saved_filename}"
end

def save_file(file)
  filename = "#{CSV_OUTDIR}/#{file.filename}"
  saved_filename = file.save!("#{filename}")
  $log.info "File #{file.uri} saved to #{saved_filename}"
end

############# **** page
$log.info "Getting **** page"
url = 'http://www.espn.com/tennis/player/results/_/id/1035/kei-nishikori'
page = agent.get(url)
save_page(page)
$log.debug page
$log.debug page.class
exit
############# login
$log.info "Start login"
form = login_page.forms[0]
form.j_username=username
form.j_password=password
top_page = form.submit
save_page(top_page,2)

############# login check
caution = top_page.search('p.caution-top')
if !caution.empty?
  $log.error "login error : #{caution.text.strip}"
  exit
end

############# member page
$log.info "Getting member page"
member_page = top_page.link_with(:href=>/member/).click
save_page(member_page,3)

############# call detail page
$log.info "Getting call detail page"
call_page = member_page.link_with(:href=>/calldetail/).click
save_page(call_page,4)
$log.info "Getting call detail list page"
call_list_page = call_page.forms[0].submit
save_page(call_list_page,5)

######### download call usage
$log.info "Downloading call usage"
form = call_list_page.forms[0]
csv = form.click_button(form.button_with(:name=>/lastmonth/))
save_file(csv)

######### data usage page
$log.info "Getting data usage page"
url = '/service/setup/hdd/viewdata/'
data_page = agent.get(url)
save_page(data_page,6)

######### download data usage(convert table to csv)
$log.info "Downloading data usage"
data_usage_page = data_page.form_with(:name=>'lteViewDataForm').submit
save_page(data_usage_page,7)

outfile="#{CSV_OUTDIR}/data_usage_#{Date.today.strftime('%Y%m%d')}.csv"
$log.info "converting table to csv"
table = data_usage_page.search('table.base2')
CSV.open(outfile,"w") do |csv|
  table.search('tr').each_with_index do |tr,i|
    row = tr.search('td').map do |td|
      td.text.strip.encode(data_usage_page.encoding)
    end
    csv << row
  end
end
$log.info "data usage saved to #{outfile}"

######### download bill
$log.info "Getting bill page"
url = '/customer/bill/'
bill_page = agent.get(url)
save_page(bill_page,8)

$log.info "Downloading bill"
#agent.log.level = Logger::DEBUG
form = bill_page.forms[0]
bill_detail = form.click_button(form.buttons[-1])
save_page(bill_detail,9)

$log.info "converting bill table to csv"
tables = bill_detail.search('table.base2')
ym = tables[0].search('tr').search('td.data2-c').text.scan(/[0-9]+/).join
outfile="#{CSV_OUTDIR}/bill_#{ym}.csv"
CSV.open(outfile,"w") do |csv|
  tables.each do |table|
    table.search('tr').each_with_index do |tr,i|
      row = tr.search('td').map do |td|
        td.text.strip.encode(data_usage_page.encoding,:invalid=>:replace,:undef=>:replace,:replace=>'')
      end
      csv << row
    end
  end
end
$log.info "bill saved to #{outfile}"
$log.info File.basename(__FILE__)+' end'

