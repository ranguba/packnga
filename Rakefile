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
require 'erb'
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

reference_base_dir = Pathname.new("doc/reference")
doc_en_dir = reference_base_dir + "en"
html_base_dir = Pathname.new("doc/html")
html_reference_dir = html_base_dir + spec.name

Packnga::DocumentTask.new(spec) do |task|
end

Packnga::ReferenceTask.new(spec) do |task|
end

def rake(*arguments)
  ruby($0, *arguments)
end

namespace :reference do
  translate_languages = [:ja]
  supported_languages = [:en, *translate_languages]

  directory reference_base_dir.to_s
  CLOBBER.include(reference_base_dir.to_s)


  desc "Upload document to rubyforge."
  task :publish => [:generate, "reference:publication:prepare"] do
    rsync_to_rubyforge(spec, "#{html_reference_dir}/", spec.name)
  end
end

namespace :html do
  desc "Publish HTML to Web site."
  task :publish do
    rsync_to_rubyforge(spec, "#{html_base_dir}/", "")
  end
end

desc "Upload document and HTML to rubyforge."
task :publish => ["html:publish", "reference:publish"]

desc "Tag the current revision."
task :tag do
  sh("git tag -a #{version} -m 'release #{version}!!!'")
end

namespace :release do
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

      indexes = ["doc/html/index.html", "doc/html/index.html.ja"]
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

  namespace :rubyforge do
    desc "Upload tar.gz to RubyForge."
    task :upload => "package" do
      ruby("-S", "rubyforge",
           "add_release",
           spec.rubyforge_project,
           spec.name,
           spec.version.to_s,
           "pkg/#{spec.name}-#{spec.version}.tar.gz")
    end
  end

  desc "Release to RubyForge."
  task :rubyforge => "release:rubyforge:upload"
end

namespace :test do
  task :install do
    gemspec_helper = Rake.application.jeweler.gemspec_helper
    ruby("-S gem install --user-install #{gemspec_helper.gem_path}")

    gem_spec = Gem.source_index.find_name("rroonga").last
    installed_path = gem_spec.full_gem_path
    ENV["NO_MAKE"] = "yes"
    ruby("-rubygems", "#{installed_path}/test/run-test.rb")
  end
end
