require 'test_helper'

module Haml
  # really should just be part of integration_test.rb , testing shit from the orchestration class
  class ExtractorTest < MiniTest::Unit::TestCase

    def setup
      @ex1 = Haml::I18n::Extractor.new(file_path("ex1.haml"))
    end

    test "it can process the haml and replace it with other text" do
      @ex1.run
    end

    test "it should be able to process filters with the haml_parser now..." do
      #@FIXME
      #raise 'implment me...check the finder#filters method and make sure you process the whole file at once so the parser gets it...'
    end

    test "with a type of overwrite or dump affecting haml writer" do
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :type => :overwrite)
      assert_equal h.haml_writer.overwrite?, true
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"))
      assert_equal h.haml_writer.overwrite?, false
    end

    test "with a interactive option which prompts the user-per line" do
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :interactive => true)
      assert_equal h.interactive?, true
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"))
      assert_equal h.interactive?, false
    end

    test "with a interactive option takes user input into consideration for haml" do
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :interactive => true)
      user_input = "D" # dump
      File.readlines(file_path("ex1.haml")).size.times do
        user_input << "n" # do not replace lines
      end
      with_highline(user_input) do
        h.run
      end
      # no changes were made cause user was all like 'uhhh, no thxk'
      assert_equal File.read(h.haml_writer.path), File.read(file_path("ex1.haml"))
    end

    test "with a interactive option takes user input N as next and stops processing file" do
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :interactive => true)
      user_input = "D" # dump
      File.readlines(file_path("ex1.haml")).size.times do
        user_input << "N" # just move on to next file
      end
      with_highline(user_input) do
        h.run
      end
      # no changes were made cause user was all like 'uhhh, move to next file'
      assert_equal File.read(h.haml_writer.path), File.read(file_path("ex1.haml"))
    end

    test "with a interactive option takes user input into consideration for yaml" do
      TestHelper.hax_shit
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :interactive => true)
      user_input = "D" # dump
      File.readlines(file_path("ex1.haml")).size.times do
        user_input << "n" # do not replace lines
      end
      with_highline(user_input) do
        h.run
      end
      # no changes were made cause user was all like 'uhhh, no thxk'
      assert_equal YAML.load(File.read(h.yaml_tool.yaml_file)), {}
    end

    test "with a interactive option user can tag a line for later review" do
      TestHelper.hax_shit
      if File.exist?(Haml::I18n::Extractor::TaggingTool::DB)
        assert_equal File.readlines(Haml::I18n::Extractor::TaggingTool::DB), []
      end
      h = Haml::I18n::Extractor.new(file_path("ex1.haml"), :interactive => true)
      user_input = "D" # dump
      File.readlines(file_path("ex1.haml")).size.times do
        user_input << "t" # tag the lines
      end
      with_highline(user_input) do
        h.run
      end
      assert (File.readlines(Haml::I18n::Extractor::TaggingTool::DB).size != 0), "tag lines get added to file"
    end


    test "can not initialize if the haml is not valid syntax" do
      begin
        Haml::I18n::Extractor.new(file_path("bad.haml"))
        assert false, "should not get here"
      rescue Haml::I18n::Extractor::InvalidSyntax
        assert true, "it should fail with invalid syntax"
      end
    end

    test "it writes the haml to an out file if valid haml output" do
      FileUtils.rm_rf(@ex1.haml_writer.path)
      assert_equal File.exists?(@ex1.haml_writer.path), false
      @ex1.run
      assert_equal File.exists?(@ex1.haml_writer.path), true
    end

    test "it writes the locale info to an out file when run" do
      TestHelper.hax_shit
      assert_equal File.exists?(@ex1.yaml_tool.yaml_file), false
      @ex1.run
      assert_equal File.exists?(@ex1.yaml_tool.yaml_file), true
      assert_equal YAML.load(File.read(@ex1.yaml_tool.yaml_file)), @ex1.yaml_tool.yaml_hash
    end

    test "sends a hash over of replacement info to its yaml tool when run" do
      @ex1 = Haml::I18n::Extractor.new(file_path("ex1.haml"))
      assert_equal @ex1.yaml_tool.locale_hash, nil
      @ex1.run
      assert @ex1.yaml_tool.locale_hash.is_a?(Hash), "its is hash of info about the files lines"
      assert_equal @ex1.yaml_tool.locale_hash.size, @ex1.haml_reader.lines.size
    end

    test "it fails before it writes to an out file if it is not valid" do
      begin
        @ex1 = Haml::I18n::Extractor.new(file_path("ex1.haml"))
        @ex1.stub(:assign_new_body, nil) do #nop
          @ex1.haml_writer.body = File.read(file_path("bad.haml"))
          @ex1.run
        end
        assert false, "should raise"
      rescue Haml::I18n::Extractor::InvalidSyntax
        assert true, "it should not allow invalid output to be written"
      end
    end
    
  end
end
