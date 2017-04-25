require 'test/unit'
require './page_saver.rb'

class TestPageSaver < Test::Unit::TestCase
  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @agent = Mechanize.new
#    @agent.log = @log
    @page = @agent.get('http://www.google.com/')
  end
  def test_save_default
    saver = PageSaver.new
    saver.save(@page)
    file_full_name="./#{@page.filename}"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    # assert html
    assert_equal File.open(file_full_name,'r').readlines[0].strip,"<!doctype html>"
    File.delete(file_full_name)
  end
  # test_outdir
  def test_save_outdir
    saver = PageSaver.new(:outdir=>'./file/html')
    saver.save(@page)
    file_full_name="./file/html/#{@page.filename}"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    assert_equal File.open(file_full_name,'r').readlines[0].strip,"<!doctype html>"
    File.delete(file_full_name)
  end
  # test_logger
  def test_save_logger
    log_full_name='log/test.log'
    saver = PageSaver.new(:log=>Logger.new(log_full_name))
    saver.save(@page)
    file_full_name="./#{@page.filename}"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    assert_equal File.open(file_full_name,'r').readlines[0].strip,"<!doctype html>"
    assert FileTest.exists?(log_full_name)
    File.delete(file_full_name)
    File.delete(log_full_name)
  end
  # test_raw
  def test_save_raw
    saver = PageSaver.new(:mode=>PageSaver::Mode::RAW)
    saver.save(@page)
    file_full_name="./#{@page.filename}"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    # assert raw
    assert (File.open(file_full_name,'r').readlines[0].strip.size > "<!doctype html>".size)
    File.delete(file_full_name)
  end
  # test_filename
  def test_save_filename
    saver = PageSaver.new
    saver.save(@page,:filename=>'test.html')
    file_full_name="./test.html"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    File.delete(file_full_name)
  end
  # test_filename_prefix
  def test_save_filename_prefix
    saver = PageSaver.new
    saver.save(@page,:filename_prefix=>'pref')
    file_full_name="./pref_#{@page.filename}"
    assert FileTest.exists?(file_full_name),"file #{file_full_name} not exists"
    assert_equal saver.saved_filename ,file_full_name
    File.delete(file_full_name)
  end
  def test_save_documnt_is_not_pretty
    url = 'http://www.espn.com/tennis/player/results/_/id/1035/kei-nishikori'
    @page = @agent.get(url)
    saver = PageSaver.new
    saver.save(@page)
    assert !saver.saved_pretty?
    File.delete(file_full_name)
  end
 end
