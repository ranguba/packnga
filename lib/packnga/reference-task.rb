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
  class ReferenceTask
    include Rake::DSL
    attr_writer :base_dir
    def initialize(spec)
      @spec = spec
      @base_dir = nil
      @translate_languages = nil
      @html_files = nil
      @po_dir = nil
      @po_file = nil
      @pot_file = nil
      yield(self)
      set_default_values
      define_tasks
    end

    def set_default_values
      @base_dir ||= Pathname.new("doc")
      @translate_languages ||= [:ja]
      @html_files = FileList[(doc_en_dir + "**/*.html").to_s].to_a

      @po_dir = "doc/po"
      @pot_file = "#{@po_dir}/#{@spec.name}.pot"

    end

    def reference_base_dir
      @base_dir + "reference"
    end

    def doc_en_dir
      @base_dir + "reference/en"
    end

    def define_tasks
      namespace :reference do
        define_pot_tasks
        define_po_tasks
        define_translate_task
      end
    end

    def define_pot_tasks
      namespace :pot do
        directory @po_dir
        file @pot_file => [@po_dir, *@html_files] do |t|
          sh("xml2po", "--keep-entities", "--output", t.name, *@html_files)
        end

        desc "Generates pot file."
        task :generate => @pot_file do |t|
        end
      end
    end

    def define_po_tasks
      namespace :po do
        @translate_languages.each do |language|
          namespace language do
            @po_file = "#{@po_dir}/#{language}.po"

            if File.exist?(@po_file)
              file @po_file => @html_files do |t|
                sh("xml2po", "--keep-entities", "--update", t.name, *@html_files)
              end
            else
              file @po_file => @pot_file do |t|
                sh("msginit",
                   "--input=#{@pot_file}",
                   "--output=#{t.name}",
                   "--locale=#{language}")
              end
            end

            desc "Updates po file for #{language}."
            task :update => @po_file
          end
        end

        desc "Updates po files."
        task :update do
          ruby($0, "clobber")
          ruby($0, "yard")
          @translate_languages.each do |language|
            ruby($0, "reference:po:#{language}:update")
          end
        end
      end
    end

    def define_translate_task
      namespace :translate do

        @translate_languages.each do |language|
          @po_file = "#{@po_dir}/#{language}.po"
          translate_doc_dir = "#{reference_base_dir}/#{language}"
          desc "Translates documents to #{language}."
          task language => [@po_file, reference_base_dir, *@html_files] do
            doc_en_dir.find do |path|
              base_path = path.relative_path_from(doc_en_dir)
              translated_path = "#{translate_doc_dir}/#{base_path}"
              if path.directory?
                mkdir_p(translated_path)
                next
              end
              case path.extname
              when ".html"
                sh("xml2po --keep-entities " +
                   "--po-file #{@po_file} --language #{language} " +
                   "#{path} > #{translated_path}")
              else
                cp(path.to_s, translated_path, :preserve => true)
              end
            end
          end
        end
      end

      translate_task_names = @translate_languages.collect do |language|
        "reference:translate:#{language}"
      end
      desc "Translates references."
      task :translate => translate_task_names
    end
  end
end
