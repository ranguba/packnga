# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2011  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2011  Kouhei Sutou <kou@clear-code.com>
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

require 'English'

require 'pathname'
require 'rubygems'
require 'rubygems/package_task'
require "rake/clean"
require 'jeweler'

base_dir = File.join(File.dirname(__FILE__))

packnga_lib_dir = File.join(base_dir, 'lib')
$LOAD_PATH.unshift(packnga_lib_dir)
ENV["RUBYLIB"] = "#{packnga_lib_dir}:#{ENV['RUBYLIB']}"

require "packnga"

def guess_version
  Packnga::VERSION.dup
end

def cleanup_white_space(entry)
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

ENV["VERSION"] ||= guess_version
version = ENV["VERSION"].dup
spec = nil
Jeweler::Tasks.new do |_spec|
  spec = _spec
  spec.name = "packnga"
  spec.version = version
  spec.rubyforge_project = "groonga"
  spec.homepage = "http://groonga.rubyforge.org/"
  spec.authors = ["Haruka Yoshihara", "Kouhei Sutou"]
  spec.email = ["yoshihara@clear-code.com", "kou@clear-code.com"]
  entries = File.read("README.textile").split(/^h2\.\s(.*)$/)
  description = cleanup_white_space(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "LGPLv2"
  spec.files = FileList["lib/**/*.rb",
                        "Rakefile",
                        "README.textile",
                        "Gemfile",
                        "doc/text/**"]
  spec.test_files = FileList["test/**/*.rb"]
end

Rake::Task["release"].prerequisites.clear
Jeweler::RubygemsDotOrgTasks.new do
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_tar_gz = true
end

Packnga::DocumentTask.new(spec) do |task|
end

Packnga::ReleaseTask.new(spec) do |task|
  task.index_html_dir = "../rroonga/doc/html"
  task.changes = File.read("doc/text/news.textile").split(/^h2\.\s(.*)$/)[2]
end
