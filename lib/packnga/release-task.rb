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
require "digest"

module Packnga
  # This class creates release tasks.
  #
  # Release tasks tag current version and install gem for test.
  # It also define tasks to upload RubyForge whether option.
  #
  # @since 0.9.0
  class ReleaseTask
    include Rake::DSL

    # This attribute is path of HTML files written version and release date.
    # @param [String] value path of HTML files
    attr_writer :index_html_dir
    # This attribute is path of base directory of document.
    # @param [String] value path of base directory of document
    attr_writer :base_dir
    # This attribute is message when tagging in release.
    # @param [String] value message
    attr_writer :tag_message
    # This attribute is options for uploading RubyForge by rsync.
    # @param [Hash] value options for uploading.
    attr_writer :publish_options
    # This attribute is text for changes in new release
    # to post news to RubyForge.
    # @param [String] value text for changes.
    attr_writer :changes
    # Defines task for preparing to release.
    # Defined tasks update version and release-date in index files
    # and tag in git.
    # If you set rubyforge_project of Jeweler::Task.new with its given block,
    # it also define tasks to update RubyForge.
    # @param [Gem::Specification] spec created by Jeweler::Task.new.
    def initialize(spec)
      @spec = spec
      @index_html_dir = nil
      @rubyforge = nil
      @tag_messsage = nil
      @publish_options = nil
      @changes = nil
      @rubyforge_password = nil
      yield(self) if block_given?
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
      @tag_message ||= "release #{@spec.version}!!!"
      @publish_options ||= {}
      @changes ||= ""
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
        desc "Update version in index HTML."
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
        sh("git tag -a #{version} -m '#{@tag_message}'")
      end
    end

    def define_rubyforge_tasks
      return if @spec.rubyforge_project.nil?
      @rubyforge = RubyForge.new
      @uninitialized_password = Digest::SHA2.hexdigest(Time.now.to_f.to_s)
      @rubyforge.configure("password" => @uninitialized_password)
      define_reference_task
      define_html_task
      define_publish_task
      define_upload_tasks
      define_post_task
    end

    def define_reference_task
      namespace :reference do
        desc "Upload document to RubyForge."
        task :publish => "reference:publication:generate" do
          rsync_to_rubyforge(@spec, "#{html_reference_dir}/", @spec.name, @publish_options)
        end
      end
    end

    def define_html_task
      namespace :html do
        desc "Publish HTML to Web site."
        task :publish do
          rsync_to_rubyforge(@spec, "#{html_base_dir}/", "", @publish_options)
        end
      end
    end

    def define_publish_task
      desc "Upload document and HTML to RubyForge."
      task :publish => ["html:publish", "reference:publish"]
    end

    def define_upload_tasks
      namespace :rubyforge do
        desc "Upload tar.gz to RubyForge."
        task :upload => "package" do
          ensure_rubyforge_password
          if @rubyforge.autoconfig["group_ids"][@spec.rubyforge_project].nil?
            @rubyforge.scrape_config
            @rubyforge.save_autoconfig
          end
          if @rubyforge.autoconfig["package_ids"][@spec.name].nil?
            @rubyforge.create_package(@rubyforge.autoconfig["group_ids"][@spec.rubyforge_project], @spec.name)
          end
          @rubyforge.add_release(@spec.rubyforge_project,
                                 @spec.name,
                                 @spec.version.to_s,
                                 "pkg/#{@spec.name}-#{@spec.version}.tar.gz")
        end
      end
      desc "Release to RubyForge."
      task :rubyforge => "release:rubyforge:upload"
    end

    def define_post_task
      namespace :rubyforge do
        namespace :news do
          desc "Post news to RubyForge."
          task :post do
            ensure_rubyforge_password
            group_id =
              @rubyforge.autoconfig["group_ids"][@spec.rubyforge_project]
            subject =
              "#{@spec.name} version #{@spec.version} has been released!"
            body = @spec.description + "\nChanges:" + @changes

            if @rubyforge.post_news(group_id, subject, body).nil?
              raise "News couldn't be posted to RubyForge."
            end
          end
        end
      end
    end

    def rsync_to_rubyforge(spec, source, destination, options={})
      host = "#{@rubyforge.userconfig["username"]}@rubyforge.org"

      rsync_args = "-av --exclude '*.erb' --chmod=ug+w"
      rsync_args << " --group=#{spec.rubyforge_project}"
      rsync_args << " --delete" if options[:delete]
      rsync_args << " --dry-run" if options[:dryrun]
      remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_project}/"
      sh("rsync #{rsync_args} #{source} #{host}:#{remote_dir}#{destination}")
    end

    def ensure_rubyforge_password
      if @rubyforge.userconfig["password"] == @uninitialized_password
        print "password:"
        system("stty -echo")
        @rubyforge.userconfig["password"] = STDIN.gets.chomp
        system("stty echo")
        puts
      end
    end
  end
end
