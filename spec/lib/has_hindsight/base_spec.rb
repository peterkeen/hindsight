require 'spec_helper'

describe Hindsight do
  let(:subject) { Document.create }

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

  describe '#snapshot' do
    it 'returns the same record' do
      expect(subject.snapshot).to eq(subject)
    end

    it 'returns a separate instance' do
      expect(subject.snapshot.object_id).not_to eq(subject.object_id)
    end
  end
end
