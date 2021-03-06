require 'spec_helper'

describe TrelloApi do
  let (:trello_api) { TrelloApi.new }
  let (:board) do
    VCR.use_cassette("trello_board") { trello_api.find_or_create_board "Lorem ipsum dolor" }
  end

  before do
    TrelloApi::Config.any_instance.stub(:consumer_key).and_return(:consumer_key)
    TrelloApi::Config.any_instance.stub(:consumer_secret).and_return(:consumer_secret)
    TrelloApi::Config.any_instance.stub(:oauth_token).and_return(:oauth_token)
  end

  context 'finding a board' do
    it "creates a new board if one doesn't exist" do

      board.should_not be_nil
    end

    it 'returns the board if it exists' do
      VCR.use_cassette("other_board") do
        board_1 = trello_api.find_or_create_board "Lorem ipsum dolor"

        board.should eq board_1
      end
    end
  end

  it 'adds lists to the board' do
    VCR.use_cassette("trello_lists") do
      list = trello_api.add_list_to_board "Some list", board
      other_list = trello_api.add_list_to_board "Some other list", board

      board.lists.should include list, other_list
    end
  end

  it 'adds cards to a list' do
    VCR.use_cassette("trello_cards") do
      borg = trello_api.add_list_to_board "The Borg", board
      humans = trello_api.add_list_to_board "The Human", board

      trello_api.add_card_to_list "Seven of Nine", "You will be assimilated.", borg
      trello_api.add_card_to_list "The Borgue Queen", " Let us see Humanity.", borg
      trello_api.add_card_to_list "Picard", "Tea, Earl Gray, hot!", humans

      borg.cards.should have(2).cards
      humans.cards.should have(1).cards
    end
  end


  context "#actions" do
    let(:borg) {
      VCR.use_cassette("borg") { trello_api.add_list_to_board "The Human", board }
    }
    let(:humans) {
      VCR.use_cassette("human") { trello_api.add_list_to_board "The Human", board }
    }


    it 'can move a card from a list to another' do
      VCR.use_cassette("move_betwen_lists") do
        seven_of_nine = trello_api.add_card_to_list "Seven of Nine", "You will be assimilated.", borg
        trello_api.add_card_to_list "The Borgue Queen", " Let us see Humanity.", borg
        trello_api.add_card_to_list "Picard", "Tea, Earl Gray, hot!", humans

        seven_of_nine.move_to_list humans

        borg.cards.should have(1).cards
        humans.cards.should have(2).cards
      end
    end

    it "finds cards by label color" do
      VCR.use_cassette("trello_find_by_label") do
        seven_of_nine = trello_api.add_card_to_list "Seven of Nine", "You will be assimilated.", borg
        picard = trello_api.add_card_to_list "Picard", "Tea, Earl Gray, hot!", humans
        trello_api.add_card_to_list "William Riker", "Fate. It protects fools, little children, and ships named 'Enterprise.'", humans

        seven_of_nine.add_label "purple"
        picard.add_label "purple"

        cards = trello_api.find_cards_by_label(board, "purple")
        cards.should include seven_of_nine, picard
      end
    end
  end
end
