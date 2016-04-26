require 'rails_helper'
require 'fileutils'

describe ActiveAdmin::Application do

  let(:application) do
    ActiveAdmin::Application.new.tap do |app|
      # Manually override the load paths becuase RSpec messes these up
      app.load_paths = [File.expand_path('app/admin', Rails.root)]
    end
  end

  it "should have a default load path of ['app/admin']" do
    expect(application.load_paths).to eq [File.expand_path('app/admin', Rails.root)]
  end

  it "should remove app/admin from the autoload paths (Active Admin deals with loading)" do
    expect(ActiveSupport::Dependencies.autoload_paths).to_not include(File.join(Rails.root, "app/admin"))
  end

  it "should store the site's title" do
    expect(application.site_title).to eq ""
  end

  it "should set the site title" do
    application.site_title = "New Title"
    expect(application.site_title).to eq "New Title"
  end

  it "should store the site's title link" do
    expect(application.site_title_link).to eq ""
  end

  it "should set the site's title link" do
    application.site_title_link = "http://www.mygreatsite.com"
    expect(application.site_title_link).to eq "http://www.mygreatsite.com"
  end

  it "should store the site's title image" do
    expect(application.site_title_image).to eq ""
  end

  it "should set the site's title image" do
    application.site_title_image = "http://railscasts.com/assets/episodes/stills/284-active-admin.png?1316476106"
    expect(application.site_title_image).to eq "http://railscasts.com/assets/episodes/stills/284-active-admin.png?1316476106"
  end

  it "should store the site's favicon" do
    expect(application.favicon).to eq false
  end

  it "should return default localize format" do
    expect(application.localize_format).to eq :long
  end

  it "should set localize format" do
    application.localize_format = :default
    expect(application.localize_format).to eq :default
  end

  it "should set the site's favicon" do
    application.favicon = "/a/favicon.ico"
    expect(application.favicon).to eq "/a/favicon.ico"
  end

  it "should store meta tags" do
    expect(application.meta_tags).to eq({})
  end

  it "should set meta tags" do
    application.meta_tags = { author: "My Company" }
    expect(application.meta_tags).to eq(author: "My Company")
  end

  it "should contains robots meta tags by default" do
    result = application.meta_tags_for_logged_out_pages
    expect(result).to eq(robots: "noindex, nofollow")
  end

  it "should set meta tags for logged out pages" do
    value = { author: "My Company" }
    application.meta_tags_for_logged_out_pages = value
    expect(application.meta_tags_for_logged_out_pages).to eq value
  end

  it "should have a view factory" do
    expect(application.view_factory).to be_an_instance_of(ActiveAdmin::ViewFactory)
  end

  it "should allow comments by default" do
    expect(application.comments).to eq true
  end

  describe "authentication settings" do

    it "should have no default current_user_method" do
      expect(application.current_user_method).to eq false
    end

    it "should have no default authentication method" do
      expect(application.authentication_method).to eq false
    end

    it "should have a logout link path (Devise's default)" do
      expect(application.logout_link_path).to eq :destroy_admin_user_session_path
    end

    it "should have a logout link method (Devise's default)" do
      expect(application.logout_link_method).to eq :get
    end
  end

  describe "files in load path" do
    it "should load files in the first level directory" do
      expect(application.files).to include(File.expand_path("app/admin/dashboard.rb", Rails.root))
    end

    it "should load files from subdirectories" do
      FileUtils.mkdir_p(File.expand_path("app/admin/public", Rails.root))
      test_file = File.expand_path("app/admin/public/posts.rb", Rails.root)
      FileUtils.touch(test_file)
      expect(application.files).to include(test_file)
    end

    context "given a complex admin directory" do
      before(:each) do
        @tmpdir = Dir.mktmpdir
        @ordered_directory = [
          "#{@tmpdir}/app/admin/a.rb",
          "#{@tmpdir}/app/admin/b.rb",
          "#{@tmpdir}/app/admin/concerns/d.rb",
          "#{@tmpdir}/app/admin/concerns/e.rb",
          "#{@tmpdir}/app/admin/v.rb",
          "#{@tmpdir}/app/admin/w.rb",
          "#{@tmpdir}/app/admin/x.rb",
          "#{@tmpdir}/app/admin/y.rb"
        ]
        FileUtils.mkdir_p "#{@tmpdir}/app/admin/concerns"
        FileUtils.touch @ordered_directory
      end
      after(:each) { FileUtils.rm_rf @tmpdir }

      context "with a single entry in load_paths" do
        it "should return the files in alphabetical order" do
          application.load_paths = ["#{@tmpdir}/app/admin"]
          expect(application.files).to eq(@ordered_directory)
        end
      end

      context "with multiple entries in load_paths" do

        it "should return the files in alphabetical order, grouped by the order defined in load_paths" do
          file_group1 = @ordered_directory.select {|f| f.include? 'concerns'}
          file_group2 = @ordered_directory.reject {|f| f.include? 'concerns'}
          application.load_paths = ["#{@tmpdir}/app/admin/concerns", "#{@tmpdir}/app/admin"]
          expect(application.files).to eq(file_group1 + file_group2)
        end
      end
    end
  end

  describe "#namespace" do

    it "should yield a new namespace" do
      application.namespace :new_namespace do |ns|
        expect(ns.name).to eq :new_namespace
      end
    end

    it "should return an instantiated namespace" do
      admin = application.namespace :admin
      expect(admin).to eq application.namespaces[:admin]
    end

    it "should yield an existing namespace" do
      expect {
        application.namespace :admin do |ns|
          expect(ns).to eq application.namespaces[:admin]
          raise "found"
        end
      }.to raise_error("found")
    end

    it "should not pollute the global app" do
      expect(application.namespaces).to be_empty
      application.namespace(:brand_new_ns)
      expect(application.namespaces.names).to eq [:brand_new_ns]
      expect(ActiveAdmin.application.namespaces.names).to eq [:admin]
    end
  end

  describe "#register_page" do
    it "finds or create the namespace and register the page to it" do
      namespace = double
      expect(application).to receive(:namespace).with("public").and_return namespace
      expect(namespace).to receive(:register_page).with("My Page", {namespace: "public"})
      application.register_page("My Page", namespace: "public")
    end
  end

end
