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

    context 'a record with a versioned has_many association' do
      # TODO
    end

    context 'a record with a versioned has_many association' do
      # FIXME: it 'persists changes to associations'
      # FIXME: it 'does not modify the associations of the original record'
    end

    context 'on a record that has a versioned has_many :through association' do
      subject { Project.create }

      it 'copies the association to the new version' do
        subject.companies << Company.create
        expect { subject.update_attributes!(:name => 'changed') }.not_to change { subject.companies }
      end

      it "persists the new version's association to the database" do
        subject.companies << Company.create
        expect { subject.update_attributes!(:name => 'changed') }.not_to change { Project.find(subject).companies }
      end

      it 'does not modify the association on the previous version' do
        original_id = subject.id
        subject.companies << Company.create
        expect { subject.update_attributes!(:name => 'changed') }.not_to change { Project.find(original_id).companies }
      end

      it 'can modify the association via others_ids=' do
        new_companies = [Company.create]
        attributes = {:company_ids => new_companies.collect(&:id) }
        expect { subject.update_attributes!(attributes) }.to change { subject.companies.to_a }.to(new_companies)
      end

      it 'persists modifications to the association via others_ids=' do
        new_companies = [Company.create]
        attributes = {:company_ids => new_companies.collect(&:id) }
        expect { subject.update_attributes!(attributes) }.to change { Project.find(subject).companies }.to(new_companies)
      end

      it 'does not modify the association on the previous version' do
        original_id = subject.id
        new_companies = [Company.create]
        attributes = {:company_ids => new_companies.collect(&:id) }
        expect { subject.update_attributes!(attributes) }.not_to change { Project.find(original_id).companies }
      end
    end

    context 'on a record that has an un-versioned has_many :through association' do
      it 'persists changes to associations'
      it 'does not modify the associations of the original record'
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

  describe '#new_version' do
    subject { Document.create }

    it 'returns a new version' do
      expect(subject.new_version).to be_a(subject.class)
      expect(subject.new_version).not_to eq(subject)
    end

    it 'does not affect the version of the receiver' do
      expect { subject.new_version }.not_to change { subject.version }
    end

    it 'accepts a block and yields a new version' do
      subject.new_version do |v|
        expect(v.version).to eq(2)
      end
    end

    it 'allows attribute changes to be made without affecting the original version' do
      subject.update_attributes(:body => 'original text')
      subject.new_version do |v|
        expect { v.update_attributes(:body => 'new text') }.not_to change { subject.body }
      end
    end

    it 'allows association= changes to be made without affecting the original version' do
      subject.update_attribute(:project, Project.create)
      subject.new_version do |v|
        expect { v.update_attribute(:project, Project.create) }.not_to change { subject.project }
      end
    end
  end
end
