require 'mechanize'
require 'cgi'
require 'logger'

class PageSaver
  attr_accessor :log,:outdir,:mode
  attr_reader :saved_filename
  def saved_pretty?
    !!@saved_pretty
  end
  module Mode
    RAW = 1
    HTML = 2
  end
  def initialize(outdir:"." ,log:Logger.new(STDOUT) ,mode:Mode::HTML)
    @outdir = outdir
    @log = log
    @mode = mode
  end
  def save(page ,filename:nil,filename_prefix:nil)
    prefix="#{filename_prefix && "#{filename_prefix}_"}"
    filename = filename || "#{prefix}#{page.filename}"
    file_full_name = File.join(outdir,filename)
    FileUtils.mkdir_p(outdir) unless Dir.exist?(outdir)
    case @mode
    when Mode::RAW then
      @saved_filename = page.save!(file_full_name)
    when Mode::HTML then
      content = page.content.toutf8
      begin
        doc = CGI.pretty(content)
        @saved_pretty = true
      rescue => e
        @log.warn "Exception <#{e}> occured, the document has saved in not-pretty html."
        doc = content
        @saved_pretty = false
      end
      open(file_full_name,'w').write(doc)
      @saved_filename = file_full_name
    else
      raise "mode is invalid:#{@mode}"
    end
    @log.info "#{page.uri} saved to #{@saved_filename}"
  end
end


