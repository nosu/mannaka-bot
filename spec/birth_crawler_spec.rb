require 'spec_helper'

describe 'access wikipedia' do
    it 'downloading page success' do
        expect(BirthCrawler.downloadPage('http://ja.wikipedia.org/wiki/2%E6%9C%8824%E6%97%A5')
