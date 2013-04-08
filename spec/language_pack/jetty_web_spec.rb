require "spec_helper"

describe LanguagePack::JettyWeb, type: :with_temp_dir do

  attr_reader :tmpdir, :jetty_web_pack

  let(:appdir) { File.join(tmpdir, "app") }

  before do
    @jetty_web_pack = LanguagePack::JettyWeb.new(appdir)
    # TODO pass in Mock
    @jetty_web_pack.stub(:install_java)

    Dir.chdir(tmpdir) do
      Dir.mkdir("app")
      Dir.chdir(appdir) do
        Dir.mkdir("WEB-INF")
        jetty_web_pack.stub(:fetch_package) do |package|
          FileUtils.copy( File.expand_path("../../support/fake-jetty.tar.gz", __FILE__), package)
        end
        jetty_web_pack.stub(:install_database_drivers)
      end
    end
  end

  describe "detect" do

    it "should be used if web.xml present" do
      Dir.chdir(appdir) do
        FileUtils.touch "WEB-INF/web.xml"
        LanguagePack::JettyWeb.use?.should == true
      end
    end

    it "should be used if web.xml is present in installed Jetty dir" do
      Dir.chdir(appdir) do
        FileUtils.mkdir_p("webapps/ROOT/WEB-INF")
        FileUtils.touch "webapps/ROOT/WEB-INF/web.xml"
        LanguagePack::JettyWeb.use?.should == true
      end
    end

    it "should not be used if no web.xml" do
      Dir.chdir(appdir) do
        LanguagePack::JettyWeb.use?.should == false
      end
    end
  end

  describe "compile" do

    before do
      FileUtils.touch "#{appdir}/WEB-INF/web.xml"
    end

    it "should download and unpack Jetty to root directory" do
      jetty_web_pack.compile
      File.exists?(File.join(appdir, "bin", "jetty.sh")).should == true
    end

    it "should remove specified Jetty files" do
      jetty_web_pack.compile
      File.exists?(File.join(appdir, "start.d/test-webapp.ini")).should == false
      Dir.chdir(File.join(appdir, "webapps")) do
        Dir.glob("*").should == ["ROOT"]
      end
    end

    it "should copy app to webapp ROOT" do
      jetty_web_pack.compile

      web_xml = File.join(appdir,"webapps","ROOT", "WEB-INF", "web.xml")
      File.exists?(web_xml).should == true
    end
  end

  describe "release" do
    it "should return the Jetty start script as default web process" do
      jetty_web_pack.release.should == {
          "addons" => [],
          "config_vars" => {},
          "default_process_types" => { "web" => "./bin/jetty.sh run" }
      }.to_yaml
    end
  end
end
