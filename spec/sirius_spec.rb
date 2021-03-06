require 'sirius'
require 'json'

describe Sirius do
  let(:valid_json) { '{"foo":"bar"}' }
  let(:incomplete_json) { '{"foo": null}' }
  let(:valid_xml) { "<foo>bar</foo>" }
  let(:incomplete_xml) { "<foo></foo>" }
  let(:nested_json) { '{"foo":{"bar":{"baz": "boo"}}}' }
  let(:nested_xml) { '<foo><bar><baz>boo</baz></bar></foo>' }

  describe ".initialize" do
    let(:klass) { Class.new { include Sirius } }

    context "with unknown format" do
      it "raises UnknownSerializationFormat error" do
        expect{ klass.new(:wrong, '') }.to raise_error
      end
    end

    context "valid formats" do
      context "json" do
        context "and valid data" do
          it "initializes successfully" do
            expect{ klass.new(:json, valid_json) }.not_to raise_error
          end
        end
        context "and blank data" do
          it "blows up" do
            expect{ klass.new(:json, '') }.to raise_error
          end
        end
      end
      context "xml" do
        context "and valid data" do
          it "initializes successfully" do
            expect{ klass.new(:xml, valid_xml) }.not_to raise_error
          end
        end
        context "and blank data" do
          it "blows up" do
            expect{ klass.new(:xml, '') }.to raise_error
          end
        end
      end
    end
  end

  describe "#requires" do
    let(:klass) {
      Class.new do
        include Sirius
        requires :foo, String
        def self.model_name; ActiveModel::Name.new(self, nil, "temp"); end
      end
    }
    context "json attribute" do
      context "with data" do
        subject { klass.new(:json, valid_json) }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:json, incomplete_json) }
        it{ should_not be_valid }
      end
    end
    context "xml attribute" do
      context "with data" do
        subject { klass.new(:xml, valid_xml) }
        it{ should respond_to(:foo) }
        its(:foo) { should == "bar" }
        it{ should be_valid }
      end
      context "without data" do
        subject { klass.new(:xml, incomplete_xml) }
        it{ should_not be_valid }
      end
    end
    describe "extracts passed options" do
      let(:klass) {
        Class.new do
          include Sirius
          requires :foo, String, at: "['foo']['bar']['baz']"
        end
      }
      context "(json)" do
        subject { klass.new(:json, nested_json) }
        its(:foo) { should == "boo" }
      end
      context "(xml)" do
        subject { klass.new(:xml, nested_xml) }
        its(:foo) { should == "boo" }
      end
    end
  end
  describe ".root" do
    let(:klass) {
      Class.new do
        include Sirius
        root "['foo']['bar']"
        requires :foo, String, at: "['baz']"
      end
    }
    context "correctly filters beginning at defined root node" do
      context "(json)" do
        subject { klass.new(:json, nested_json) }
        its(:foo) { should == 'boo' }
      end
      context "(xml)" do
        subject { klass.new(:xml, nested_xml) }
        its(:foo) { should == 'boo' }
      end
    end
  end

  describe "maintains Virtus coercion abilities" do
    before do
      class Treasure
        include Virtus
        attribute :type, String
        attribute :weight, Integer
        attribute :unit, String
      end
    end
    let(:klass) {
      class TreasureHunt
        include Sirius
        root "['ocean']['sea_floor']['treasure_chest']['hidden_compartment']"
        requires :treasure, Treasure
      end
    }
    let(:response) { '{"ocean": { "sea_floor": {"treasure_chest": {"hidden_compartment": { "treasure": { "type": "Gold", "weight": 1, "unit": "Ton" }}}}}}' }
    subject { klass.new(:json, response).treasure }
    it{ should be }
    it{ should be_a(Treasure) }
  end
end
