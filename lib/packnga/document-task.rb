# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2012  Haruka Yoshihara <yoshihara@clear-code.com>
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

require "pathname"
require "packnga/yard-task"
require "packnga/reference-task"

module Packnga
  # This class creates tasks for document.
  # They generate YARD document or references.
  #
  # @since 0.9.0
  class DocumentTask
    include Rake::DSL
    # Defines tasks to generate YARD documentation
    # and to translate references.
    # @param [Gem::Specification] spec specification for your package
    def initialize(spec)
      @spec = spec
      @yard_task = YARDTask.new(@spec)
      @reference_task = ReferenceTask.new(@spec)
      self.base_dir = "doc"
      yield(self) if block_given?
      define
    end

    # Sets base directory for documents. Default value is "doc".
    # @param [String] dir base direcory path
    def base_dir=(dir)
      dir = Pathname.new(dir)
      @yard_task.base_dir = dir
      @reference_task.base_dir = dir
    end

    # Sets original language which you wrote document.
    # Default value is "en" (as English).
    # Specified value is used to define language for translation.
    #
    # @see DocumentTask#translate_languages= #translate_language(s)= is used to specify languages for translation.
    # @param [String] language language you wrote document
    #
    # @since 0.9.6
    def original_language=(language)
      @reference_task.original_language = language
    end

    # Sets a translate language for document.
    # This method receives String as language code.
    #
    # @see http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    #   see "639-1" row in this page for lanugage codes.
    #
    # @example Specify Japanese.
    #   DocumentTask.new(spec) do |task|
    #     task.translate_language = "ja"
    #   end
    #
    # @!macro [new] document-task.translate_lanuguage.default_value
    #   If the language specified by {#original_language=} isn't
    #   English, its default value is one.
    #   Otherwise, it is not specified.
    # @!macro document-task.translate_lanuguage.default_value
    #
    # @see DocumentTask#translate_languages=
    #   #translate_languages= receives Array of String target languages codes.
    # @param [String] language target language code for translated document
    #
    # @since 0.9.7
    def translate_language=(language)
      self.translate_languages = [language]
    end

    # Sets translate languages for document.
    # This method receives Array of Strings as each language code.
    #
    # @see http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    #   see "639-1" row in this page for lanugage codes.
    #
    # @example Sets Japanese and English.
    #   DocumentTask.new(spec) do |task|
    #     task.translate_languages = ["ja", "en"]
    #   end
    #
    # @!macro document-task.translate_lanuguage.default_value
    #
    # @see DocumentTask#translate_language=
    #   #translate_language= receives String as target language code.
    # @param [Array<String>] languages
    #   target language codes for translated document
    #
    # @since 0.9.6
    def translate_languages=(languages)
      @reference_task.translate_languages = languages
    end

    # Runs block to task for YARD documentation.
    def yard
      yield(@yard_task)
    end

    # Runs block to tasks for references.
    def reference
      yield(@reference_task)
    end

    def htaccess
      @reference_task.htaccess
    end

    private
    def define
      set_default_values
      define_tasks
    end

    def set_default_values
      set_default_readme
      set_default_source_files
      set_default_text_files
    end

    def set_default_readme
      readme = @spec.files.find do |file|
        file.include?("README")
      end
      @yard_task.readme = readme
      @reference_task.readme = readme
    end

    def set_default_source_files
      source_files = @spec.files.find_all do |file|
        ruby_source_file?(file) or
          c_source_file?(file)
      end
      @yard_task.source_files = source_files
      @reference_task.source_files = source_files
    end

    def ruby_source_file?(file)
      file.start_with?("lib/") and file.end_with?(".rb")
    end

    def c_source_file?(file)
      file.start_with?("ext/") and file.end_with?(".c")
    end

    def set_default_text_files
      text_dir = @yard_task.base_dir + "text"
      text_files = @spec.files.find_all do |file|
        file.start_with?(text_dir.to_s)
      end
      @yard_task.text_files = text_files
      @reference_task.text_files = text_files
    end

    def define_tasks
      @yard_task.define
      @reference_task.define
    end
  end
end
