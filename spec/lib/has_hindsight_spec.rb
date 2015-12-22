require 'spec_helper'

describe Hindsight do
  describe 'saving' do
    subject { Document.create }

    it 'increments the version number' do
      expect { subject.save! }.to change { subject.version }.from(1).to(2)
    end

    it 'creates a new version record' do
      expect { subject.save! }.to change { subject.class.count }.from(1).to(2)
    end

    it 'associates the version with the original record' do
      subject_id = subject.id
      subject.save!
      expect(subject.versions.first.id).to eq(subject_id)
    end

    it 'modifies the attributes of the new version record' do
      expect{ subject.update_attributes!(:body => 'changed') }.to change { subject.body }
    end

    it 'does not modify the attributes of the original record' do
      expect{ subject.update_attributes!(:body => 'changed') }.not_to change { subject.versions.first.body }
    end
  end

  describe 'saving has_many associations' do
    context 'when the associated record is versioned' do
      it 'persists changes to associations'
      it 'does not modify the associations of the original record'
    end

    context 'when the associated record is not versioned' do
      # FIXME: it 'persists changes to associations'
      # FIXME: it 'does not modify the associations of the original record'
    end
  end

  describe 'saving has_many :through associations' do
    context 'when the associated record is versioned' do
      it 'persists changes to associations'
      it 'does not modify the associations of the original record'
    end

    context 'when the associated record is not versioned' do
      it 'persists changes to associations'
      it 'does not modify the associations of the original record'
    end
  end
end
