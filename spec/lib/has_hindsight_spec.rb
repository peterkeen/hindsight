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
  end

  describe '#versions' do
    it 'includes all versions of the record, including self' do
      new_version = subject.new_version
      expect(subject.versions).to contain_exactly(subject, new_version)
    end
  end

  describe '#versions.previous' do
    it 'returns the version whose version number is immediately preceding this version' do
      middle_version = subject.new_version
      new_version = middle_version.new_version
      expect(new_version.versions.previous).to eq(middle_version)
    end

    it 'skips over missing versions' do
      new_version = subject.new_version
      new_version.update_column(:version, new_version.version + 10)
      expect(new_version.versions.previous).to eq(subject)
    end
  end

  describe '#versions.next' do
    it 'returns the version whose version number is immediately following this version' do
      new_version = subject.new_version
      new_version.new_version
      expect(subject.versions.next).to eq(new_version)
    end

    it 'skips over missing versions' do
      new_version = subject.new_version
      new_version.update_column(:version, new_version.version + 10)
      expect(subject.versions.next).to eq(new_version)
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

  describe '#latest_version?' do
    it 'returns true if the record is the only version' do
      expect(subject.latest_version?).to be_truthy
    end

    it 'returns true if the record is the latest version' do
      new_version = subject.new_version
      expect(new_version.latest_version?).to be_truthy
    end

    it 'returns false if the record is not the latest version' do
      new_version = subject.new_version
      expect(subject.latest_version?).to be_falsey
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

  describe '#snapshot' do
    it 'returns the same record' do
      expect(subject.snapshot).to eq(subject)
    end

    it 'returns a separate instance' do
      expect(subject.snapshot.object_id).not_to eq(subject.object_id)
    end
  end
end
