require 'spec_helper'

describe Hindsight::AssociationConditions do
  describe 'latest_version' do
    let(:company) { Company.create }
    let(:project) { Project.create(:companies => [company]) }
    subject { project.companies }

    before { company.update_attribute(:name, 'changed') }

    it 'counts only the latest versions' do
      expect(subject.count).to eq(1)
    end

    it 'returns only the latest versions' do
      expect(subject).to contain_exactly(company.versions.last)
    end

    it 'returns only the latest persisted versions' do
      expect(Project.find(project.id).companies(true)).to contain_exactly(company.versions.last)
    end
  end
end
