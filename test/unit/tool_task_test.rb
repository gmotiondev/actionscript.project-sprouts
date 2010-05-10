require File.dirname(__FILE__) + '/test_helper'

require 'test/fixtures/tool/mxmlc_task'

class ToolTaskTest < Test::Unit::TestCase
  include SproutTestCase

  context "a new tool task" do

    setup do
      @tool = FakeToolTask.new
    end

    # TODO: Test each parameter type:

    should "accept boolean param" do
      @tool.boolean_param = true
      assert @tool.boolean_param
      assert_equal "-boolean-param=true", @tool.to_shell
    end

    should "accept a string param" do
      @tool.string_param = "string1"
      assert_equal "string1", @tool.string_param
      assert_equal "-string-param=string1", @tool.to_shell
    end

    should "accept strings param" do
      @tool.strings_param << 'string1'
      @tool.strings_param << 'string2'

      assert_equal ['string1', 'string2'], @tool.strings_param
      assert_equal "-strings-param+=string1 -strings-param+=string2", @tool.to_shell
    end

    should "accept number param" do
      @tool.number_param = 1234
      assert_equal 1234, @tool.number_param
    end

    should "accept parameter alias" do
      @tool.strings_param << "a"
      @tool.sp << "b"

      assert_equal ["a", "b"], @tool.sp

    end

    should "raise UsageError with unknown type" do

      assert_raises Sprout::Errors::UsageError do
        class BrokenTool
          include Sprout::Tool::Task
          add_param :broken_param, :unknown_type
        end

        tool = BrokenTool.new
      end
    end

    should "define a new method" do

      class WorkingTool
        include Sprout::Tool::Task
        add_param :custom_name, :string
      end

      tool1 = WorkingTool.new
      tool1.custom_name = "Foo Bar"
      assert_equal "Foo Bar", tool1.custom_name

      tool2 = WorkingTool.new
      tool2.custom_name = "Bar Baz"
      assert_equal "Bar Baz", tool2.custom_name

    end

    context "with a custom param (defined below)" do
      should "attempt to instantiate by adding _param to the end" do
        assert_not_nil Sprout::Tool::ParameterFactory.create :custom
      end
      should "attempt to instantiate an unknown type before failing" do
        assert_not_nil Sprout::Tool::ParameterFactory.create :custom_param
      end
    end

    # TODO: Ensure that file, files, path and paths
    # validate the existence of the references.

    # TODO: Ensure that a helpful error message is thrown
    # when assignment operator is used on collection params
  end

  context "a new mxmlc task" do

    setup do
      @tool = Sprout::MXMLCTask.new
      @mxmlc_executable = File.join(fixtures, 'tool', 'flex3sdk_gem', 'mxmlc')
    end

    should "accept input" do
      @tool.input = "test/fixtures/tool/src/Main.as"
      assert_equal "test/fixtures/tool/src/Main.as", @tool.input
      assert_equal "test/fixtures/tool/src/Main.as", @tool.to_shell
    end

    should "accept default gem name" do
      assert_equal 'sprout-flex3sdk', @tool.gem_name
    end

    should "override default gem name" do
      @tool.gem_name = 'sprout-flex4sdk'
      assert_equal 'sprout-flex4sdk', @tool.gem_name
    end

    should "accept default gem version" do
      assert_equal '>= 1.0.pre', @tool.gem_version
    end

    should "override default gem version" do
      @tool.gem_version = '1.1.pre'
      assert_equal '1.1.pre', @tool.gem_version
    end

    should "accept default gem executable" do
      assert_equal :mxmlc, @tool.executable
    end

    should "override default gem executable" do
      @tool.executable = :compc
      assert_equal :compc, @tool.executable
    end

    should "accept configuratin as a file task" do
      mxmlc 'bin/SomeFile.swf' do |t|
        t.source_path << 'test/fixtures/tool/src'
        t.input = 'test/fixtures/tool/src/Main.as'
        @tool = t # Hold onto the MXMLCTask reference...
      end
      assert_equal "-source-path+=test/fixtures/tool/src test/fixtures/tool/src/Main.as", @tool.to_shell
    end

    should "to_shell input" do
      @tool.debug = true
      @tool.source_path << "test/fixtures/tool/src"
      assert_equal "-debug -source-path+=test/fixtures/tool/src", @tool.to_shell
    end

    should "execute the registered executable" do
      # Configure stub tool:
      @tool.input = 'test/fixtures/tool/src/Main.as'
      @tool.source_path << 'test/fixtures/tool/src'
      @tool.debug = true
      Sprout.expects(:load_executable).with(:mxmlc, 'sprout-flex3sdk', '>= 1.0.pre').returns @mxmlc_executable

      # Ensure the exe file mode is NOT valid:
      File.chmod 0644, @mxmlc_executable
      first = File.stat(@mxmlc_executable).mode

      # Execute the stub tool:
      @tool.execute

      # Ensure the file mode was updated:
      assert "non-executable file mode should be updated by execute", first != File.stat(@mxmlc_executable).mode
    end

  end
end

class CustomParam < Sprout::Tool::Param; end

class FakeToolTask
  include Sprout::Tool::Task

  add_param :boolean_param, :boolean
  add_param :file_param,    :file
  add_param :files_param,   :files
  add_param :number_param,  :number
  add_param :path_param,    :path
  add_param :paths_param,   :paths
  add_param :string_param,  :string
  add_param :strings_param, :strings 
  add_param :symbols_param, :symbols
  add_param :urls_param,    :urls

  add_param_alias :sp, :strings_param
end

