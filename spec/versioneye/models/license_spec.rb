require 'spec_helper'

describe License do

  describe 'to_s' do

    it 'returns the right to_s string' do
      license = License.new({:language => 'Ruby', :prod_key => 'rails',
        :version => '1.0.0', :name => 'MIT'})
      license.to_s.should eq('[License for (Ruby/rails/1.0.0) : MIT]')
    end

  end

  describe 'find_or_create' do

    it 'creates a new one' do
      License.count.should == 0
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
    end

    it 'creates a new one and returns it the 2nd time' do
      License.count.should == 0
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
      described_class.find_or_create("PHP", "doctrine/doctrine", "1.0.0", "MIT").should_not be_nil
      License.count.should == 1
    end

  end

  describe 'product' do

    it 'returns the product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      prod = mit_license.product
      prod.id.to_s.should eq( product.id.to_s )
    end

  end

  describe 'for_product' do

    it 'returns the licenses for product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      bsd_license = LicenseFactory.create_new product, "BSD"
      licenses = License.for_product product
      licenses.should_not be_nil
      licenses.count.should eq(2)
    end

    it 'returns the licenses for product' do
      product = ProductFactory.create_new 1
      mit_license = LicenseFactory.create_new product, "MIT"
      product.version = "not_1"
      bsd_license = LicenseFactory.create_new product, "BSD"
      licenses = License.for_product product
      licenses.should_not be_nil
      licenses.count.should eq(1)
      licenses.first.name.should eq('BSD')
      licenses = License.for_product product, true
      licenses.should_not be_nil
      licenses.count.should eq(2)
    end

  end

  describe "link" do

    it "should return mit link" do
      license = License.new({:name => "MIT"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "mit"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "The MIT License"})
      license.link.should eq("http://mit-license.org/")
    end
    it "should return mit link" do
      license = License.new({:name => "MIT License"})
      license.link.should eq("http://mit-license.org/")
    end

    it "should return apache 2 link" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end
    it "should return apache 2 link" do
      license = License.new({:name => "The Apache Software License, Version 2.0"})
      license.link.should eq("http://www.apache.org/licenses/LICENSE-2.0.txt")
    end

  end

  describe "name_substitute" do

    it "should return MIT name" do
      license = License.new({:name => "MIT"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "MIT License"})
      license.name_substitute.should eq("MIT")
    end
    it "should return MIT name" do
      license = License.new({:name => "The MIT License"})
      license.name_substitute.should eq("MIT")
    end

    it "should return BSD name" do
      license = License.new({:name => "BSD"})
      license.name_substitute.should eq("BSD")
    end
    it "should return BSD name" do
      license = License.new({:name => "BSD License"})
      license.name_substitute.should eq("BSD")
    end

    it "should return Ruby name" do
      license = License.new({:name => "Ruby"})
      license.name_substitute.should eq("Ruby")
    end
    it "should return Ruby name" do
      license = License.new({:name => "Ruby License"})
      license.name_substitute.should eq("Ruby")
    end

    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL 2"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL-2"})
      license.name_substitute.should eq("GPL-2.0")
    end
    it "should return GPL 2.0 name" do
      license = License.new({:name => "GPL 2.0"})
      license.name_substitute.should eq("GPL-2.0")
    end

    it "should return Apache License version 2 name" do
      license = License.new({:name => "The Apache Software License\, Version 2\.0"})
      license.name_substitute.should eq("Apache License 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License, Version 2.0"})
      license.name_substitute.should eq("Apache License 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache License Version 2.0"})
      license.name_substitute.should eq("Apache License 2.0")
    end
    it "should return Apache License version 2 name" do
      license = License.new({:name => "Apache-2.0"})
      license.name_substitute.should eq("Apache License 2.0")
    end

    it "should return Apache License name" do
      license = License.new({:name => "Apache License"})
      license.name_substitute.should eq("Apache License 2.0")
    end
    it "should return Apache License name" do
      license = License.new({:name => "Apache Software License"})
      license.name_substitute.should eq("Apache License 2.0")
    end

    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse"})
      license.name_substitute.should eq("Eclipse Public License 1.0")
    end
    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse License"})
      license.name_substitute.should eq("Eclipse Public License 1.0")
    end
    it "should return eclipse public license name" do
      license = License.new({:name => "Eclipse Public License 1.0"})
      license.name_substitute.should eq("Eclipse Public License 1.0")
    end

    it "should return Artistic License 1.0 license name" do
      license = License.new({:name => "Artistic 1.0"})
      license.name_substitute.should eq("Artistic License 1.0")
    end
    it "should return Artistic License 1.0 license name" do
      license = License.new({:name => "Artistic License"})
      license.name_substitute.should eq("Artistic License 1.0")
    end
    it "should return Artistic License 1.0 license name" do
      license = License.new({:name => "Artistic License 1.0"})
      license.name_substitute.should eq("Artistic License 1.0")
    end

    it "should return Artistic License 2.0 license name" do
      license = License.new({:name => "Artistic 2.0"})
      license.name_substitute.should eq("Artistic License 2.0")
    end
    it "should return Artistic License 2.0 license name" do
      license = License.new({:name => "Artistic License 2.0"})
      license.name_substitute.should eq("Artistic License 2.0")
    end

    it "should return the given name if name is uknown" do
      license = License.new({:name => "not_existing"})
      license.name_substitute.should eq("not_existing")
    end

  end

end
