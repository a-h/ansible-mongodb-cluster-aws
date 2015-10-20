require 'spec_helper'

describe 'Should be listening on mongo port' do
	describe port(27017) do
	  it { should be_listening }
	end
end