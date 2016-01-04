require 'spec_helper'

describe Hindsight do
  let(:document) { Document.create }
  let(:company) { Company.create }
  let(:project) { Project.create }
  let(:comment) { Comment.create }
  let(:author) { Author.create }

  describe '#new_version' do
    subject { Document.create }

    context 'with a versioned has_many association' do
      it 'copies the association the new version' do
        project.update_attributes!(:documents => [document])
        expect(project.new_version.documents).to contain_exactly(document.versions.last)
      end

      it "persists the new version's association to the database" do
        project.update_attributes!(:documents => [document])
        project.new_version
        expect(project.versions.last.documents).to contain_exactly(document.versions.last)
      end

      it 'does not affect the association on the previous version' do
        project.update_attributes!(:documents => [document])
        expect { project.new_version }.not_to change { project.documents(true).to_a }
      end
    end

    context 'setting a versioned has_many association' do
      it 'can assign a collection' do
        expect(project.new_version(:documents => [document]).documents).to contain_exactly(document)
      end

      it 'can persist a collection' do
        expect(Project.find(project.new_version(:documents => [document]).id).documents).to contain_exactly(document)
      end

      it 'creates only a single new version of the association owner' do
        expect { project.new_version(:documents => [document]) }.to change { project.versions.count }.by(1)
      end

      it 'does not affect the association on the previous version' do
        project.update_attributes!(:documents => [Document.create])
        expect { project.new_version(:documents => [Document.create]) }.not_to change { project.documents(true).to_a }
      end
    end

    context 'with an unversioned has_many association' do
      it 'copies the association the new version' do
        document.update_attributes!(:comments => [comment])
        expect(document.new_version.comments).to contain_exactly(comment)
      end

      it "persists the new version's association to the database" do
        document.update_attributes!(:comments => [comment])
        document.new_version
        expect(document.versions.last.comments).to contain_exactly(comment)
      end
    end

    context 'setting an unversioned has_many association' do
      it 'can assign a collection' do
        expect(document.new_version(:comments => [comment]).comments).to contain_exactly(comment)
      end

      it 'can persist a collection' do
        expect(Document.find(document.new_version(:comments => [comment]).id).comments).to contain_exactly(comment)
      end

      it 'creates only a single new version of the association owner' do
        expect { document.new_version(:comments => [comment]) }.to change { document.versions.count }.from(1).to(2)
      end

      it 'does not affect the association on the previous version' do
        document.update_attributes!(:comments => [Comment.create])
        expect { document.new_version(:comments => [Comment.create]) }.not_to change { document.comments(true).to_a }
      end
    end

    context 'with a versioned has_many :through association' do
      it 'can assign a collection' do
        expect(project.new_version(:companies => [company]).companies).to contain_exactly(company)
      end

      it 'creates only a single new version of the association owner' do
        expect { project.new_version(:companies => [company]) }.to change { project.versions.count }.by(1)
      end

      it 'does not create a new version of the associated record' do
        expect { project.new_version(:companies => [company]) }.not_to change { company.versions.count }
      end

      it 'does not affect the association on the previous version' do
        project.update_attributes!(:companies => [Company.create])
        expect { project.new_version(:companies => [Company.create]) }.not_to change { project.companies(true).to_a }
      end
    end

    context 'with an unversioned has_many :through association' do
      it 'can assign a collection' do
        expect(document.new_version(:authors => [author]).authors).to contain_exactly(author)
      end

      it 'creates only a single new version of the association owner' do
        expect { document.new_version(:authors => [author]) }.to change { document.versions.count }.by(1)
      end

      it 'does not affect the association on the previous version' do
        document.update_attributes!(:authors => [Author.create])
        expect { document.new_version(:authors => [Author.create]) }.not_to change { document.authors(true).to_a }
      end
    end
  end

  describe '#become_current' do
    subject { document }
    let(:new_version) { document.new_version(:comments => [Comment.new] ) }

    it 'updates association to those of the latest version' do
      expect { document.become_current }.to change { document.comments.to_a }.to(new_version.comments(true).to_a)
    end
  end

  describe "collection<<" do
    context 'on a versioned has_many association' do
      it 'does not create a new version of the record being shovelled' do
        expect { project.documents << document }.not_to change { document.versions.count }
      end
    end

    context 'on a versioned has_many through association' do
      it 'does not create a new version of the record being shovelled' do
        expect { project.companies << company }.not_to change { company.versions.count }
      end

      it 'does not create a new version of the association owner' do
        expect { project.companies << company }.not_to change { project.versions.count }
      end

      it 'associates the record being shovelled with the same version of the association owner' do
        snapshot = project.snapshot
        project.companies << company
        expect(project.companies).to eq(snapshot.companies)
      end
    end
  end

  describe 'a versioned has_many association' do
    context 'on the latest version of a record' do
      # project 1:1    document [1:1]
      # project 1:2 <= document [1:2]
      let(:project) { Project.create.new_version }
      before { project.update_attributes!(:documents => [document]) }

      # project 1:2 <= document [1:3]
      it 'returns the latest versions of records' do
        new_version = document.new_version
        expect(project.documents(true)).to contain_exactly(new_version)
      end

      #                document [1:3]
      it 'exludes associated versions that have been moved to a different record in their latest version' do
        document.update_attributes!(:project => nil)
        expect(project.documents(true)).not_to include(*document.versions)
      end
    end

    context 'on a previous version of a record' do
      # project 1:1    document [1:1]
      # project 1:2 <= document [1:2]
      # project 1:3 <= document [1:3]
      before do
        project.update_attributes!(:documents => [document])
        project.new_version
        document.become_current
      end

      #                document [1:3]
      it 'returns the latest versions of records when they were associated to that version' do
        snapshot = document.versions.previous # document [1:2]
        document.update_attributes!(:project => nil)
        expect(project.documents(true)).to contain_exactly(snapshot)
      end
    end
  end

  describe 'a versioned has_many :through association' do
    context 'on the latest version of a record' do
      # project 1:1                           company [1:1]
      # project 1:2 <= project_company [1] <= company [1:2]
      let(:project) { Project.create.new_version }
      before { project.update_attributes!(:companies => [company]) }

      # project 1:2 <= project_company [2] <= company [1:3]
      it 'returns the latest versions of records' do
        new_version = company.new_version
        expect(project.companies(true)).to contain_exactly(new_version)
      end
    end
  end

  describe 'an unversioned has_many association' do
  end

  describe 'an unversioned has_many :through association' do
  end
end
