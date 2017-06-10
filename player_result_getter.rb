require 'logger'
require 'mechanize'
require './page_saver.rb'

class PlayerResultGetter
  attr_accessor :log,:agent,:id,:year,:page_saver
  def initialize(id,year,log:Logger.new(STDOUT),agent:Mechanize.new
                 ,page_saver:PageSaver.new)
    super()
    @log = log
    @agent = agent
    @id = id
    @year = year
    @page_saver = page_saver
  end
  def get_page
    @log.debug {"begin get_page id=#{@id},year=#{@year}"
    page = @agent.get("http://www.espn.com/tennis/player/results/_/id/#{@id}/year/#{@year}")
    @page_saver.save(page, :filename=>"player_result_#{@id}_#{@year}.html")
  end
end
