require 'spec_helper'

describe Qti::V1::Models::Numerics::ExactMatch do
  context '#scoring_data' do
    let(:equal_node) do
      double(
        attributes: { 'respident' => double(value: 'response1') },
        content: '1234'
      )
    end

    let(:gte_node_value) { '1234' }
    let(:gte_node) do
      double(
        attributes: { 'respident' => double(value: 'response1') },
        content: gte_node_value
      )
    end

    let(:lte_node_value) { '1234' }
    let(:lte_node) do
      double(
        attributes: { 'respident' => double(value: 'response1') },
        content: lte_node_value
      )
    end

    let(:scoring_node) do
      double(
        equal_node: equal_node,
        gte_node: gte_node,
        lte_node: lte_node
      )
    end

    subject { described_class.new(scoring_node) }

    context 'missing node' do
      context 'equal_node is missing' do
        let(:equal_node) { nil }
        it 'returns nil' do
          expect(subject.scoring_data).to be_nil
        end
      end

      context 'gte_node is missing' do
        let(:gte_node) { nil }
        it 'returns nil' do
          expect(subject.scoring_data).to be_nil
        end
      end

      context 'lte_node is missing' do
        let(:lte_node) { nil }
        it 'returns nil' do
          expect(subject.scoring_data).to be_nil
        end
      end
    end

    context 'mismatching values for exact match' do
      context 'gte_node is mismatching with equal_node' do
        let(:gte_node_value) { '11111' }
        it 'returns nil' do
          expect(subject.scoring_data).to be_nil
        end
      end

      context 'lte_node is missing' do
        let(:lte_node_value) { '11111' }
        it 'returns nil' do
          expect(subject.scoring_data).to be_nil
        end
      end
    end

    it 'returns correct attributes' do
      ret_val = subject.scoring_data
      expect(ret_val.id).to eq('response1')
      expect(ret_val.type).to eq('exactResponse')
      expect(ret_val.value).to eq('1234')
    end
  end
end
