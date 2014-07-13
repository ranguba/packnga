# -*- coding: utf-8 -*-
#
# Copyright (C) 2012 Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013 Kouhei Sutou <kou@clear-code.com>
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

class DocumentTaskTest < Test::Unit::TestCase
  def teardown
    Rake::Task.clear
  end

  def test_base_directory_set
    spec = Gem::Specification.new("test")
    base_dir = Pathname("base_directory")
    document_task = Packnga::DocumentTask.new(spec) do |task|
      task.base_dir = base_dir.to_s
      task.reference do |reference|
        reference.translate_languages = ["ja"]
        reference.readme = "README.md"
      end
    end

    document_task.yard do |yard_task|
      assert_equal(base_dir, yard_task.base_dir)
    end

    document_task.reference do |reference_task|
      assert_equal(base_dir, reference_task.base_dir)
    end
  end

  class TranslateLanguagesTest < self
    def test_single
      translate_language = "ja"
      options = {:translate_language => translate_language}
      document_task = create_document_task(options)

      document_task.reference do |reference_task|
        assert_equal([translate_language], reference_task.translate_languages)
      end
    end

    def test_multi
      translate_languages = ["ja", "uk"]
      options = {:translate_languages => translate_languages}
      document_task = create_document_task(options)

      document_task.reference do |reference_task|
        assert_equal(translate_languages, reference_task.translate_languages)
      end
    end

    private
    def create_document_task(options)
      translate_languages = options[:translate_languages]
      translate_language = options[:translate_language]

      spec = Gem::Specification.new("test")
      Packnga::DocumentTask.new(spec) do |task|
        if translate_languages.nil?
          task.translate_language = translate_language
        else
          task.translate_languages = translate_languages
        end
        task.reference do |reference|
          reference.readme = "README.md"
        end
      end
    end
  end

  def test_original_language
    original_language = "original_language"
    spec = Gem::Specification.new("test")
    document_task = Packnga::DocumentTask.new(spec) do |task|
      task.original_language = original_language
      task.reference do |reference|
        reference.readme = "README.md"
      end
    end

    document_task.reference do |reference_task|
      assert_equal(original_language, reference_task.original_language)
    end
  end

  class ReadmeTest < self
    def setup
      @readme = "README.textile"
      spec = Gem::Specification.new("test") do |_spec|
        _spec.files = [@readme]
      end
      document_task = Packnga::DocumentTask.new(spec) do |task|
        task.translate_languages = ["ja"]
      end
      @yard_task = extract_yard_task(document_task)
      @reference_task = extract_reference_task(document_task)
    end

    def test_readme
      assert_equal(@readme, @yard_task.readme)
      assert_equal(@readme, @reference_task.readme)
    end

    def test_source_files
      assert_equal([], @yard_task.source_files)
      assert_equal([], @reference_task.source_files)
    end

    def test_text_files
      assert_equal([], @yard_task.text_files)
      assert_equal([], @reference_task.text_files)
    end
  end

  class SourceFilesTest < self
    def setup
      source_ruby_files = ["lib/packnga.rb", "lib/packnga/version.rb"]
      other_ruby_files = ["other1.rb", "ext/other2.rb"]

      source_c_files = ["ext/packnga.c", "ext/packnga/version.c"]
      other_c_files = ["other1.c", "lib/other2.c"]

      spec = Gem::Specification.new("test") do |_spec|
        _spec.files = [
          source_ruby_files,
          other_ruby_files,
          source_c_files,
          other_c_files,
        ]
      end
      document_task = Packnga::DocumentTask.new(spec) do |task|
        task.translate_languages = ["ja"]
      end
      @yard_task = extract_yard_task(document_task)
      @reference_task = extract_reference_task(document_task)

      @source_files = source_ruby_files + source_c_files
    end

    def test_readme
      assert_nil(@yard_task.readme)
      assert_nil(@reference_task.readme)
    end

    def test_source_files
      assert_equal(@source_files.sort, @yard_task.source_files.sort)
      assert_equal(@source_files.sort, @reference_task.source_files.sort)
    end

    def test_text_files
      assert_equal([], @yard_task.text_files)
      assert_equal([], @reference_task.text_files)
    end
  end

  class TextFilesTest < self
    def setup
      @source_text_files = ["doc/text/tutorial.textile", "doc/text/new.md"]
      other_text_files = ["other1.textile", "doc/other2.md", "Rakefile"]

      spec = Gem::Specification.new("test") do |_spec|
        _spec.files = [
          @source_text_files,
          other_text_files,
        ]
      end
      document_task = Packnga::DocumentTask.new(spec) do |task|
        task.translate_languages = ["ja"]
      end
      @yard_task = extract_yard_task(document_task)
      @reference_task = extract_reference_task(document_task)
    end

    def test_readme
      assert_nil(@yard_task.readme)
      assert_nil(@reference_task.readme)
    end

    def test_source_files
      assert_equal([], @yard_task.source_files)
      assert_equal([], @reference_task.source_files)
    end

    def test_text_files
      assert_equal(@source_text_files.sort, @yard_task.text_files.sort)
      assert_equal(@source_text_files.sort, @reference_task.text_files.sort)
    end
  end

  class NoFilesTest < self
    def setup
      spec = Gem::Specification.new("test")
      document_task = Packnga::DocumentTask.new(spec)
      @yard_task = extract_yard_task(document_task)
      @reference_task = extract_reference_task(document_task)
    end

    def test_readme
      assert_nil(@yard_task.readme)
      assert_nil(@reference_task.readme)
    end

    def test_source_files
      assert_equal([], @yard_task.source_files)
      assert_equal([], @reference_task.source_files)
    end

    def test_text_files
      assert_equal([], @yard_task.text_files)
      assert_equal([], @reference_task.text_files)
    end
  end

  private
  def extract_yard_task(document_task)
    document_task.yard do |yard_task|
      yard_task
    end
  end

  def extract_reference_task(document_task)
    document_task.reference do |reference_task|
      reference_task
    end
  end
end
