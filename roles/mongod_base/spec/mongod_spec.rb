require 'spec_helper'

describe 'firewalld should be enabled and running' do
	describe service('firewalld') do
	  it { should be_running }
	  it { should be_enabled }
	end
end

describe 'mongod should be enabled and running' do
	describe service('mongod') do
	  it { should be_enabled }
	end
end
