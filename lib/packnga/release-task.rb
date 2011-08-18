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

module Packnga
  class ReleaseTask
    include Rake::DSL
    attr_writer :index_html_dir
    def initialize(spec)
      @spec = spec
      @index_html_dir = nil
      yield(self)
      set_default_values
      define_tasks
    end

    private
    def set_default_values
      @index_html_dir ||= "doc/html"
    end

    def define_tasks
      namespace :release do
        define_info_task
        define_tag_task
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
  end
end
