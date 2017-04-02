require 'mechanize'
require 'cgi'
require 'logger'

class PageSaver
  attr_accessor :log,:outdir,:mode
  attr_reader :saved_filename
  module Mode
    RAW = 1
    HTML = 2
  end
  def initialize(outdir=".",log=Logger.new(STDOUT),mode=Mode::HTML)
    @outdir = outdir
    @log = log
    @mode = mode
  end
  def save(page,filename=nil,filename_prefix=nil)
    prefix="#{filename_prefix && "#{filename_prefix}_"}"
    filename = filename || "#{prefix}#{page.filename}"
    file_full_name = "#{outdir}/#{filename}"
    case @mode
    when Mode::RAW then
      @saved_filename = page.save!("#{file_full_name}")
    when Mode::HTML then
      doc = CGI.pretty(page.content.toutf8)
      open(filename,'w').write(doc)
      @saved_filename = file_full_name
    end
    @log.info "#{page.uri} saved to #{@saved_filename}"
  end
end


