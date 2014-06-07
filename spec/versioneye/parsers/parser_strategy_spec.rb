require 'spec_helper'
require 'cocoapods-core'

describe ParserStrategy do

  describe "parser_for" do

    it "returns GemfileParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_RUBYGEMS, "Gemfile" )
      parser.is_a?( GemfileParser ).should be_true
    end

    it "returns GemfilelockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_RUBYGEMS, "Gemfile.lock" )
      parser.is_a?( GemfilelockParser ).should be_true
    end

    it "returns ComposerParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COMPOSER, "composer.json" )
      parser.is_a?( ComposerParser ).should be_true
    end

    it "returns ComposerLockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COMPOSER, "composer.lock" )
      parser.is_a?( ComposerLockParser ).should be_true
    end

    it "returns PodfilelockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COCOAPODS, "Podfile.lock" )
      parser.is_a?( PodfilelockParser ).should be_true
    end

    it "returns PodfileParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COCOAPODS, "Podfile" )
      parser.is_a?( PodfileParser ).should be_true
    end

    it "returns PomParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_MAVEN2, "pom.xml" )
      parser.is_a?( PomParser ).should be_true
    end

    it "returns PomParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_MAVEN2, "pom.json" )
      parser.is_a?( PomJsonParser ).should be_true
    end

    it "returns BowerParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_BOWER, "bower.json" )
      parser.is_a?( BowerParser ).should be_true
    end

    it "returns RequirementsParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_PIP, "requirements.txt" )
      parser.is_a?( RequirementsParser ).should be_true
    end

    it "returns PythonSetupParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_PIP, "setup.py" )
      parser.is_a?( PythonSetupParser ).should be_true
    end

    it "returns PackageParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_NPM, "package.json" )
      parser.is_a?( PackageParser ).should be_true
    end

    it "returns GradleParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_GRADLE, "dep.gradle" )
      parser.is_a?( GradleParser ).should be_true
    end

    it "returns LeinParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_LEIN, "lein" )
      parser.is_a?( LeinParser ).should be_true
    end

    it "returns nil" do
      parser = ParserStrategy.parser_for( "HujBuy", "lein" )
      parser.should be_nil
    end

  end

end
