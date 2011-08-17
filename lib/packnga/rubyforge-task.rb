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
  class RubyforgeTask
    include Rake::DSL
    attr_writer :base_dir
    def initialize(spec)
      @spec = spec
      @base_dir = nil
      yield(self)
      set_default_values
      define_tasks
    end

    def html_base_dir
      @base_dir + "html"
    end

    def html_reference_dir
      html_base_dir + @spec.name
    end

    def set_default_values
      @base_dir ||= Pathname.new("doc")
    end

    def define_tasks
      define_reference_task
      define_html_task
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

    def rsync_to_rubyforge(spec, source, destination, options={})
      config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
      host = "#{config["username"]}@rubyforge.org"

      rsync_args = "-av --exclude '*.erb' --chmod=ug+w"
      rsync_args << " --delete" if options[:delete]
      remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_project}/"
      sh("rsync --dry-run -#{rsync_args} #{source} #{host}:#{remote_dir}#{destination}")
    end

  end
end
