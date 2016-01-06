require 'spec_helper'

describe Hindsight do
  let(:subject) { Document.create }

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
end
