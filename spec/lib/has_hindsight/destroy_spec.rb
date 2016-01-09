require 'spec_helper'

describe 'Hindsight::Destroy' do
  describe '::not_destroyed' do
    let(:subject) { Project }

    it 'returns an ActiveRecord::Relation' do
      expect(Document.not_destroyed).to be_a(ActiveRecord::Relation)
    end

    it 'only returns versions that have not been destroyed' do
      document = subject.create
      snapshot = document.snapshot
      document.destroy
      expect(document.versions.not_destroyed).to contain_exactly(snapshot)
    end
  end

  describe '::destroyed' do
    let(:subject) { Project }

    it 'returns an ActiveRecord::Relation' do
      expect(Document.destroyed).to be_a(ActiveRecord::Relation)
    end

    it 'only returns versions that have not been destroyed' do
      document = subject.create
      document.destroy
      expect(document.versions.destroyed).to contain_exactly(document)
    end
  end

  describe "#destroy" do
    let(:document) { Document.create }
    let(:project) { Project.create }
    let(:comment) { Comment.create }
    let(:subject) { document }

    it 'creates a new version' do
      expect { subject.destroy }.to change { subject.versions.count }.by(1)
    end

    it 'increments the version number' do
      expect { subject.destroy }.to change { subject.version }.by(1)
    end

    it 'does not remove the record from the database' do
      id = subject.id
      subject.destroy
      expect(subject.class.where(:id => id)).to exist
    end

    it 'raises an exception if the record is not a latest_version' do
      subject.new_version
      subject.body = 'changed'
      expect { subject.destroy }.to raise_exception(Hindsight::ReadOnlyVersion)
    end

    it 'cascades destroy to dependent versioned associations' do
      stub_class(Project) { has_many :documents, :dependent => :destroy }
      project.update_attributes(:documents => [document])
      document.become_current

      expect { project.destroy }.to change { document.versions.destroyed.count }.by(1)
    end

    it 'does not cascade destroy to dependent un-versioned associations' do
      stub_class(Document) { has_many :comments, :dependent => :destroy }
      subject.update_attributes(:comments => [comment])
      expect { document.destroy }.not_to change { Comment.count }
    end

    it 'raises an exception when destroying a readonly record (standard ActiveRecord behaviour)' do
      subject.stub(:readonly? => true)
      expect { subject.destroy }.to raise_exception(ActiveRecord::ReadOnlyRecord)
    end

    it 'triggers before_destroy callbacks'
    it 'triggers after_destroy callbacks'
  end

  describe "#destroyed?" do
    let(:subject) { Project.create }

    it 'returns true if the record is a destroyed record' do
      subject.destroy
      expect(subject).to be_destroyed
    end
  end
end
