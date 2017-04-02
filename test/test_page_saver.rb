class TestPageSaver
end
if __FILE__ == $0
  log=Logger.new(STDOUT)
  agent = Mechanize.new
  page = agent.get('http://www.google.com/')
  saver = PageSaver.new
  log.info "TestCase01:no args"
  saver.save(page)
  log.info "TestCase02-1:set directory when init"
  saver = PageSaver.new('file/html/test')
  saver.save(page)
end
