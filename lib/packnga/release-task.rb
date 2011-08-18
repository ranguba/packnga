# -*- coding: utf-8 -*-
#
# Copyright (C) 2011  yoshihara haruka <yoshihara@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "rubyforge"

module Packnga
  class ReleaseTask
    # This class creates release tasks.
    #   Release task defines tasks to tag, test-install gem.
    #   It also define tasks to upload rubyforge whether option.
    #
    # @since 0.9.0
    include Rake::DSL
    attr_writer :index_html_dir
    attr_writer :base_dir, :upload_rubyforge
    # Defines task for preparing to release.
    # @param [Jeweler::Task] spec created by Jeweler::Task.new.
    def initialize(spec)
      @spec = spec
      @index_html_dir = nil
      @rubyforge = nil
      yield(self)
      set_default_values
      define_tasks
    end

    private
    def html_base_dir
      @base_dir + "html"
    end

    def html_reference_dir
      html_base_dir + @spec.name
    end

    def set_default_values
      @index_html_dir ||= "doc/html"
      @base_dir ||= Pathname.new("doc")
    end

    def define_tasks
      namespace :release do
        define_info_task
        define_tag_task
        define_rubyforge_tasks
      end
    end

    def define_info_task
      namespace :info do
        desc "update version in index HTML."
        task :update do
          old_version = ENV["OLD_VERSION"]
          old_release_date = ENV["OLD_RELEASE_DATE"]
          new_release_date = ENV["RELEASE_DATE"] || Time.now.strftime("%Y-%m-%d")
          new_version = ENV["VERSION"]

          empty_options = []
          empty_options << "OLD_VERSION" if old_version.nil?
          empty_options << "OLD_RELEASE_DATE" if old_release_date.nil?

          unless empty_options.empty?
            raise ArgumentError, "Specify option(s) of #{empty_options.join(", ")}."
          end
          @index_html_dir = Pathname(@index_html_dir)
          indexes = [@index_html_dir + "index.html", @index_html_dir + "index.html.ja"]
          indexes.each do |index|
            content = replaced_content = File.read(index)
            [[old_version, new_version],
             [old_release_date, new_release_date]].each do |old, new|
              replaced_content = replaced_content.gsub(/#{Regexp.escape(old)}/, new)
              if /\./ =~ old
                old_underscore = old.gsub(/\./, '-')
                new_underscore = new.gsub(/\./, '-')
                replaced_content =
                  replaced_content.gsub(/#{Regexp.escape(old_underscore)}/,
                                        new_underscore)
              end
            end

            next if replaced_content == content
            File.open(index, "w") do |output|
              output.print(replaced_content)
            end
          end
        end
      end
    end

    def define_tag_task
      desc "Tag the current revision."
      task :tag do
        version = @spec.version
        sh("git tag -a #{version} -m 'release #{version}!!!'")
      end
    end

    def define_rubyforge_tasks
      return if @spec.rubyforge_project.nil?
      @rubyforge = RubyForge.new
      @rubyforge.configure
      define_reference_task
      define_html_task
      define_publish_task
      define_upload_tasks
    end

    def define_reference_task
      namespace :reference do
        desc "Upload document to rubyforge."
        task :publish => [:generate, "reference:publication:prepare"] do
          rsync_to_rubyforge(@spec, "#{html_reference_dir}/", @spec.name)
        end
      end
    end

    def define_html_task
      namespace :html do
        desc "Publish HTML to Web site."
        task :publish do
          rsync_to_rubyforge(@spec, "#{html_base_dir}/", "")
        end
      end
    end

    def define_publish_task
      desc "Upload document and HTML to rubyforge."
      task :publish => ["html:publish", "reference:publish"]
    end

    def define_upload_tasks
      namespace :release do
        namespace :rubyforge do
          desc "Upload tar.gz to RubyForge."
          task :upload, "password"
          task :upload => "package" do |t, args|
            @rubyforge.userconfig["password"] =
              args[:password] || ENV["password"]
            @rubyforge.add_release(@spec.rubyforge_project,
                 @spec.name,
                 @spec.version.to_s,
                 "pkg/#{@spec.name}-#{@spec.version}.tar.gz")
          end
        end
        desc "Release to RubyForge."
        task :rubyforge, "password"
        task :rubyforge => "release:rubyforge:upload"
      end
    end

    def rsync_to_rubyforge(spec, source, destination, options={})

      config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
      host = "#{@rubyforge.userconfig["username"]}@rubyforge.org"

      rsync_args = "-av --dry-run --exclude '*.erb' --chmod=ug+w"
      rsync_args << " --delete" if options[:delete]
      remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_project}/"
      sh("rsync #{rsync_args} #{source} #{host}:#{remote_dir}#{destination}")
    end
  end
end
