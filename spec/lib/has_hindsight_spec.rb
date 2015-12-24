require 'spec_helper'

describe Hindsight do
  describe '#save!' do
    context 'a record' do
      subject { Document.create }

      it 'increments the version number' do
        expect { subject.save! }.to change { subject.version }.from(1).to(2)
      end

      it 'changes the id to that of the new version' do
        expect { subject.save! }.to change { subject.id }.by(1)
      end

      it "sets versioned_record_id to its own id if it is the first version" do
        expect(subject.versioned_record_id).to eq(subject.id)
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
        expect { subject.update_attributes!(:body => 'changed') }.to change { subject.body }
      end

      it 'does not modify unchanged attributes of the new version record' do
        subject.update_attributes!(:body => 'changed')
        expect { subject.save! }.not_to change { subject.reload.body }
      end

      it 'does not modify the attributes of the original record' do
        expect { subject.update_attributes!(:body => 'changed') }.not_to change { subject.versions.first.body }
      end
    end

    context 'a record with a has_many association' do
      context 'that is versioned' do
        subject { Project.create }

        it 'persists association changes via others_ids=' do
          new_companies = [Company.create]
          attributes = {:company_ids => new_companies.collect(&:id) }
          expect { subject.update_attributes!(attributes) }.to change { subject.companies.to_a }.to(new_companies)
        end

        it 'does not modify the associations of the original record' do
          original_id = subject.id
          expect { subject.update_attributes!(:company_ids => [Company.create.id]) }.not_to change { Project.find(original_id).companies }
        end

        it 'does not change unmodified associations of the new version' do
          original_id = subject.id
          expect { subject.update_attributes!(:document_ids => [Document.create.id]) }.not_to change { Project.find(original_id).companies }
        end
      end

      context 'that is not versioned' do
        # FIXME: it 'persists changes to associations'
        # FIXME: it 'does not modify the associations of the original record'
      end
    end

    context 'when the record has a has_many :through association' do
      context 'that is versioned' do
        it 'persists changes to associations'
        it 'does not modify the associations of the original record'
      end

      context 'that is not versioned' do
        it 'persists changes to associations'
        it 'does not modify the associations of the original record'
      end
    end
  end

  describe '#versions' do
    subject { Document.create }

    it 'includes all versions of the record, including self' do
      original_id = subject.id
      subject.save!
      expect(subject.versions.pluck(:id)).to contain_exactly(original_id, subject.id)
    end
  end

  describe '#versions.previous' do
    subject { Document.create }

    it 'returns the version whose version number is immediately preceding this version' do
      previous_id = subject.id
      subject.save!
      expect(subject.versions.previous.id).to eq(previous_id)
    end

    it 'skips over missing versions'
  end

  describe '#versions.next' do
    subject { Document.create }

    it 'returns the version whose version number is immediately following this version' do
      original_id = subject.id
      subject.save!
      expect(subject.class.find(original_id).versions.next).to eq(subject)
    end

    it 'skips over missing versions'
  end

  describe '#update_attributes' do
    subject { Document.create }

    it 'creates new versions' do
      expect { subject.update_attributes!(:body => 'changed') }.to change { subject.versions.count }.from(1).to(2)
    end
  end
end
