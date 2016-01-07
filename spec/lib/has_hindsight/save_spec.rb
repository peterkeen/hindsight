require 'spec_helper'

describe Hindsight do
  let(:subject) { Document.create }

  describe '#new_version' do
    it 'returns a new version' do
      new_version = subject.new_version
      expect(new_version).to be_a(subject.class)
      expect(new_version).not_to eq(subject)
    end

    it 'increments the version number' do
      expect(subject.new_version.version).to be(subject.version + 1)
    end

    it 'does not affect the version of the receiver' do
      expect { subject.new_version }.not_to change { subject.version }
    end

    it 'accepts attributes to assign to the new verson' do
      expect(subject.new_version(:body => 'changed').body).to eq('changed')
    end

    it 'accepts a block and yields a new version' do
      subject.new_version {|v| expect(v.version).to eq(2) }
    end

    it 'allows attribute changes to be made without affecting the original version' do
      subject.update_attributes(:body => 'original text')
      expect { subject.new_version(:body => 'new text') }.not_to change { subject.body }
    end

    it 'associates the version with the original record' do
      new_version = subject.new_version
      expect(new_version.versions.first).to eq(subject)
    end

    it 'returns false if the record is invalid' do
      subject.class.any_instance.stub(:valid? => false)
      expect(subject.new_version).to be_falsey
    end

    it 'does not create a new version if the record is invalid' do
      subject.class.any_instance.stub(:valid? => false)
      expect { subject.new_version }.not_to change { subject.versions.count }
    end

    it 'runs save callbacks on the new version' do
      subject.class.send :attr_accessor, :test_point
      subject.class.after_save lambda { |record| record.test_point = 'ran callbacks' }
      new_version = subject.new_version

      expect(new_version.test_point).to eq('ran callbacks')
    end

    it 'does not run callbacks on the current version' do
      subject.class.send :attr_accessor, :test_point
      subject.class.after_save lambda { |record| record.test_point = 'ran callbacks' }
      new_version = subject.new_version

      expect(subject.test_point).not_to eq('ran callbacks')
    end
  end

  describe '#create!' do
    it 'starts the version number at 1' do
      expect(subject.version).to eq(1)
    end
  end

  describe '#save' do
    it 'changes the id to that of the new version' do
      subject.save
      expect(subject.id).to eq(subject.versions.last.id)
    end

    it 'creates a new version record' do
      expect { subject.save }.to change { subject.class.count }.from(1).to(2)
    end

    it 'raises an exception if the record is not a latest_version' do
      subject.new_version
      subject.body = 'changed'
      expect { subject.save }.to raise_exception(Hindsight::ReadOnlyVersion)
    end

    it 'returns false if the record is invalid' do
      subject.class.any_instance.stub(:valid? => false)
      expect(subject.save).to be_falsey
    end

    it 'does not create a new version if the record is invalid' do
      subject.class.any_instance.stub(:valid? => false)
      expect { subject.save }.not_to change { subject.versions.count }
    end

    it 'runs save callbacks'
  end

  describe '#update_attributes' do
    context 'setting attributes' do
      it 'creates new versions' do
        expect { subject.update_attributes!(:body => 'changed') }.to change { subject.versions.count }.from(1).to(2)
      end

      it 'replaces self with the new version' do
        expect { subject.update_attributes!(:body => 'changed') }.to change { subject.version }.from(1).to(2)
      end
    end
  end

  describe '#become_current' do
    let(:new_version) { subject.new_version(:body => 'changed') }

    it 'updates id to the latest version id' do
      expect { subject.become_current }.to change { subject.id }.to(new_version.id)
    end

    it 'updates attributes to those of the latest version' do
      expect { subject.become_current }.to change { subject.body }.to(new_version.body)
    end
  end
end
